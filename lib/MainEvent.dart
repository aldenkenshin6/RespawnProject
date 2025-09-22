import 'package:flutter/material.dart';
import "package:get/get.dart";
import 'package:projectrespawn/auth/login.dart';
import 'package:projectrespawn/auth/register.dart';

class MainEvent extends StatefulWidget {
  const MainEvent({super.key});

  @override
  State<MainEvent> createState() => _MainEventState();
}

class _MainEventState extends State<MainEvent> {
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
                  const SizedBox(height: 70),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF830A0A),
                          fixedSize: Size(150, 54),
                        ),
                        onPressed: () {
                          Get.to(
                            () => Login(),
                            transition: Transition.leftToRightWithFade,
                          );
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          fixedSize: Size(150, 54),
                        ),
                        onPressed: () {
                          Get.to(
                            () => Register(),
                            transition: Transition.rightToLeftWithFade,
                          );
                        },
                        child: Text(
                          "Register",
                          style: TextStyle(fontSize: 17, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
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
                bottom: 100,
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
