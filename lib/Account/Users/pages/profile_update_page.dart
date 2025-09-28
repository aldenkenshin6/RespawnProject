import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectrespawn/auth/auth_service.dart';

class ProfileUpdatePage extends StatefulWidget {
  const ProfileUpdatePage({super.key});

  @override
  State<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  File? _imageFile;
  Uint8List? _webImageBytes; // for web preview
  bool _isLoading = false;

  final ImagePicker picker = ImagePicker();

  /// 🔹 Pick image and save locally (preview + upload later)
  Future<void> _pickImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imageFile = null; // web doesn’t use File
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImageBytes = null;
        });
      }
    }
  }

  /// 🔹 Upload to Cloudinary
  Future<String?> uploadImageToCloudinary(XFile pickedFile) async {
    const cloudName = "ditzlkqag";
    const uploadPreset = "profile";

    var uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );
    var request = http.MultipartRequest("POST", uri);
    request.fields["upload_preset"] = uploadPreset;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes("file", bytes, filename: pickedFile.name),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath("file", pickedFile.path),
      );
    }

    var response = await request.send();
    var resData = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(resData.body);
      return data["secure_url"]; // ✅ hosted Cloudinary URL
    } else {
      print("❌ Upload failed: ${resData.body}");
      return null;
    }
  }

  /// 🔹 Save profile (Firestore + Cloudinary)
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      String? photoUrl;
      if (_imageFile != null || _webImageBytes != null) {
        final pickedXFile = kIsWeb
            ? XFile.fromData(_webImageBytes!, name: "profile.jpg")
            : XFile(_imageFile!.path);

        photoUrl = await uploadImageToCloudinary(pickedXFile);
      }

      final currentUser = authService.value.currentUser;
      if (currentUser != null) {
        final userDoc = FirebaseFirestore.instance
            .collection("users")
            .doc(currentUser.uid);

        await userDoc.update({
          if (_nameController.text.isNotEmpty)
            "displayName": _nameController.text.trim(),
          if (_bioController.text.isNotEmpty) "bio": _bioController.text.trim(),
          if (photoUrl != null) "photoUrl": photoUrl,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile updated successfully!")),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF830A0A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🔹 Profile Picture Preview
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _webImageBytes != null
                    ? MemoryImage(_webImageBytes!)
                    : (_imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : null),
                child: (_imageFile == null && _webImageBytes == null)
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 40),

            /// 🔹 Name Input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Display Name"),
            ),
            const SizedBox(height: 20),

            /// 🔹 Bio Input
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: "Bio"),
            ),
            const SizedBox(height: 40),

            /// 🔹 Save Button
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF830A0A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Save Changes"),
                  ),
          ],
        ),
      ),
    );
  }
}
