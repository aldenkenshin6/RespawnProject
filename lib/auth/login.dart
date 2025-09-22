import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projectrespawn/auth/auth_service.dart';
import 'package:projectrespawn/auth/register.dart';
import 'package:projectrespawn/auth_layout.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  String errorMessage = "";

  void checkLogin() async {
    try {
      UserCredential userCredential = await authService.value.signIn(
        username: username.text.trim(),
        password: password.text.trim(),
      );
      if (userCredential.user != null) {
        Get.offAll(() => AuthLayout(), transition: Transition.fadeIn);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                opacity: 0.5,
                image: AssetImage("assets/image 2.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 223,
                  child: Image.asset(
                    "assets/Login.png",
                    width: 231,
                    height: 107,
                  ),
                ),
                Positioned(
                  top: 300,
                  child: Image.asset(
                    "assets/Line 1.png",
                    width: 280,
                    height: 36,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/LOGO 1.png",
                      width: 248,
                      height: 248,
                      opacity: const AlwaysStoppedAnimation(0.5),
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
                    opacity: const AlwaysStoppedAnimation(0.5),
                  ),
                ),
                Positioned(
                  top: 234,
                  right: -40,
                  child: Image.asset(
                    "assets/image-removebg-preview (1) 1.png",
                    width: 260,
                    height: 280,
                    opacity: const AlwaysStoppedAnimation(0.5),
                  ),
                ),
                Positioned(
                  left: 30,
                  bottom: 156,
                  child: Image.asset(
                    "assets/image-removebg-preview (2) 1.png",
                    width: 156,
                    height: 156,
                    opacity: const AlwaysStoppedAnimation(0.5),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(60),
                  margin: EdgeInsets.only(top: 340),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      255,
                      255,
                      255,
                    ).withOpacity(0.9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 25),
                      TextField(
                        style: TextStyle(fontSize: 20, height: 1.5),
                        controller: username,
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(),
                          hintText: "Enter Username",
                          labelText: "Username",
                        ),
                      ),
                      const SizedBox(height: 50),
                      TextField(
                        style: TextStyle(fontSize: 24, height: 1.5),
                        obscureText: true,
                        controller: password,
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(),
                          hintText: "Enter Password",
                          labelText: "Password",
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              "Forgot the password?",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 206, 34, 34),
                        ),
                      ),
                      const SizedBox(height: 90),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF830A0A),
                          fixedSize: const Size(300, 53),
                        ),
                        onPressed: () {
                          checkLogin();
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () {
                          Get.to(
                            () => Register(),
                            transition: Transition.rightToLeft,
                          );
                        },
                        child: Text("Create an account"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
