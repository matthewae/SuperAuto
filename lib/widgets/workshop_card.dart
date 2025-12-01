import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class WorkshopCard extends StatelessWidget {
  final String name;
  final double? rating; // 0-5
  final String? distance; // e.g., '2.1 km'
  final VoidCallback? onTap;
  const WorkshopCard({super.key, required this.name, this.rating, this.distance, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: GFCard(
        title: GFListTile(
          titleText: name,
          subTitleText: [
            if (rating != null) 'Rating ${rating!.toStringAsFixed(1)}',
            if (distance != null) distance!,
          ].join(' • '),
        ),
      ),
    );
  }
}

