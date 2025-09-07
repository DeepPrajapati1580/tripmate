// lib/screens/agent/trip_edit_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/cloudinary_service.dart';

class TripEditPage extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> existingData;

  const TripEditPage({
    super.key,
    required this.tripId,
    required this.existingData,
  });

  @override
  State<TripEditPage> createState() => _TripEditPageState();
}

class _TripEditPageState extends State<TripEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _destCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _capacityCtrl;

  DateTime? _startDate, _endDate;

  // For image handling
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // for web
  String? _selectedImageName;     // for web

  String? _existingImageUrl;
  String? _existingImagePublicId;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.existingData;
    _titleCtrl = TextEditingController(text: data["title"]);
    _descCtrl = TextEditingController(text: data["description"]);
    _destCtrl = TextEditingController(text: data["destination"]);
    _priceCtrl = TextEditingController(text: data["price"].toString());
    _capacityCtrl = TextEditingController(text: data["capacity"].toString());

    final start = data["startDate"] as Timestamp?;
    final end = data["endDate"] as Timestamp?;
    _startDate = start?.toDate();
    _endDate = end?.toDate();

    _existingImageUrl = data["imageUrl"];
    _existingImagePublicId = data["imagePublicId"];
  }

  /// Pick image cross-platform
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageName = picked.name;
            _selectedImage = null; // no File on web
            _existingImageUrl = null; // hide old preview
          });
        } else {
          final tempDir = await getTemporaryDirectory();
          final file = await File(picked.path).copy('${tempDir.path}/${picked.name}');
          setState(() {
            _selectedImage = file;
            _selectedImageBytes = null;
            _selectedImageName = null;
            _existingImageUrl = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: $e")),
      );
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _updateTrip() async {
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and pick dates")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? imageUrl = _existingImageUrl;
      String? publicId = _existingImagePublicId;

      // Upload new image if picked
      if (_selectedImage != null || (_selectedImageBytes != null && _selectedImageName != null)) {
        Map<String, String> uploadRes;

        if (kIsWeb) {
          uploadRes = await CloudinaryUploader.uploadImage(
            fileBytes: _selectedImageBytes,
            fileName: _selectedImageName,
          );
        } else {
          uploadRes = await CloudinaryUploader.uploadImage(filePath: _selectedImage!.path);
        }

        imageUrl = uploadRes["secure_url"];
        publicId = uploadRes["publicId"];
      }

      await FirebaseFirestore.instance.collection("trip_packages").doc(widget.tripId).update({
        "title": _titleCtrl.text,
        "description": _descCtrl.text,
        "destination": _destCtrl.text,
        "startDate": _startDate,
        "endDate": _endDate,
        "price": int.parse(_priceCtrl.text),
        "capacity": int.parse(_capacityCtrl.text),
        "imageUrl": imageUrl,
        "imagePublicId": publicId,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip updated successfully ✅")),
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
    final df = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Trip Package")),
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
                        : "Start: ${df.format(_startDate!)}"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pickEndDate,
                    child: Text(_endDate == null
                        ? "Pick End Date"
                        : "End: ${df.format(_endDate!)}"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text("Pick Image"),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedImage != null)
                    SizedBox(
                      width: double.infinity,
                      height: 150,
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  else if (_selectedImageBytes != null)
                    SizedBox(
                      width: double.infinity,
                      height: 150,
                      child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                    )
                  else if (_existingImageUrl != null)
                      SizedBox(
                        width: double.infinity,
                        height: 150,
                        child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                      ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _updateTrip,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Update Package"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
