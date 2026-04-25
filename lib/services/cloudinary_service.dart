import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String _cloudName = 'drqu9hydp';
  static const String _uploadPreset = 'smartrent_uploads';
  static const String _folder = 'gowns';

  static Future<String?> uploadImage(File image, String gownCode) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = '$_folder/$gownCode'
        ..files.add(
          await http.MultipartFile.fromPath('file', image.path),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return jsonData['secure_url'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<String>> uploadImages(
      List<File> images, String gownCode) async {
    final List<String> urls = [];
    for (final image in images) {
      final url = await uploadImage(image, gownCode);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  // // Returns an optimized URL for displaying in the app
  // static String optimizeUrl(String originalUrl, {int width = 800}) {
  //   return originalUrl.replaceFirst(
  //     '/upload/',
  //     '/upload/w_$width,q_auto,f_auto/',
  //   );
  // }
}