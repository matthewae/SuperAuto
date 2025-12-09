// import 'package:flutter/material.dart';
// import 'package:getwidget/getwidget.dart';
// import '../models/service_history.dart';
//
// class ServiceHistoryCard extends StatelessWidget {
//   final ServiceHistoryItem item;
//   final VoidCallback? onTap;
//   const ServiceHistoryCard({super.key, required this.item, this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: GFCard(
//         title: GFListTile(
//           titleText: '${item.date.toLocal().toString().split(' ').first} • KM ${item.km}',
//           subTitleText: 'Rp ${item.totalCost.toStringAsFixed(0)}',
//         ),
//         content: Text('Pekerjaan: ${item.jobs.join(', ')}\nSparepart: ${item.parts.join(', ')}'),
//       ),
//     );
//   }
// }

