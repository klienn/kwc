import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker
import 'dart:io';

import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart'; // For NavigationStates

class Profile extends StatefulWidget implements NavigationStates {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ImagePicker _picker = ImagePicker(); // Create ImagePicker instance
  File? _profileImage; // Variable to store selected profile image
  bool isPickerActive = false; // Flag to check if image picker is active

  // Controllers to handle text input
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController ageController = TextEditingController();

  // Placeholder data (This could come from your auth service or user profile data)
  String name = 'John Doe';
  String username = 'johndoe123';
  String address = '123 Main Street';
  String age = '25';

  bool isEditing = false; // Variable to track if profile is in edit mode

  @override
  void initState() {
    super.initState();

    // Initializing controllers with existing data
    nameController.text = name;
    usernameController.text = username;
    addressController.text = address;
    ageController.text = age;
  }

  // Method to pick an image from the gallery or camera
  Future<void> _pickImage() async {
    if (isPickerActive) {
      return; // Prevent opening the picker if it's already active
    }

    setState(() {
      isPickerActive = true; // Set flag to true when picker is in use
    });

    try {
      final pickedFile = await _picker.pickImage(
        source:
            ImageSource.gallery, // You can change this to ImageSource.camera
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });

        // Upload the image to Firebase after picking
        await _uploadImageToFirebase(_profileImage!);
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image. Please try again.")),
      );
    } finally {
      setState(() {
        isPickerActive =
            false; // Reset the flag when the image picker session ends
      });
    }
  }

  // Method to upload image to Firebase Storage
  Future<void> _uploadImageToFirebase(File imageFile) async {
    try {
      // Get a reference to Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;

      // Create a unique file name
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Create a reference to the file in Firebase Storage
      Reference ref = storage.ref().child('profile_images/$fileName');

      // Upload the file to Firebase Storage
      await ref.putFile(imageFile);

      // Get the download URL of the uploaded file
      String downloadURL = await ref.getDownloadURL();

      // You can now save this URL to your database or use it for the profile picture
      print('Profile Image uploaded! Download URL: $downloadURL');

      // Optionally, you can save this URL to Firestore or your app's user profile database
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image. Please try again.")),
      );
    }
  }

  // Method to save the updated data
  void _saveProfile() {
    setState(() {
      // Update the profile data
      name = nameController.text;
      username = usernameController.text;
      address = addressController.text;
      age = ageController.text;

      // Show a snackbar to indicate profile was updated
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile updated successfully")),
      );

      // Switch to View mode after saving
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffa7beae),
      appBar: AppBar(
        title: Center(
          child: Text(
            "Profile", // Text centered in the AppBar
            style: TextStyle(
              fontSize: 24, // You can adjust the size
              fontWeight:
                  FontWeight.bold, // Optional: Add bold weight to the title
            ),
          ),
        ),
        backgroundColor: Color(0xffF98866),
        elevation: 0.0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center horizontally
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: _pickImage, // Trigger image picker when tapped
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!) // Display selected image
                        : null,
                    child: _profileImage == null
                        ? Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 40,
                          ) // Placeholder icon if no image selected
                        : null,
                  ),
                ),
                SizedBox(height: 20),

                // Name field (editable if in edit mode)
                isEditing
                    ? TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: Colors.black),
                          filled: true,
                          fillColor: Color(0xffF7F7F7),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xffF98866), // Border color
                              width: 2.0, // Border width
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      )
                    : Text(
                        'Full Name: $name', // Display name if not editing
                        style: TextStyle(fontSize: 18),
                      ),
                SizedBox(height: 10),

                // Username field (editable if in edit mode)
                isEditing
                    ? TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(color: Colors.black),
                          filled: true,
                          fillColor: Color(0xffF7F7F7),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xffF98866),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      )
                    : Text(
                        'Username: $username', // Display username if not editing
                        style: TextStyle(fontSize: 18),
                      ),
                SizedBox(height: 10),

                // Address field (editable if in edit mode)
                isEditing
                    ? TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          labelStyle: TextStyle(color: Colors.black),
                          filled: true,
                          fillColor: Color(0xffF7F7F7),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xffF98866),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      )
                    : Text(
                        'Address: $address', // Display address if not editing
                        style: TextStyle(fontSize: 18),
                      ),
                SizedBox(height: 10),

                // Age field (editable if in edit mode)
                isEditing
                    ? TextField(
                        controller: ageController,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          labelStyle: TextStyle(color: Colors.black),
                          filled: true,
                          fillColor: Color(0xffF7F7F7),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xffF98866),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      )
                    : Text(
                        'Age: $age', // Display age if not editing
                        style: TextStyle(fontSize: 18),
                      ),
                SizedBox(height: 20),

                // Toggle between Edit and View mode
                isEditing
                    ? ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffF98866),
                        ),
                        child: Text("Save Changes"),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isEditing = true; // Switch to Edit mode
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffF98866),
                        ),
                        child: Text("Edit Profile"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
