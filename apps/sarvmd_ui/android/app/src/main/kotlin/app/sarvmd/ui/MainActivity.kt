package app.sarvmd.ui

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "app.sarvmd/file_opener"
    }

    private var channel: MethodChannel? = null

    // Hold the path from the launch intent so we can forward it once Flutter
    // has finished initialising and the channel is ready.
    private var pendingFilePath: String? = null

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
                else -> result.notImplemented()
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
