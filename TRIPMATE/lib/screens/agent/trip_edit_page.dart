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
  late TextEditingController _hotelNameCtrl;
  late TextEditingController _hotelStarsCtrl;
  late TextEditingController _mealsCtrl;
  late TextEditingController _activitiesCtrl;

  DateTime? _startDate, _endDate;

  File? _coverImage;
  Uint8List? _coverImageBytes;
  String? _coverImageName;
  String? _existingCoverUrl;

  List<File> _galleryImages = [];
  List<String> _existingGalleryUrls = [];

  bool _airportPickup = false;

  // Itinerary
  List<Map<String, TextEditingController>> _itinerary = [];

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
    _hotelNameCtrl = TextEditingController(text: data["hotelName"] ?? "");
    _hotelStarsCtrl =
        TextEditingController(text: data["hotelStars"]?.toString() ?? "");
    _mealsCtrl =
        TextEditingController(text: (data["meals"] ?? []).join(", "));
    _activitiesCtrl =
        TextEditingController(text: (data["activities"] ?? []).join(", "));

    _airportPickup = data["airportPickup"] ?? false;

    final start = data["startDate"] as Timestamp?;
    final end = data["endDate"] as Timestamp?;
    _startDate = start?.toDate();
    _endDate = end?.toDate();

    _existingCoverUrl = data["imageUrl"];
    _existingGalleryUrls = List<String>.from(data["gallery"] ?? []);

    // Load itinerary
    final itinerary = List<Map<String, dynamic>>.from(data["itinerary"] ?? []);
    for (var day in itinerary) {
      _itinerary.add({
        "day": TextEditingController(text: day["day"].toString()),
        "description": TextEditingController(text: day["description"] ?? ""),
        "meals":
        TextEditingController(text: (day["meals"] ?? []).join(", ")),
        "activities":
        TextEditingController(text: (day["activities"] ?? []).join(", ")),
      });
    }
  }

  void _addItineraryDay() {
    setState(() {
      _itinerary.add({
        "day": TextEditingController(),
        "description": TextEditingController(),
        "meals": TextEditingController(),
        "activities": TextEditingController(),
      });
    });
  }

  void _removeItineraryDay(int index) {
    setState(() {
      _itinerary[index].values.forEach((c) => c.dispose());
      _itinerary.removeAt(index);
    });
  }

  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _coverImageBytes = bytes;
            _coverImageName = picked.name;
            _coverImage = null;
            _existingCoverUrl = null;
          });
        } else {
          final tempDir = await getTemporaryDirectory();
          final file = await File(picked.path)
              .copy('${tempDir.path}/${picked.name}');
          setState(() {
            _coverImage = file;
            _coverImageBytes = null;
            _coverImageName = null;
            _existingCoverUrl = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick cover image: $e")),
      );
    }
  }

  Future<void> _pickGalleryImages() async {
    final picker = ImagePicker();
    final pickedList = await picker.pickMultiImage();
    if (pickedList.isNotEmpty) {
      setState(() {
        _galleryImages.addAll(pickedList.map((e) => File(e.path)));
      });
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
      String? coverImageUrl = _existingCoverUrl;
      List<String> galleryUrls = List.from(_existingGalleryUrls);

      // Upload cover image if changed
      if (_coverImage != null ||
          (_coverImageBytes != null && _coverImageName != null)) {
        Map<String, String> uploadRes;

        if (kIsWeb) {
          uploadRes = await CloudinaryUploader.uploadImage(
            fileBytes: _coverImageBytes,
            fileName: _coverImageName,
          );
        } else {
          uploadRes =
          await CloudinaryUploader.uploadImage(filePath: _coverImage!.path);
        }

        coverImageUrl = uploadRes["secure_url"];
      }

      // Upload new gallery images
      for (var img in _galleryImages) {
        final res =
        await CloudinaryUploader.uploadImage(filePath: img.path);
        final url = res["secure_url"];
        if (url != null) galleryUrls.add(url);
      }

      // Build itinerary list
      final List<Map<String, dynamic>> itinerary = _itinerary.map((dayCtrl) {
        return {
          "day": int.tryParse(dayCtrl["day"]!.text.trim()) ?? 0,
          "description": dayCtrl["description"]!.text.trim(),
          "meals": dayCtrl["meals"]!.text.isNotEmpty
              ? dayCtrl["meals"]!.text
              .split(",")
              .map((e) => e.trim())
              .toList()
              : <String>[],
          "activities": dayCtrl["activities"]!.text.isNotEmpty
              ? dayCtrl["activities"]!.text
              .split(",")
              .map((e) => e.trim())
              .toList()
              : <String>[],
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection("trip_packages")
          .doc(widget.tripId)
          .update({
        "title": _titleCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "destination": _destCtrl.text.trim(),
        "startDate": _startDate,
        "endDate": _endDate,
        "price": int.parse(_priceCtrl.text.trim()),
        "capacity": int.parse(_capacityCtrl.text.trim()),
        "imageUrl": coverImageUrl,
        "gallery": galleryUrls,
        "hotelName": _hotelNameCtrl.text.trim(),
        "hotelStars":
        int.tryParse(_hotelStarsCtrl.text.trim()) ?? null,
        "meals": _mealsCtrl.text.isNotEmpty
            ? _mealsCtrl.text.split(",").map((e) => e.trim()).toList()
            : [],
        "activities": _activitiesCtrl.text.isNotEmpty
            ? _activitiesCtrl.text.split(",").map((e) => e.trim()).toList()
            : [],
        "airportPickup": _airportPickup,
        "itinerary": itinerary,
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
        borderSide: const BorderSide(color: Colors.teal),
      ),
    );
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
        child: Form(
          key: _formKey,
          child: Column(
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
                decoration:
                _inputDecoration("Description", icon: Icons.description),
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
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Price (₹)",
                    icon: Icons.currency_rupee),
                validator: (v) => v!.isEmpty ? "Enter price" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                decoration:
                _inputDecoration("Capacity", icon: Icons.people),
                validator: (v) => v!.isEmpty ? "Enter capacity" : null,
              ),
              const SizedBox(height: 12),

              // Hotel & extras
              TextFormField(
                controller: _hotelNameCtrl,
                decoration: _inputDecoration("Hotel Name", icon: Icons.hotel),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hotelStarsCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Hotel Stars (1–5)",
                    icon: Icons.star),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mealsCtrl,
                decoration: _inputDecoration("Meals (comma separated)",
                    icon: Icons.restaurant),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _activitiesCtrl,
                decoration: _inputDecoration("Activities (comma separated)",
                    icon: Icons.local_activity),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                value: _airportPickup,
                onChanged: (v) => setState(() => _airportPickup = v),
                title: const Text("Airport Pickup Available"),
                activeColor: Colors.teal,
              ),

              // Itinerary
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Itinerary",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Column(
                children: List.generate(_itinerary.length, (i) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _itinerary[i]["day"],
                                  decoration: _inputDecoration("Day"),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeItineraryDay(i),
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _itinerary[i]["description"],
                            decoration:
                            _inputDecoration("Description"),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _itinerary[i]["meals"],
                            decoration: _inputDecoration("Meals"),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _itinerary[i]["activities"],
                            decoration: _inputDecoration("Activities"),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _addItineraryDay,
                  icon: const Icon(Icons.add, color: Colors.teal),
                  label: const Text("Add Day",
                      style: TextStyle(color: Colors.teal)),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(_startDate == null
                          ? "Pick Start Date"
                          : "Start: ${df.format(_startDate!)}"),
                      onPressed: _pickStartDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(_endDate == null
                          ? "Pick End Date"
                          : "End: ${df.format(_endDate!)}"),
                      onPressed: _pickEndDate,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _coverImage != null
                      ? Image.file(_coverImage!, fit: BoxFit.cover)
                      : _coverImageBytes != null
                      ? Image.memory(_coverImageBytes!,
                      fit: BoxFit.cover)
                      : _existingCoverUrl != null
                      ? Image.network(_existingCoverUrl!,
                      fit: BoxFit.cover)
                      : const Center(
                      child: Text("Tap to select Cover Image")),
                ),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickGalleryImages,
                  icon: const Icon(Icons.photo_library,
                      color: Colors.teal),
                  label: const Text("Add Gallery Images",
                      style: TextStyle(color: Colors.teal)),
                ),
              ),
              if (_existingGalleryUrls.isNotEmpty ||
                  _galleryImages.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    ..._existingGalleryUrls.map((url) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url,
                          width: 80, height: 80, fit: BoxFit.cover),
                    )),
                    ..._galleryImages.map((file) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(file,
                          width: 80, height: 80, fit: BoxFit.cover),
                    )),
                  ],
                ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _loading ? null : _updateTrip,
                  icon: _loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    _loading ? "Updating..." : "Update Package",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
