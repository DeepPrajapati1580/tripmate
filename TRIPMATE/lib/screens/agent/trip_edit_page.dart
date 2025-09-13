// lib/screens/agent/trip_edit_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/cloudinary_service.dart';
import '../../services/trip_service.dart';
import '../../models/trip_package.dart';
import '../../widgets/itinerary_day_widget.dart';

class TripEditPage extends StatefulWidget {
  final String tripId;
  const TripEditPage({super.key, required this.tripId});

  @override
  State<TripEditPage> createState() => _TripEditPageState();
}

class _TripEditPageState extends State<TripEditPage> {
  final _formKey = GlobalKey<FormState>();
  final df = DateFormat("dd MMM yyyy");

  // Controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _hotelNameCtrl = TextEditingController();
  final _hotelDescCtrl = TextEditingController();
  final _hotelStarsCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  // Trip images
  String? _imageUrl;
  String? _imagePublicId;
  List<String> _gallery = [];

  // Hotel images
  String? _hotelMainImage;
  List<String> _hotelGallery = [];

  // Extras
  List<String> _meals = [];
  List<String> _activities = [];
  bool _airportPickup = false;
  List<Map<String, dynamic>> _itinerary = [];
  List<int> _bookedSeatsList = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    final doc = await TripService.getTrip(widget.tripId);
    final trip = TripPackage.fromDoc(doc);

    setState(() {
      _titleCtrl.text = trip.title;
      _descCtrl.text = trip.description;
      _sourceCtrl.text = trip.source;
      _destCtrl.text = trip.destination;
      _priceCtrl.text = trip.price.toString();
      _capacityCtrl.text = trip.capacity.toString();
      _hotelNameCtrl.text = trip.hotelName ?? '';
      _hotelDescCtrl.text = trip.hotelDescription ?? '';
      _hotelStarsCtrl.text = trip.hotelStars?.toString() ?? '';

      _startDate = trip.startDate;
      _endDate = trip.endDate;

      _imageUrl = trip.imageUrl;
      _imagePublicId = trip.imagePublicId;
      _gallery = List.from(trip.gallery);

      _hotelMainImage = trip.hotelMainImage;
      _hotelGallery = List.from(trip.hotelGallery);

      _meals = List.from(trip.meals);
      _activities = List.from(trip.activities);
      _airportPickup = trip.airportPickup;
      _itinerary = List.from(trip.itinerary);

      _bookedSeatsList = List.from(trip.bookedSeatsList);

      _loading = false;
    });
  }

  Future<void> _pickImage({bool isHotel = false, bool isGallery = false, bool isMain = false}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    Map<String, String> upload;
    if (kIsWeb) {
      Uint8List bytes = await picked.readAsBytes();
      upload = await CloudinaryUploader.uploadImage(fileBytes: bytes, fileName: picked.name);
    } else {
      upload = await CloudinaryUploader.uploadImage(filePath: picked.path);
    }

    setState(() {
      final url = upload["secure_url"];
      if (isHotel && isGallery) {
        if (url != null) _hotelGallery.add(url);
      } else if (isHotel && isMain) {
        _hotelMainImage = url;
      } else if (!isHotel && isGallery) {
        if (url != null) _gallery.add(url);
      } else if (!isHotel && isMain) {
        _imageUrl = url;
        _imagePublicId = upload["publicId"];
      }
    });
  }

  Future<void> _updateTrip() async {
    if (!_formKey.currentState!.validate()) return;

    // Update itinerary from controllers
    for (int i = 0; i < _itinerary.length; i++) {
      final day = _itinerary[i];
      final dayCtrl = TextEditingController(text: day['day']?.toString() ?? '');
      final descCtrl = TextEditingController(text: day['plan'] ?? '');
      final mealsCtrl = TextEditingController(text: (day['meals'] as List<dynamic>?)?.join(", ") ?? '');
      final activitiesCtrl = TextEditingController(text: (day['activities'] as List<dynamic>?)?.join(", ") ?? '');

      day['day'] = int.tryParse(dayCtrl.text) ?? (i + 1);
      day['plan'] = descCtrl.text;
      day['meals'] = mealsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      day['activities'] = activitiesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    await TripService.update(
      tripId: widget.tripId,
      title: _titleCtrl.text,
      description: _descCtrl.text,
      source: _sourceCtrl.text,
      destination: _destCtrl.text,
      price: int.tryParse(_priceCtrl.text),
      capacity: int.tryParse(_capacityCtrl.text),
      startDate: _startDate,
      endDate: _endDate,
      imageUrl: _imageUrl,
      imagePublicId: _imagePublicId,
      gallery: _gallery,
      hotelName: _hotelNameCtrl.text.isNotEmpty ? _hotelNameCtrl.text : null,
      hotelDescription: _hotelDescCtrl.text.isNotEmpty ? _hotelDescCtrl.text : null,
      hotelStars: int.tryParse(_hotelStarsCtrl.text),
      hotelMainImage: _hotelMainImage,
      hotelGallery: _hotelGallery,
      meals: _meals,
      activities: _activities,
      airportPickup: _airportPickup,
      itinerary: _itinerary,
      bookedSeatsList: _bookedSeatsList,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip updated successfully")));
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _chipEditor(String label, List<String> items, void Function(List<String>) onChanged) {
    final ctrl = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 6,
          children: items.map((e) => Chip(label: Text(e), onDeleted: () => onChanged(List.from(items)..remove(e)))).toList(),
        ),
        Row(
          children: [
            Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Add item"))),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  onChanged(List.from(items)..add(ctrl.text.trim()));
                  ctrl.clear();
                }
              },
            )
          ],
        ),
      ],
    );
  }

  Widget _itineraryEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Itinerary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ..._itinerary.asMap().entries.map((e) {
          final index = e.key;
          final day = _itinerary[index];

          final dayCtrl = TextEditingController(text: day['day']?.toString() ?? '');
          final descCtrl = TextEditingController(text: day['plan'] ?? '');
          final mealsCtrl = TextEditingController(text: (day['meals'] as List<dynamic>?)?.join(", ") ?? '');
          final activitiesCtrl = TextEditingController(text: (day['activities'] as List<dynamic>?)?.join(", ") ?? '');

          return ItineraryDayField(
            dayCtrl: dayCtrl,
            descCtrl: descCtrl,
            mealsCtrl: mealsCtrl,
            activitiesCtrl: activitiesCtrl,
            onRemove: () => setState(() => _itinerary.removeAt(index)),
          );
        }).toList(),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _itinerary.add({
                'day': _itinerary.length + 1,
                'plan': '',
                'meals': [],
                'activities': [],
              });
            });
          },
          child: const Text("Add Day"),
        ),
      ],
    );
  }

  Widget _imageGalleryEditor(String label, List<String> images, bool isHotel, {bool isMain = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (isMain && images.isNotEmpty)
          GestureDetector(
            onTap: () => _pickImage(isHotel: isHotel, isMain: true),
            child: Image.network(images.first, width: double.infinity, height: 200, fit: BoxFit.cover),
          ),
        Wrap(
          spacing: 6,
          children: images.map((img) => Stack(
            alignment: Alignment.topRight,
            children: [
              Image.network(img, width: 100, height: 100, fit: BoxFit.cover),
              GestureDetector(
                onTap: () => setState(() => images.remove(img)),
                child: const Icon(Icons.close, color: Colors.red),
              )
            ],
          )).toList(),
        ),
        if (!isMain)
          ElevatedButton(
            onPressed: () => _pickImage(isHotel: isHotel, isGallery: true),
            child: const Text("Add Image"),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Trip")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(controller: _titleCtrl, decoration: _inputDecoration("Trip Title"), validator: (v) => v!.isEmpty ? "Enter title" : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descCtrl, decoration: _inputDecoration("Description"), maxLines: 3),
            const SizedBox(height: 12),
            TextFormField(controller: _sourceCtrl, decoration: _inputDecoration("Source City")),
            const SizedBox(height: 12),
            TextFormField(controller: _destCtrl, decoration: _inputDecoration("Destination")),
            const SizedBox(height: 12),
            TextFormField(controller: _priceCtrl, decoration: _inputDecoration("Price"), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextFormField(controller: _capacityCtrl, decoration: _inputDecoration("Capacity"), keyboardType: TextInputType.number),
            const SizedBox(height: 12),

            // Dates
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (picked != null) setState(() => _startDate = picked);
              },
              child: AbsorbPointer(child: TextFormField(controller: TextEditingController(text: _startDate != null ? df.format(_startDate!) : ""), decoration: _inputDecoration("Start Date"))),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _endDate ?? (_startDate ?? DateTime.now()), firstDate: _startDate ?? DateTime.now(), lastDate: DateTime(2100));
                if (picked != null) setState(() => _endDate = picked);
              },
              child: AbsorbPointer(child: TextFormField(controller: TextEditingController(text: _endDate != null ? df.format(_endDate!) : ""), decoration: _inputDecoration("End Date"))),
            ),
            const SizedBox(height: 12),

            // Main Images
            _imageGalleryEditor("Trip Main Image", _imageUrl != null ? [_imageUrl!] : [], false, isMain: true),
            const SizedBox(height: 12),
            _imageGalleryEditor("Trip Gallery", _gallery, false),
            const SizedBox(height: 12),
            _imageGalleryEditor("Hotel Main Image", _hotelMainImage != null ? [_hotelMainImage!] : [], true, isMain: true),
            const SizedBox(height: 12),
            _imageGalleryEditor("Hotel Gallery", _hotelGallery, true),
            const SizedBox(height: 12),

            // Hotel Info
            TextFormField(controller: _hotelNameCtrl, decoration: _inputDecoration("Hotel Name")),
            const SizedBox(height: 12),
            TextFormField(controller: _hotelDescCtrl, decoration: _inputDecoration("Hotel Description"), maxLines: 2),
            const SizedBox(height: 12),
            TextFormField(controller: _hotelStarsCtrl, decoration: _inputDecoration("Hotel Stars"), keyboardType: TextInputType.number),
            const SizedBox(height: 12),

            // Meals & Activities
            _chipEditor("Meals", _meals, (v) => setState(() => _meals = v)),
            const SizedBox(height: 12),
            _chipEditor("Activities", _activities, (v) => setState(() => _activities = v)),
            const SizedBox(height: 12),

            // Airport pickup
            SwitchListTile(value: _airportPickup, onChanged: (v) => setState(() => _airportPickup = v), title: const Text("Airport Pickup")),
            const SizedBox(height: 12),

            // Itinerary
            _itineraryEditor(),
            const SizedBox(height: 20),

            ElevatedButton(onPressed: _updateTrip, child: const Text("Save Changes")),
          ]),
        ),
      ),
    );
  }
}
