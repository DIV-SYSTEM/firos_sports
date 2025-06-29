import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../services/firebase_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/text_field.dart';
import '../model/user_model.dart';
import '../providers/user_provider.dart';
import '../utils/helpers.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  XFile? _documentImage;
  XFile? _liveImage;
  bool _isMatching = false;
  bool _isRegistering = false;
  String? _dob;
  int? _matchedAge;
  String _selectedDocType = 'Aadhaar';

  final String aadhaarApiUrl = 'https://a5cd-116-72-197-225.ngrok-free.app/api/verify/aadhaar/';
  final String panApiUrl = 'https://a5cd-116-72-197-225.ngrok-free.app/api/verify/pan/';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  int _extractAgeFromDOB(String dob) {
    try {
      final parts = dob.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final birthDate = DateTime(year, month, day);
        final now = DateTime.now();
        int age = now.year - birthDate.year;
        if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
          age--;
        }
        return age;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _pickDocumentImage() async {
    final status = kIsWeb ? PermissionStatus.granted : await Permission.photos.request();
    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (pickedFile != null) {
        setState(() => _documentImage = pickedFile);
        if (kDebugMode) {
          print('Document image selected: ${pickedFile.path}');
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery permission denied')),
      );
    }
  }

  Future<void> _pickLiveImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 100,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (pickedFile != null) {
      setState(() => _liveImage = pickedFile);
      if (kDebugMode) {
        print('Live image selected: ${pickedFile.path}');
      }
    } else if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
      }
    }
  }

  Future<File> _preprocessImage(XFile imageFile) async {
    final file = File(imageFile.path);
    if (!await file.exists()) {
      throw Exception('Image file does not exist: ${imageFile.path}');
    }

    final imageBytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image: ${imageFile.path}');
    }

    image = img.bakeOrientation(image);

    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/${imageFile.name}.jpg');
    await tempFile.writeAsBytes(img.encodeJpg(image, quality: 100));

    return tempFile;
  }

  Future<void> _matchImages() async {
    if (_documentImage == null || _liveImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both images')),
      );
      return;
    }

    setState(() => _isMatching = true);

    try {
      final apiUrl = _selectedDocType == 'Aadhaar' ? aadhaarApiUrl : panApiUrl;
      final uri = Uri.parse(apiUrl);
      final request = http.MultipartRequest('POST', uri);

      final documentField = _selectedDocType == 'Aadhaar' ? 'aadhaar_image' : 'pan_image';

      final documentFile = await _preprocessImage(_documentImage!);
      final selfieFile = await _preprocessImage(_liveImage!);

      request.files.add(await http.MultipartFile.fromPath(documentField, documentFile.path));
      request.files.add(await http.MultipartFile.fromPath('selfie_image', selfieFile.path));
      request.headers['Accept'] = 'application/json';

      final streamedResponse = await request.send().timeout(const Duration(seconds: 50));
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('API response: ${response.statusCode}, body: ${response.body}');
      }

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['verified'] == true) {
        setState(() {
          _dob = data['dob'];
          _matchedAge = _extractAgeFromDOB(_dob!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face matched! Age: $_matchedAge')),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Verification Failed'),
            content: Text(data['message'] ?? 'Unknown error'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _matchImages: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isMatching = false);
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _matchedAge != null && _liveImage != null) {
      setState(() => _isRegistering = true);
      try {
        final imageFile = File(_liveImage!.path);
        final bytes = await imageFile.readAsBytes();
        final imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        final user = UserModel(
          id: const Uuid().v4(),
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          age: _matchedAge,
          imageUrl: imageUrl,
        );

        await FirebaseService().registerUser(user, imageFile);
        Provider.of<UserProvider>(context, listen: false).setUser(user);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error in _register: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isRegistering = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete form and match images first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDocType,
                decoration: const InputDecoration(labelText: 'Choose Document Type'),
                items: const [
                  DropdownMenuItem(value: 'Aadhaar', child: Text('Aadhaar')),
                  DropdownMenuItem(value: 'PAN', child: Text('PAN')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDocType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Name',
                controller: _nameController,
                validator: Helpers.validateName,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                validator: Helpers.validateEmail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
                validator: Helpers.validatePassword,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomButton(
                    text: 'Upload $_selectedDocType',
                    onPressed: _pickDocumentImage,
                  ),
                  CustomButton(
                    text: 'Capture Live Photo',
                    onPressed: _pickLiveImage,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_documentImage != null) Text('$_selectedDocType Image Selected'),
              if (_liveImage != null) const Text('Live Photo Selected'),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Match Images',
                onPressed: _matchImages,
                isLoading: _isMatching,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Register',
                onPressed: _register,
                isLoading: _isRegistering,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Skip to HomeScreen',
                onPressed: () {
                  final user = UserModel(
                    id: const Uuid().v4(),
                    name: 'Dummy User',
                    email: 'dummy@example.com',
                    password: 'DummyPass123!',
                    age: 35,
                  );
                  Provider.of<UserProvider>(context, listen: false).setUser(user);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
