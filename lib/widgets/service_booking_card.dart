import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../models/service_booking.dart';

class ServiceBookingCard extends StatelessWidget {
  final ServiceBooking booking;
  final VoidCallback? onTap;
  const ServiceBookingCard({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: GFCard(
        title: GFListTile(
          titleText: '${booking.workshop} • ${booking.type.name}',
          subTitleText: 'Status: ${booking.status.name} • Estimasi: Rp ${booking.estimatedCost.toStringAsFixed(0)}',
        ),
        content: Text(
          'Jadwal: ${booking.scheduledAt.toLocal().toString().split(' ').first}',
        ),
      ),
    );
  }
}

