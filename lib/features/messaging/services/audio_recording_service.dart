import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service for recording audio messages.
///
/// Handles the MissingPluginException that can occur with path_provider
/// by providing fallback mechanisms and proper error handling.
class AudioRecordingService {
  AudioRecordingService();

  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isInitialized = false;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Initialize the recording service and request permissions
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission denied');
        return false;
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to initialize audio recording: $e');
      return false;
    }
  }

  /// Get the path for saving audio files.
  ///
  /// Handles MissingPluginException by using fallback paths.
  Future<String> _getRecordingPath() async {
    try {
      // Try to get the application documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String recordingsDir = p.join(appDir.path, 'recordings');

      // Create the recordings directory if it doesn't exist
      final Directory dir = Directory(recordingsDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Generate a unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = p.join(recordingsDir, 'audio_$timestamp.m4a');

      return filePath;
    } catch (e) {
      debugPrint('Failed to get recording path from path_provider: $e');
      // Fallback: use temporary directory
      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        return p.join(tempDir.path, 'audio_$timestamp.m4a');
      } catch (e2) {
        debugPrint('Failed to get temporary directory: $e2');
        // Final fallback: use current directory
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        return 'audio_$timestamp.m4a';
      }
    }
  }

  /// Start recording audio
  Future<String?> startRecording() async {
    if (_isRecording) {
      debugPrint('Already recording');
      return null;
    }

    if (!await initialize()) {
      debugPrint('Failed to initialize audio recording');
      return null;
    }

    try {
      // Get the recording path
      final String filePath = await _getRecordingPath();
      _currentRecordingPath = filePath;

      // Configure recording settings
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      // Start recording
      await _recorder.start(config, path: filePath);
      _isRecording = true;

      debugPrint('Started recording to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return null;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      debugPrint('Not recording');
      return null;
    }

    try {
      final String? path = await _recorder.stop();
      _isRecording = false;

      debugPrint('Stopped recording, file saved to: $path');
      return path ?? _currentRecordingPath;
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      _isRecording = false;
      return _currentRecordingPath;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();
      _isRecording = false;

      // Delete the file if it exists
      if (_currentRecordingPath != null) {
        final File file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted cancelled recording: $_currentRecordingPath');
        }
      }
    } catch (e) {
      debugPrint('Failed to cancel recording: $e');
    } finally {
      _currentRecordingPath = null;
    }
  }

  /// Check if the recorder is available
  Future<bool> isAvailable() async {
    try {
      return await _recorder.isRecorderAvailable();
    } catch (e) {
      debugPrint('Failed to check recorder availability: $e');
      return false;
    }
  }

  /// Dispose of the recorder
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }
      await _recorder.dispose();
    } catch (e) {
      debugPrint('Failed to dispose recorder: $e');
    }
  }
}
