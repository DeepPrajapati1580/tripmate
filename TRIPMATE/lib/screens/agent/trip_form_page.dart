import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/cloudinary_service.dart';
import '../../services/trip_service.dart';
import '../../widgets/itinerary_day_widget.dart';
import '../../models/trip_package.dart';

class TripFormPage extends StatefulWidget {
  const TripFormPage({super.key});

  @override
  State<TripFormPage> createState() => _TripFormPageState();
}

class _TripFormPageState extends State<TripFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _hotelNameCtrl = TextEditingController();
  final _hotelStarsCtrl = TextEditingController();
  final _hotelDescCtrl = TextEditingController();
  final _mealsCtrl = TextEditingController();
  final _activitiesCtrl = TextEditingController();

  // Dates
  DateTime? _startDate, _endDate;

  // Images
  File? _coverImage;
  List<File> _galleryImages = [];
  File? _hotelMainImage;
  List<File> _hotelGalleryImages = [];

  // Other fields
  bool _airportPickup = false;
  bool _loading = false;

  // Global fields
  List<String> meals = [];
  List<String> activities = [];

  // Itinerary
  final List<Map<String, TextEditingController>> _itineraryControllers = [];

  // ------------------ Image Pickers ------------------
  Future<void> _pickImage(Function(File) onSelected) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) onSelected(File(picked.path));
  }

  Future<void> _pickMultipleImages(Function(List<File>) onSelected) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) onSelected(picked.map((e) => File(e.path)).toList());
  }

  // ------------------ Date Pickers ------------------
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

  // ------------------ Create Trip ------------------
  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and pick dates")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Upload images
      String? coverUrl;
      List<String> galleryUrls = [];
      String? hotelMainUrl;
      List<String> hotelGalleryUrls = [];

      if (_coverImage != null) {
        final res = await CloudinaryUploader.uploadImage(filePath: _coverImage!.path);
        coverUrl = res["secure_url"];
      }

      for (final img in _galleryImages) {
        final res = await CloudinaryUploader.uploadImage(filePath: img.path);
        galleryUrls.add(res["secure_url"]!);
      }

      if (_hotelMainImage != null) {
        final res = await CloudinaryUploader.uploadImage(filePath: _hotelMainImage!.path);
        hotelMainUrl = res["secure_url"];
      }

      for (final img in _hotelGalleryImages) {
        final res = await CloudinaryUploader.uploadImage(filePath: img.path);
        hotelGalleryUrls.add(res["secure_url"]!);
      }

      // Global meals & activities
      meals = _mealsCtrl.text.split(",").map((e) => e.trim()).toList();
      activities = _activitiesCtrl.text.split(",").map((e) => e.trim()).toList();

      // Build itinerary
      final itinerary = _itineraryControllers.map((c) {
        return {
          "day": int.tryParse(c["day"]!.text) ?? 0,
          "description": c["desc"]!.text,
          "meals": c["meals"]!.text.split(",").map((e) => e.trim()).toList(),
          "activities": c["activities"]!.text.split(",").map((e) => e.trim()).toList(),
        };
      }).toList();

      // Call your create method
      await TripService.create(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        source: _sourceCtrl.text,
        destination: _destCtrl.text,
        startDate: _startDate!,
        endDate: _endDate!,
        price: int.parse(_priceCtrl.text),
        capacity: int.parse(_capacityCtrl.text),
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        imageUrl: coverUrl,
        gallery: galleryUrls,
        hotelName: _hotelNameCtrl.text,
        hotelDescription: _hotelDescCtrl.text,
        hotelMainImage: hotelMainUrl,
        hotelGallery: hotelGalleryUrls,
        hotelStars: int.tryParse(_hotelStarsCtrl.text),
        meals: meals,
        activities: activities,
        airportPickup: _airportPickup,
        itinerary: itinerary,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip created successfully ✅")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------------------ UI Helpers ------------------
  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.teal) : null,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.teal),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }

  Widget _imagePicker(String label, File? image, Function(File) onPick,
      {bool multiple = false, Function(List<File>)? onPickMultiple}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => multiple && onPickMultiple != null
              ? _pickMultipleImages(onPickMultiple)
              : _pickImage(onPick),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: image != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(image, fit: BoxFit.cover, width: double.infinity))
                : Center(child: Text("Tap to pick ${multiple ? 'images' : 'image'}", style: const TextStyle(color: Colors.grey))),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Trip Package"), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Trip Info
              _sectionCard(
                "Trip Info",
                Column(
                  children: [
                    TextFormField(controller: _titleCtrl, decoration: _inputDecoration("Title", icon: Icons.title), validator: (v) => v!.isEmpty ? "Enter title" : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _descCtrl, maxLines: 3, decoration: _inputDecoration("Description", icon: Icons.description), validator: (v) => v!.isEmpty ? "Enter description" : null),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _sourceCtrl, decoration: _inputDecoration("Source City", icon: Icons.location_city), validator: (v) => v!.isEmpty ? "Enter source city" : null)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _destCtrl, decoration: _inputDecoration("Destination", icon: Icons.place), validator: (v) => v!.isEmpty ? "Enter destination" : null)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _priceCtrl, decoration: _inputDecoration("Price (₹)", icon: Icons.currency_rupee), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? "Enter price" : null)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _capacityCtrl, decoration: _inputDecoration("Capacity", icon: Icons.people), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? "Enter capacity" : null)),
                      ],
                    ),
                  ],
                ),
              ),
              // Dates
              _sectionCard(
                "Dates",
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: _pickStartDate, icon: const Icon(Icons.calendar_today, color: Colors.teal), label: Text(_startDate == null ? "Pick Start Date" : "Start: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}"))),
                    const SizedBox(width: 12),
                    Expanded(child: OutlinedButton.icon(onPressed: _pickEndDate, icon: const Icon(Icons.event, color: Colors.teal), label: Text(_endDate == null ? "Pick End Date" : "End: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}"))),
                  ],
                ),
              ),
              // Images
              _sectionCard(
                "Images",
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _imagePicker("Cover Image", _coverImage, (f) => setState(() => _coverImage = f)),
                    const SizedBox(height: 12),
                    _imagePicker("Gallery Images", null, (_) {}, multiple: true, onPickMultiple: (list) => setState(() => _galleryImages = list)),
                    Wrap(spacing: 8, runSpacing: 8, children: _galleryImages.map((f) => ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover))).toList()),
                  ],
                ),
              ),
              // Hotel Info
              _sectionCard(
                "Hotel Info",
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(controller: _hotelNameCtrl, decoration: _inputDecoration("Hotel Name", icon: Icons.hotel)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _hotelStarsCtrl, decoration: _inputDecoration("Hotel Stars", icon: Icons.star), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextFormField(controller: _hotelDescCtrl, decoration: _inputDecoration("Hotel Description", icon: Icons.description), maxLines: 2),
                    const SizedBox(height: 12),
                    _imagePicker("Hotel Main Image", _hotelMainImage, (f) => setState(() => _hotelMainImage = f)),
                    const SizedBox(height: 8),
                    _imagePicker("Hotel Gallery Images", null, (_) {}, multiple: true, onPickMultiple: (list) => setState(() => _hotelGalleryImages = list)),
                    Wrap(spacing: 8, runSpacing: 8, children: _hotelGalleryImages.map((f) => ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover))).toList()),
                    const SizedBox(height: 12),
                    SwitchListTile(value: _airportPickup, onChanged: (v) => setState(() => _airportPickup = v), title: const Text("Airport Pickup Available")),
                  ],
                ),
              ),
              // Meals & Activities
              _sectionCard(
                "Meals & Activities",
                Column(
                  children: [
                    TextFormField(controller: _mealsCtrl, decoration: _inputDecoration("Meals (comma separated)")),
                    const SizedBox(height: 12),
                    TextFormField(controller: _activitiesCtrl, decoration: _inputDecoration("Activities (comma separated)")),
                  ],
                ),
              ),
              // Itinerary
              _sectionCard(
                "Itinerary",
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Itinerary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: () => setState(() {
                            _itineraryControllers.add({
                              "day": TextEditingController(),
                              "desc": TextEditingController(),
                              "meals": TextEditingController(),
                              "activities": TextEditingController(),
                            });
                          }),
                          icon: const Icon(Icons.add_circle, color: Colors.teal),
                        )
                      ],
                    ),
                    Column(
                      children: _itineraryControllers.map((c) => ItineraryDayField(
                        dayCtrl: c["day"]!,
                        descCtrl: c["desc"]!,
                        mealsCtrl: c["meals"]!,
                        activitiesCtrl: c["activities"]!,
                        onRemove: () => setState(() => _itineraryControllers.remove(c)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _createTrip,
                  icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle),
                  label: Text(_loading ? "Creating..." : "Create Package"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
