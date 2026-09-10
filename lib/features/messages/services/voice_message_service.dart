import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Unified service for recording voice messages.
///
/// Single canonical recorder used by the whole app. Records AAC-LC .m4a
/// files into the temp directory. Path-provider calls are wrapped so a
/// MissingPluginException falls back to a safe location instead of crashing.
class VoiceMessageService {
  VoiceMessageService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _currentRecordingPath;
  bool _isRecording = false;
  DateTime? _startedAt;

  bool get isRecording => _isRecording;

  Duration? get recordingDuration =>
      _isRecording && _startedAt != null
          ? DateTime.now().difference(_startedAt!)
          : null;

  String? get currentPath => _currentRecordingPath;

  Future<bool> isAvailable() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('Recorder availability check failed');
      return false;
    }
  }

  Future<String> _getRecordingPath() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final filename = 'audio_msg_$timestamp.m4a';
    try {
      final Directory tempDir = await getTemporaryDirectory();
      return p.join(tempDir.path, filename);
    } catch (e) {
      debugPrint('Temp dir unavailable');
      try {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String recordingsDir = p.join(appDir.path, 'recordings');
        final Directory dir = Directory(recordingsDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return p.join(recordingsDir, filename);
      } catch (e2) {
        debugPrint('Documents dir unavailable');
        return filename;
      }
    }
  }

  Future<String?> startRecording() async {
    if (_isRecording) return _currentRecordingPath;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission denied');
        return null;
      }
      final String filePath = await _getRecordingPath();
      _currentRecordingPath = filePath;
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      );
      await _recorder.start(config, path: filePath);
      _isRecording = true;
      _startedAt = DateTime.now();
      return filePath;
    } catch (e) {
      debugPrint('Failed to start recording');
      _isRecording = false;
      _currentRecordingPath = null;
      _startedAt = null;
      return null;
    }
  }

  Future<RecordedAudio?> stopRecording() async {
    if (!_isRecording) return null;
    try {
      final duration = recordingDuration;
      final String? path = await _recorder.stop();
      _isRecording = false;
      final resolved = path ?? _currentRecordingPath;
      if (resolved == null) return null;
      final tooShort = await _rejectIfTooShort(resolved, duration);
      if (tooShort != null) return tooShort;
      _currentRecordingPath = resolved;
      return RecordedAudio(resolved, duration?.inSeconds ?? 0);
    } catch (e) {
      debugPrint('Failed to stop recording');
      _isRecording = false;
      final resolved = _currentRecordingPath;
      if (resolved == null) return null;
      return RecordedAudio(resolved, 0);
    } finally {
      _startedAt = null;
    }
  }

  Future<RecordedAudio?> _rejectIfTooShort(
    String resolved,
    Duration? duration,
  ) async {
    try {
      final file = File(resolved);
      if (await file.exists()) {
        final size = await file.length();
        final secs = duration?.inSeconds ?? 0;
        if (size < 1024 || secs < 1) {
          await deleteRecording(resolved);
          _currentRecordingPath = null;
          return RecordedAudio.tooShort();
        }
      }
    } catch (e) {
      debugPrint('Recording size check failed');
    }
    return null;
  }

  Future<void> cancelRecording() async {
    if (_isRecording) {
      try {
        await _recorder.stop();
      } catch (e) {
        debugPrint('Failed to stop recorder on cancel');
      }
      _isRecording = false;
    }
    _startedAt = null;
    await deleteRecording(_currentRecordingPath);
    _currentRecordingPath = null;
  }

  Stream<Amplitude> get onAmplitudeChanged =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  Future<void> deleteRecording(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete recording');
    }
  }

  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }
      await deleteRecording(_currentRecordingPath);
      _currentRecordingPath = null;
      await _recorder.dispose();
    } catch (e) {
      debugPrint('Failed to dispose recorder');
    }
  }
}

class RecordedAudio {
  RecordedAudio(this.path, this.durationSeconds) : isTooShort = false;
  RecordedAudio.tooShort()
      : path = '',
        durationSeconds = 0,
        isTooShort = true;
  final String path;
  final int durationSeconds;
  final bool isTooShort;
}

typedef AudioRecordingService = VoiceMessageService;
