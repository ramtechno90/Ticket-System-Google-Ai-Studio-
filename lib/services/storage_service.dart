import 'package:firebase_storage/firebase_storage.dart';
import 'package:cross_file/cross_file.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required XFile file,
    required String path,
  }) async {
    final ref = _storage.ref().child(path);
    final data = await file.readAsBytes();
    // content-type can be inferred by Firebase Storage or passed if known.
    // XFile mimeType might be null.
    final metadata = SettableMetadata(
      contentType: file.mimeType,
    );

    final task = ref.putData(data, metadata);
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }
}
