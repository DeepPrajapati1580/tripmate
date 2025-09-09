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

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

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
            _selectedImage = null;
            _existingImageUrl = null;
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
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
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
      appBar: AppBar(
        title: const Text("Edit Trip Package"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Title
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: "Title",
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "Enter title" : null,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Description",
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "Enter description" : null,
                  ),
                  const SizedBox(height: 12),

                  // Destination
                  TextFormField(
                    controller: _destCtrl,
                    decoration: InputDecoration(
                      labelText: "Destination",
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "Enter destination" : null,
                  ),
                  const SizedBox(height: 12),

                  // Price
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Price (₹)",
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "Enter price" : null,
                  ),
                  const SizedBox(height: 12),

                  // Capacity
                  TextFormField(
                    controller: _capacityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Capacity",
                      prefixIcon: const Icon(Icons.people),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "Enter capacity" : null,
                  ),
                  const SizedBox(height: 16),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _startDate == null ? "Pick Start Date" : "Start: ${df.format(_startDate!)}",
                          ),
                          onPressed: _pickStartDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event),
                          label: Text(
                            _endDate == null ? "Pick End Date" : "End: ${df.format(_endDate!)}",
                          ),
                          onPressed: _pickEndDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text("Pick Image"),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover)
                            : _selectedImageBytes != null
                            ? Image.memory(_selectedImageBytes!, height: 150, width: double.infinity, fit: BoxFit.cover)
                            : _existingImageUrl != null
                            ? Image.network(_existingImageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover)
                            : Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Center(child: Text("No Image Selected")),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _loading ? null : _updateTrip,
                      icon: _loading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Icon(Icons.save),
                      label: Text(
                        _loading ? "Updating..." : "Update Package",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
