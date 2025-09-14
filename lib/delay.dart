import 'package:flutter/material.dart';
import 'package:projectrespawn/auth/login.dart';
import "package:get/get.dart";

class Delay extends StatefulWidget {
  const Delay({super.key});

  @override
  State<Delay> createState() => _DelayState();
}

class _DelayState extends State<Delay> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      Get.to(() => Login(), transition: Transition.downToUp);
    });
  }

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
                right: 24,
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
