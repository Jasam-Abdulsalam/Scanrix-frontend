import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Thin wrapper around ML Kit's on-device text recognizer. Kept separate
/// from `AnalyzeTextUseCase` since this is local ML plumbing (turning a
/// photo into text), not a backend call — the use case takes the resulting
/// string and sends it to `POST /scan/analyze-text`.
class OcrTextRecognizer {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  void dispose() => _recognizer.close();
}
