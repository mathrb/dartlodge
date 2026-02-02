# Darts App

A **local-first**, open-source darts application for Android and iOS, built with Flutter. Users can track statistics, play manually, or optionally use a self-hosted backend for auto-scoring via computer vision.

## Features
- **Local-First**: Works offline by default, with optional backend sync.
- **Statistics Tracking**: Save and view game statistics locally.
- **Auto-Scoring (Optional)**: Use a self-hosted backend to detect darts via computer vision.
- **Cross-Platform**: Available on Android and iOS.

## Advanced Features

For advanced functionality including remote multiplayer, authentication, and complex synchronization, see [Backend Integration](docs/BACKEND_INTEGRATION.md).

### Multiplayer Support
This application supports both local (hotseat) and remote multiplayer modes. Detailed architecture and implementation guidance is available in the backend integration documentation.

## Documentation

For detailed technical information, see:
- [Data Structure](docs/DATA.md) - Database schema and data models
- [System Architecture](docs/ARCHITECTURE.md) - Technical architecture and design

## Architecture
### Frontend (Flutter)
- **Local Storage**: Uses SQLite (via sqflite package) to store statistics offline. SQLite was chosen for its relational capabilities, complex query support, and better long-term maintainability for statistics tracking.
- **UI**: Built with Flutter widgets for a native-like experience.
- **Optional Backend Sync**: Connects to a self-hosted backend if configured.

### Backend (Optional, Self-Hosted)
- **REST API**: For syncing statistics and auto-scoring.
- **Computer Vision**: Detects darts using PyTorch or ONNX models (Rust/Python).
- **Self-Hosted**: Users can run their own backend (Python or Rust).

## Getting Started
### Prerequisites
- Flutter SDK (for mobile app development).
- Python or Rust (for backend, if used).
- Optional: LibTorch or ONNX runtime (for computer vision).

### Install the Mobile App
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/darts-app.git
   cd darts-app
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Add SQLite dependency (if not already in pubspec.yaml):
   ```bash
   flutter pub add sqflite
   flutter pub add path_provider
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Set Up the Backend (Optional)
#### Python Backend
1. Install dependencies:
   ```bash
   pip install flask opencv-python torch
   ```
2. Run the backend:
   ```bash
   python backend/app.py
   ```
3. Configure the app to use the backend URL (e.g., `http://localhost:5000`).

#### Rust Backend
1. Install Rust:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```
2. Install dependencies (e.g., `tract-onnx` or `tch-rs`):
   ```bash
   cargo add tract-onnx
   ```
3. Run the backend:
   ```bash
   cargo run --release
   ```

## Computer Vision (Auto-Scoring)
### PyTorch Model
- Export your PyTorch model to ONNX:
  ```python
  torch.onnx.export(model, dummy_input, "model.onnx")
  ```
- Load the model in Rust using `tract-onnx` or `tch-rs`.

### ONNX Model
- Use `tract-onnx` for pure Rust inference:
  ```rust
  let model = onnx().model_for_path("model.onnx")?.into_runnable()?;
  ```

## Contributing
Contributions are welcome! Open an issue or submit a pull request.

## License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
