
class ImagePlaceholder {

  static const int _defaultWidth = 400;
  static const int _defaultHeight = 300;
  static String generate({int? width, int? height}) {
    final int w = width ?? _defaultWidth;
    final int h = height ?? _defaultHeight;

    final String seed = DateTime.now().millisecondsSinceEpoch.toString();

    return 'https://picsum.photos/seed/$seed/$w/$h.jpg';
  }
}