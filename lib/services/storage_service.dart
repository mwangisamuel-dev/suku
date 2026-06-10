import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
  static Future<Directory> _receiptsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final receipts = Directory(p.join(dir.path, 'receipts'));
    if (!receipts.existsSync()) receipts.createSync(recursive: true);
    return receipts;
  }

  static Future<String?> moveReceiptToAppDir(String sourcePath) async {
    try {
      final src = File(sourcePath);
      if (!await src.exists()) return null;
      final receipts = await _receiptsDir();
      final dest = File(p.join(receipts.path, '${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}'));
      await src.copy(dest.path);
      return dest.path;
    } catch (e) {
      return null;
    }
  }

  static Future<double> getCacheSizeMB() async {
    int bytes = 0;
    final temp = await getTemporaryDirectory();
    if (temp.existsSync()) {
      await for (var f in temp.list(recursive: true, followLinks: false)) {
        if (f is File) {
          try {
            bytes += await f.length();
          } catch (_) {}
        }
      }
    }

    final receipts = await _receiptsDir();
    if (receipts.existsSync()) {
      await for (var f in receipts.list(recursive: true, followLinks: false)) {
        if (f is File) {
          try {
            bytes += await f.length();
          } catch (_) {}
        }
      }
    }

    return bytes / (1024 * 1024);
  }

  static Future<void> clearTemporaryCache() async {
    final temp = await getTemporaryDirectory();
    if (!temp.existsSync()) return;
    await for (var f in temp.list(recursive: true, followLinks: false)) {
      try {
        if (f is File) await f.delete();
        if (f is Directory) await f.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Ensure total receipts stored is below [maxTotalMB] by deleting oldest files.
  static Future<void> pruneReceipts({int maxTotalMB = 50}) async {
    final receipts = await _receiptsDir();
    if (!receipts.existsSync()) return;
    final files = receipts
        .listSync()
        .whereType<File>()
        .toList()
      ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    int totalBytes = files.fold(0, (s, f) => s + f.lengthSync());
    final maxBytes = maxTotalMB * 1024 * 1024;
    while (totalBytes > maxBytes && files.isNotEmpty) {
      final f = files.removeAt(0);
      try {
        final len = f.lengthSync();
        f.deleteSync();
        totalBytes -= len;
      } catch (_) {}
    }
  }
}
