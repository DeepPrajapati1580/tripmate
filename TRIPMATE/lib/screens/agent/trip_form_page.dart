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
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _endDate == null) {
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
        final uploadRes = await CloudinaryUploader.uploadImage(
          filePath: _selectedImage!.path,
        );
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
        imageUrl: imageUrl,
        imagePublicId: publicId,
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

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Trip Package"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: _inputDecoration("Title", icon: Icons.title),
                    validator: (v) => v!.isEmpty ? "Enter title" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: _inputDecoration("Description",
                        icon: Icons.description),
                    validator: (v) => v!.isEmpty ? "Enter description" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _destCtrl,
                    decoration:
                    _inputDecoration("Destination", icon: Icons.place),
                    validator: (v) => v!.isEmpty ? "Enter destination" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceCtrl,
                    decoration:
                    _inputDecoration("Price (₹)", icon: Icons.currency_rupee),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Enter price" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _capacityCtrl,
                    decoration: _inputDecoration("Capacity", icon: Icons.people),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Enter capacity" : null,
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickStartDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_startDate == null
                              ? "Pick Start Date"
                              : "Start: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickEndDate,
                          icon: const Icon(Icons.event),
                          label: Text(_endDate == null
                              ? "Pick End Date"
                              : "End: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                          : const Center(
                        child: Text(
                          "Tap to pick image",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _createTrip,
                      icon: _loading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.check_circle),
                      label: Text(_loading ? "Creating..." : "Create Package"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
