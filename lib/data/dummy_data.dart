import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/enums.dart';
import '../models/bundling.dart';
import '../models/promo.dart';
import '../providers/app_providers.dart';

import '../data/dao/product_dao.dart';

Future<void> seedDummyData(WidgetRef ref) async {
  final uuid = const Uuid();
  final products = [
    Product(
      id: uuid.v4(),
      name: 'Oli Mesin 5W-30',
      category: ProductCategory.oil,
      description: 'Oli mesin sintetik 5W-30 untuk performa optimal.',
      price: 150000,
      compatibleModels: const ['Civic', 'Avanza', 'Yaris'],
    ),
    Product(
      id: uuid.v4(),
      name: 'Filter Oli',
      category: ProductCategory.engineParts,
      description: 'Filter oli OEM quality.',
      price: 50000,
      compatibleModels: const ['Civic', 'Avanza'],
    ),
    Product(
      id: uuid.v4(),
      name: 'Brake Pad',
      category: ProductCategory.brakes,
      description: 'Kampas rem depan.',
      price: 300000,
      compatibleModels: const ['Civic'],
    ),
    Product(
      id: uuid.v4(),
      name: 'Wiper Blade',
      category: ProductCategory.exteriorAccessories,
      description: 'Karet wiper 24 inch.',
      price: 80000,
    ),
    Product(
      id: uuid.v4(),
      name: 'Klakson Hella Black Twin Tone',
      category: ProductCategory.accessories,
      description: 'Klakson mobil Hella Black Twin Tone, suara nyaring dan elegan.',
      price: 250000,
      compatibleModels: const ['Semua Model'],
      imageUrl: 'https://via.placeholder.com/150/000000/FFFFFF?text=Klakson+Hella',
    ),
    Product(
      id: uuid.v4(),
      name: 'Lampu LED Philips Ultinon Essential',
      category: ProductCategory.electronics,
      description: 'Lampu depan LED Philips Ultinon Essential, terang dan tahan lama.',
      price: 600000,
      compatibleModels: const ['Semua Model'],
      imageUrl: 'https://via.placeholder.com/150/FFFF00/000000?text=Lampu+LED+Philips',
    ),
    Product(
      id: uuid.v4(),
      name: 'Kamera Mundur Universal',
      category: ProductCategory.electronics,
      description: 'Kamera mundur universal dengan tampilan jernih untuk keamanan parkir.',
      price: 350000,
      compatibleModels: const ['Semua Model'],
      imageUrl: 'https://via.placeholder.com/150/808080/FFFFFF?text=Kamera+Mundur',
    ),
  ];

  ref.read(bundlingsProvider.notifier).set([
    Bundling(
      id: uuid.v4(),
      name: 'Paket Ganti Oli Hemat',
      description: 'Oli + Filter Oli dengan harga spesial.',
      productIds: [products[0].id, products[1].id],
      bundlePrice: 180000,
    ),
    Bundling(
      id: uuid.v4(),
      name: 'Paket Tune-up',
      description: 'Perawatan rutin untuk performa mesin.',
      productIds: [products[0].id],
      bundlePrice: 200000,
    ),
  ]);

  ref.read(promosProvider.notifier).set([
    Promo(
      id: uuid.v4(),
      name: 'Diskon Sparepart 10%',
      type: 'product_discount',
      value: 10,
      start: DateTime.now().subtract(const Duration(days: 1)),
      end: DateTime.now().add(const Duration(days: 30)),
    ),
    Promo(
      id: uuid.v4(),
      name: 'Diskon Servis 15%',
      type: 'service_discount',
      value: 15,
      start: DateTime.now().subtract(const Duration(days: 1)),
      end: DateTime.now().add(const Duration(days: 30)),
    ),
  ]);

}
