import 'dart:io';
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Wrapper around the `record` package for voice messages.
///
/// The backend stores messages as text only, so a voice message is sent as
/// an audio attachment. The attachment is uploaded to the
/// `/conversations/{id}/messages/{messageId}/audio` endpoint and the message
/// body is replaced with a placeholder like "Voice message" until the
/// upload completes.
class VoiceMessageService {
  VoiceMessageService({AudioRecorder? record}) : _record = record ?? AudioRecorder();

  final AudioRecorder _record;
  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  /// Start recording audio to a temp file.
  Future<String> startRecording() async {
    if (_isRecording) return _currentPath ?? '';

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _record.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );

    _isRecording = true;
    _currentPath = path;
    return path;
  }

  /// Stop recording and return the file path.
  Future<String?> stopRecording() async {
    if (!_isRecording) return _currentPath;
    final path = await _record.stop();
    _isRecording = false;
    _currentPath = path;
    return path;
  }

  /// Cancel the current recording and delete the temp file.
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _record.stop();
      _isRecording = false;
    }
    final path = _currentPath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _currentPath = null;
  }

  /// Check whether a recording is in progress.
  Stream<Amplitude> get onAmplitudeChanged =>
      _record.onAmplitudeChanged(const Duration(milliseconds: 100));
 Future<void> dispose() async {
    await cancelRecording();
    await _record.dispose();
  }
}