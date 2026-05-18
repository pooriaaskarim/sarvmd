# Sarv Manuscript Designer
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="apps/sarvmd_ui/assets/handwriting/sarv_banner_dark.png">
  <img alt="SarvMD" src="apps/sarvmd_ui/assets/handwriting/sarv_banner_light.png">
</picture>


## What is SarvMD?
SarvMD is a music manuscript generator designed to provide a flexible environment for composers, educators, and musicians to create customizable manuscript papers. SarvMD offers control over various dimensions of the workspace, ensuring clean and legible outputs.

## Intentions
The motivation for SarvMD is to bridge the gap between static manuscript templates and the struggle of using complicated software to create manuscript layouts.
SarvMD was designed to boost the creative and diverse workflow of musicians. It provides a flexible interface that stays out of your way, while offering granular control over every aspect of the layout.

## How It Works
SarvMD operates through a clean, layered pipeline to ensure reliable rendering and positioning:

1. **Config**: The user defines the document's structure, including page size, layout type, staff dimensions, and clef settings.
2. **Layout Engine**: A core geometric engine calculates staff positions and symbol anchor points based on the configuration.
3. **Emitter**: Translates the layout data into specific rendering commands:
   - For PDF export, it generates LaTeX `\pdfliteral` and `picture` commands.
   - For the UI, it generates `CustomPainter` path commands.
4. **Compiler/Renderer**: 
   - The **CLI** uses `pdflatex` to compile the LaTeX into a scalable, vector-based PDF.
   - The **UI** utilizes Flutter's canvas to render custom Bézier paths, providing an immediate and accurate preview of the manuscript.

## Technical Brief

SarvMD is architected as a modular Dart Workspace (monorepo). This structure maintains a single source of truth for the core logic across all interfaces.

### Workspace Structure
- **`packages/sarvmd_core`**: The foundational engine. It contains the configuration models, layout calculations, symbol path data, LaTeX emission logic, and PDF compilation wrappers. It operates independently of any UI framework.
- **`apps/sarvmd_ui`**: A Flutter-based desktop editor, optimized primarily for Linux and Web. Key technical details include:
  - An **Editor-Workspace** pattern that separates the tooling from the canvas.
  - **State Management**: A dual-notifier system that decouples the document state (`ConfigNotifier`) from the user's viewport and zoom settings (`ViewNotifier`).
  - **Premium UI**: A dynamic, accent-based theme system using pastel seeds, complemented by interactive controls and practical features like "mouse wings" alignment crosshairs.
- **`apps/sarvmd_cli`**: A lightweight command-line interface for headless workflows and batch generation.

### Design Philosophy
- **Desktop-First**: The UI is optimized for desktop environments to support detailed layout adjustments, fluid keyboard-and-mouse navigation, and seamless system-level export handling.
- **Zero-Dependency Core**: The core layout engine relies entirely on pure Dart, minimizing external dependencies to ensure long-term stability and performance.

## License & Contributing

### License
SarvMD is licensed under the **Business Source License 1.1 (BUSL-1.1)**. 
*   **Non-Commercial Use**: Free to copy, modify, and run the code for personal, educational, or testing purposes.
*   **Commercial Use**: Commercial production use, including hosting a commercial service, embedding the layout engine in proprietary software, or selling compiled versions of the applications, is prohibited unless authorized by the copyright owner (**Pooria Askari Moqaddam**).
*   **Open-Source Transition**: On **June, 2031**, this license automatically transitions to the standard, highly permissive **Apache License 2.0**.

For the full legal terms, please read the [LICENSE](LICENSE) file.

### Contributing
We welcome contributions! To keep our codebase legally clean and secure, we require all contributors to sign off on their commits using the **Developer Certificate of Origin (DCO)**. 

Please read our [Contributing Guidelines](CONTRIBUTING.md) for step-by-step instructions on how to sign off on your commits (`git commit -s`).
