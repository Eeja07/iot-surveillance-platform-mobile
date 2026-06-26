import 'dart:io';

void main() async {
  print("🔍 Mencari file tensor.dart...");

  String? home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) {
    print("❌ Gagal menemukan direktori Home.");
    return;
  }

  String pathPart = 'hosted/pub.dev/tflite_flutter-0.10.4/lib/src/tensor.dart';

  List<String> possiblePaths = [
    '$home/AppData/Local/Pub/Cache/$pathPart',
    '$home/.pub-cache/$pathPart',
  ];

  File? tensorFile;

  for (var p in possiblePaths) {
    var f = File(p);
    if (await f.exists()) {
      tensorFile = f;
      break;
    }
  }

  if (tensorFile == null) {
    print(
      "❌ File tidak ditemukan. Pastikan sudah menjalankan 'flutter pub get'",
    );
    return;
  }

  print("✅ File ditemukan: ${tensorFile.path}");

  try {
    String content = await tensorFile.readAsString();

    const String badCode = '''
  Uint8List get data {
    final data = cast<Uint8>(tfliteBinding.TfLiteTensorData(_tensor));
    return UnmodifiableUint8ListView(
        data.asTypedList(tfliteBinding.TfLiteTensorByteSize(_tensor)));
  }''';

    const String goodCode = '''
  Uint8List get data {
    final data = cast<Uint8>(tfliteBinding.TfLiteTensorData(_tensor));
    return data.asTypedList(tfliteBinding.TfLiteTensorByteSize(_tensor));
  }''';

    if (content.contains('UnmodifiableUint8ListView')) {
      String newContent = content.replaceFirst(
        'return UnmodifiableUint8ListView(\n        data.asTypedList(tfliteBinding.TfLiteTensorByteSize(_tensor)));',
        'return data.asTypedList(tfliteBinding.TfLiteTensorByteSize(_tensor));',
      );

      if (newContent == content) {
        newContent = content.replaceAll('UnmodifiableUint8ListView(', '');
        newContent = newContent.replaceAll(
          'tfliteBinding.TfLiteTensorByteSize(_tensor)))',
          'tfliteBinding.TfLiteTensorByteSize(_tensor))',
        );
      }

      await tensorFile.writeAsString(newContent);
      print("🎉 SUKSES! File telah dipatch.");
    } else {
      print("⚠️ File sepertinya sudah diperbaiki sebelumnya.");
    }
  } catch (e) {
    print("❌ Error: $e");
  }
}
