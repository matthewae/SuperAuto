import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic_header.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const NeumorphicHeader(title: "Selamat Datang", subtitle: "Jelajahi layanan kami"),
          const SizedBox(height: 12),
          CarouselSlider(
            options: CarouselOptions(
              height: 180.0,
              enlargeCenterPage: true,
              autoPlay: true,
              aspectRatio: 16 / 9,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              viewportFraction: 0.8,
            ),
            items: ['promo_1.png', 'promo_2.png', 'promo_3.png'].map((i) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8.0),
                      image: DecorationImage(
                        image: AssetImage('assets/images/$i'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Mobil Utama'),
              subtitle: const Text('Pilih atau tambahkan mobil'),
              trailing: const Icon(Icons.directions_car),
              onTap: () => context.push('/cars'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Jadwal Servis Terdekat'),
              subtitle: const Text('Belum ada jadwal'),
              trailing: const Icon(Icons.schedule),
              onTap: () => context.push('/booking'),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              GFButton(onPressed: () => context.push('/booking'), text: 'Booking Servis', icon: const Icon(Icons.build)),
              GFButton(onPressed: () => context.push('/catalog'), text: 'Katalog Produk', icon: const Icon(Icons.store)),
              GFButton(onPressed: () => context.push('/promo'), text: 'Promo', icon: const Icon(Icons.card_giftcard)),
              GFButton(onPressed: () => context.push('/loyalty'), text: 'Rewards', icon: const Icon(Icons.redeem)),
            ],
          ),
        ],
      ),
    );
  }
}
