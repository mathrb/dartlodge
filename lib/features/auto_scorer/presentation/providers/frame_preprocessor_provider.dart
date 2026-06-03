import 'package:dart_lodge/features/auto_scorer/data/preprocessing/image_frame_preprocessor.dart';
import 'package:dart_lodge/features/auto_scorer/domain/preprocessing/frame_preprocessor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'frame_preprocessor_provider.g.dart';

/// The frame preprocessor used to build the model's 800×800 input (#377 §2).
/// Wires the `data/` codec implementation behind the `domain/` interface, so
/// the session (presentation) injects it without importing `data/`.
@Riverpod(keepAlive: true)
FramePreprocessor framePreprocessor(Ref ref) => const ImageFramePreprocessor();
