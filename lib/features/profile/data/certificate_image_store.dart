import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Copies a picked certificate photo out of the image picker's transient
/// cache into app-owned storage so it's still there after the app restarts
/// (and so the DB can hold a stable path).
Future<String> saveCertificateImage(XFile picked) async {
  final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/achievements');
  await dir.create(recursive: true);
  final extension = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
  final destination = File('${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$extension');
  await destination.writeAsBytes(await picked.readAsBytes());
  return destination.path;
}
