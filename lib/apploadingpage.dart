import 'package:flutter/material.dart';

class Apploadingpage extends StatefulWidget {
  const Apploadingpage({super.key});

  @override
  State<Apploadingpage> createState() => _ApploadingpageState();
}

class _ApploadingpageState extends State<Apploadingpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/image 2.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/LOGO 1.png", width: 248, height: 248),
                  const SizedBox(height: 16),
                  CircularProgressIndicator.adaptive(),
                ],
              ),
              Positioned(
                top: -90,
                left: -50,
                child: Image.asset(
                  "assets/image-removebg-preview 1.png",
                  width: 346,
                  height: 541,
                ),
              ),
              Positioned(
                top: 234,
                right: -40,
                child: Image.asset(
                  "assets/image-removebg-preview (1) 1.png",
                  width: 260,
                  height: 280,
                ),
              ),
              Positioned(
                left: 30,
                bottom: 156,
                child: Image.asset(
                  "assets/image-removebg-preview (2) 1.png",
                  width: 156,
                  height: 156,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
