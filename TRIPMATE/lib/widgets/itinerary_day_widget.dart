import 'package:flutter/material.dart';

class ItineraryDayField extends StatelessWidget {
  final TextEditingController dayCtrl;
  final TextEditingController mealsCtrl;
  final TextEditingController activitiesCtrl;
  final VoidCallback onRemove;

  const ItineraryDayField({
    super.key,
    required this.dayCtrl,
    required this.mealsCtrl,
    required this.activitiesCtrl,
    required this.onRemove,
  });

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
                    controller: dayCtrl,
                    decoration: _inputDecoration("Day"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: mealsCtrl,
              decoration: _inputDecoration("Meals (comma separated)"),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: activitiesCtrl,
              decoration: _inputDecoration("Activities (comma separated)"),
            ),
          ],
        ),
      ),
    );
  }
}
