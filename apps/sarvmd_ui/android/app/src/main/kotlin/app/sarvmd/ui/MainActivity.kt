package app.sarvmd.ui

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "app.sarvmd/file_opener"
        private const val SAVE_FILE_REQUEST_CODE = 2001
    }

    private var channel: MethodChannel? = null

    // Hold the path from the launch intent so we can forward it once Flutter
    // has finished initialising and the channel is ready.
    private var pendingFilePath: String? = null

    // Save File SAF tracking
    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveBytes: ByteArray? = null
    private var pendingSaveFileName: String? = null

    // ── Flutter engine wiring ────────────────────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialFilePath" -> {
                    result.success(pendingFilePath)
                    pendingFilePath = null        // consumed
                }
                "saveFile" -> {
                    handleSaveFile(call, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleSaveFile(call: MethodCall, result: MethodChannel.Result) {
        if (pendingSaveResult != null) {
            result.error("CONCURRENT_SAVE", "Another save file dialog is currently active.", null)
            return
        }

        val fileName = call.argument<String>("fileName") ?: "document"
        val bytes = call.argument<ByteArray>("bytes")
        val mimeType = call.argument<String>("mimeType") ?: resolveMimeType(fileName)

        pendingSaveResult = result
        pendingSaveBytes = bytes
        pendingSaveFileName = fileName

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, fileName)
        }

        try {
            startActivityForResult(intent, SAVE_FILE_REQUEST_CODE)
        } catch (e: Exception) {
            pendingSaveResult = null
            pendingSaveBytes = null
            pendingSaveFileName = null
            result.error("PICKER_FAILED", "Failed to open document creator: ${e.message}", null)
        }
    }

    private fun resolveMimeType(fileName: String): String {
        val lower = fileName.lowercase()
        return when {
            lower.endsWith(".pdf") -> "application/pdf"
            lower.endsWith(".svg") -> "image/svg+xml"
            lower.endsWith(".tex") -> "text/plain"
            lower.endsWith(".png") -> "image/png"
            lower.endsWith(".mid") || lower.endsWith(".midi") -> "audio/midi"
            lower.endsWith(".sarv") -> "application/octet-stream"
            else -> "*/*"
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == SAVE_FILE_REQUEST_CODE) {
            val saveResult = pendingSaveResult ?: return
            val saveBytes = pendingSaveBytes
            val originalFileName = pendingSaveFileName

            pendingSaveResult = null
            pendingSaveBytes = null
            pendingSaveFileName = null

            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                // User cancelled or dismissed the picker
                saveResult.success(null)
                return
            }

            var uri = data.data!!
            var displayName = resolveFileName(uri) ?: originalFileName ?: "document"

            // Android Storage Access Framework (SAF) appends " (1)" after the file extension
            // when it cannot match the MIME type to the extension (e.g. .sarv or */*),
            // producing names like "Treble_A4_Portrait.pdf (1)" or "Treble_A4_Portrait.sarv (1)".
            // Reposition the numeric counter immediately before the extension: "Treble_A4_Portrait (1).pdf".
            val duplicateRegex = Regex("""^(.+?)\.([a-zA-Z0-9]+)\s*[\(_]([0-9]+)\)?$""")
            val match = duplicateRegex.find(displayName)
            if (match != null) {
                val baseName = match.groupValues[1]
                val ext = match.groupValues[2]
                val initialIndex = match.groupValues[3].toIntOrNull() ?: 1

                var counter = initialIndex
                var candidateName = "$baseName ($counter).$ext"
                val maxAttempts = initialIndex + 50

                while (counter < maxAttempts) {
                    try {
                        val renamedUri = DocumentsContract.renameDocument(contentResolver, uri, candidateName)
                        if (renamedUri != null) {
                            uri = renamedUri
                            displayName = candidateName
                            break
                        }
                    } catch (_: Exception) {
                        // Rename conflict with existing candidateName or provider constraint; try next index
                    }
                    counter++
                    candidateName = "$baseName ($counter).$ext"
                }
            }

            try {
                if (saveBytes != null) {
                    contentResolver.openOutputStream(uri)?.use { output ->
                        output.write(saveBytes)
                        output.flush()
                    }
                }
                val returnPath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                    .absolutePath + File.separator + displayName
                saveResult.success(returnPath)
            } catch (e: Exception) {
                saveResult.error("SAVE_IO_ERROR", "Failed to write document content: ${e.message}", null)
            }
        }
    }

    // ── Activity lifecycle ───────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Process a cold-start file-open intent
        pendingFilePath = resolveFilePath(intent)
    }

    /** Called when the app is already running (launchMode="singleTop"). */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val path = resolveFilePath(intent) ?: return
        // App is already running — push the path directly to Flutter if ready,
        // otherwise stash it as pending.
        val ch = channel
        if (ch != null) {
            ch.invokeMethod("openFile", path)
        } else {
            pendingFilePath = path
        }
    }

    // ── Intent resolution ────────────────────────────────────────────────────

    /**
     * Extracts a filesystem path from an [ACTION_VIEW] intent carrying a `.sarv` document.
     *
     * For `file://` URIs the path is taken directly.
     * For `content://` URIs (Storage Access Framework / email attachments) the bytes are
     * copied into the app's private cache directory and that stable path is returned.
     *
     * Returns `null` for unrelated intents.
     */
    private fun resolveFilePath(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_VIEW) return null
        val uri: Uri = intent.data ?: return null

        return when (uri.scheme) {
            "file" -> uri.path
            "content" -> copyUriToCache(uri)
            else -> null
        }
    }

    private fun copyUriToCache(uri: Uri): String? {
        return try {
            val fileName = resolveFileName(uri) ?: "document.sarv"
            val cacheFile = File(cacheDir, fileName)

            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(cacheFile).use { output ->
                    input.copyTo(output)
                }
            }
            cacheFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    private fun resolveFileName(uri: Uri): String? {
        var name: String? = null
        try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (nameIndex >= 0) name = cursor.getString(nameIndex)
                    }
                }
        } catch (_: Exception) {
            // Ignore security exception or failure querying provider
        }
        if (name == null) {
            name = uri.lastPathSegment
        }
        return name?.let { File(it).name }
    }
}
