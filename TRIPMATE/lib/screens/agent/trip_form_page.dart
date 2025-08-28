// lib/screens/agent/trip_form_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/cloudinary_service.dart';
import '../../services/trip_service.dart';

class TripFormPage extends StatefulWidget {
  const TripFormPage({super.key});

  @override
  State<TripFormPage> createState() => _TripFormPageState();
}

class _TripFormPageState extends State<TripFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  DateTime? _startDate, _endDate;
  File? _selectedImage;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and pick dates")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? imageUrl;
      String? publicId;

      // ✅ Upload to Cloudinary if image picked
      if (_selectedImage != null) {
        final uploadRes = await CloudinaryUploader.uploadImage(filePath: _selectedImage!.path);
        imageUrl = uploadRes["secure_url"];
        publicId = uploadRes["publicId"];
      }

      await TripService.create(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        destination: _destCtrl.text,
        startDate: _startDate!,
        endDate: _endDate!,
        price: int.parse(_priceCtrl.text),
        capacity: int.parse(_capacityCtrl.text),
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        imageUrl: imageUrl,        // 👈 save Cloudinary URL
        imagePublicId: publicId,   // 👈 save Cloudinary ID
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip created successfully ✅")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Trip Package")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (v) => v!.isEmpty ? "Enter title" : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (v) => v!.isEmpty ? "Enter description" : null,
              ),
              TextFormField(
                controller: _destCtrl,
                decoration: const InputDecoration(labelText: "Destination"),
                validator: (v) => v!.isEmpty ? "Enter destination" : null,
              ),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: "Price (₹)"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter price" : null,
              ),
              TextFormField(
                controller: _capacityCtrl,
                decoration: const InputDecoration(labelText: "Capacity"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter capacity" : null,
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickStartDate,
                    child: Text(_startDate == null
                        ? "Pick Start Date"
                        : "Start: ${_startDate!.toLocal()}".split(' ')[0]),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pickEndDate,
                    child: Text(_endDate == null
                        ? "Pick End Date"
                        : "End: ${_endDate!.toLocal()}".split(' ')[0]),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text("Pick Image"),
                  ),
                  const SizedBox(width: 12),
                  if (_selectedImage != null)
                    Expanded(child: Image.file(_selectedImage!, height: 100)),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createTrip,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Create Package"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
