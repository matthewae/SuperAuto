import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../models/car.dart';

class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const CarCard({super.key, required this.car, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GFCard(
      title: GFListTile(
        avatar: const Icon(Icons.directions_car),
        titleText: '${car.brand} ${car.model} (${car.year})',
        subTitleText: '${car.plateNumber} • KM awal: ${car.initialKm}',
        onTap: onTap,
        icon: onDelete != null
            ? IconButton(icon: const Icon(Icons.delete), onPressed: onDelete)
            : null,
      ),
    );
  }
}

