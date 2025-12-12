
class ImagePlaceholder {
  // Menggunakan Lorem Picsum untuk gambar placeholder acak
  // Anda bisa mengubah ukuran default di sini
  static const int _defaultWidth = 400;
  static const int _defaultHeight = 300;

  /// Menghasilkan URL gambar placeholder yang unik setiap kali dipanggil.
  /// [width] dan [height] bisa disesuaikan.
  static String generate({int? width, int? height}) {
    final int w = width ?? _defaultWidth;
    final int h = height ?? _defaultHeight;

    // Menggunakan timestamp sebagai 'seed' agar gambar selalu berbeda
    final String seed = DateTime.now().millisecondsSinceEpoch.toString();

    return 'https://picsum.photos/seed/$seed/$w/$h.jpg';
  }
}