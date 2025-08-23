import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  late TextEditingController _title;
  late TextEditingController _desc;
  late TextEditingController _dest;
  late TextEditingController _price;
  late TextEditingController _capacity;
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existingData["title"]);
    _desc = TextEditingController(text: widget.existingData["description"]);
    _dest = TextEditingController(text: widget.existingData["destination"]);
    _price = TextEditingController(text: widget.existingData["price"].toString());
    _capacity = TextEditingController(text: widget.existingData["capacity"].toString());

    final start = widget.existingData["startDate"];
    final end = widget.existingData["endDate"];
    if (start != null) _start = (start as Timestamp).toDate();
    if (end != null) _end = (end as Timestamp).toDate();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
      initialDate: isStart ? (_start ?? now) : (_end ?? now),
    );
    if (picked != null) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select dates")));
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection("trip_packages")
          .doc(widget.tripId)
          .update({
        "title": _title.text,
        "description": _desc.text,
        "destination": _dest.text,
        "startDate": _start,
        "endDate": _end,
        "price": int.parse(_price.text),
        "capacity": int.parse(_capacity.text),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Trip Package")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dest,
                decoration: const InputDecoration(labelText: 'Destination'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(true),
                      child: Text(
                        _start == null ? 'Start date' : df.format(_start!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(false),
                      child: Text(_end == null ? 'End date' : df.format(_end!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                decoration:
                    const InputDecoration(labelText: 'Price per seat (INR)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Enter amount',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacity,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Enter capacity',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Update"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
