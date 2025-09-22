class ProfileModel {
  final String uid;
  final String pathPicture;
  final String bio;

  ProfileModel({
    required this.uid,
    required this.pathPicture,
    required this.bio,
  });

  //convert model to map
  Map<String, dynamic> toMap() {
    return {'uid': uid, 'pathPicture': pathPicture, 'bio': bio};
  }

  //convert map to model
  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      uid: map["uid"],
      pathPicture: map["pathPicture"],
      bio: map["bio"],
    );
  }
}
