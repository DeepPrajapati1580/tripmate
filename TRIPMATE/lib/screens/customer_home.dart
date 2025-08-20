import 'package:flutter/material.dart';
import 'trips/trip_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "TripMate",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal.shade900,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/user.jpg'),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Welcome Back!",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        "Deep",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TripListPage()),
                    ),
                    child: _quickAction(Icons.flight_takeoff, "Plan Trip"),
                  ),
                  _quickAction(Icons.hotel, "Bookings"),
                  _quickAction(Icons.map, "Map"),
                  _quickAction(Icons.account_circle, "Profile"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Upcoming Trips
            _sectionTitle("Upcoming Trips"),
            _tripCard(
              image: "assets/images/paris.jpg",
              title: "Paris Getaway",
              date: "20 Aug - 25 Aug",
              price: "\$1200",
            ),
            _tripCard(
              image: "assets/images/london.jpg",
              title: "London Adventure",
              date: "5 Sep - 12 Sep",
              price: "\$1500",
            ),

            const SizedBox(height: 20),

            // Popular Destinations
            _sectionTitle("Popular Destinations"),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _destinationCard("assets/images/maldives.jpg", "Maldives"),
                  _destinationCard("assets/images/dubai.jpg", "Dubai"),
                  _destinationCard("assets/images/bali.jpg", "Bali"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _quickAction(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  static Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tripCard({
    required String image,
    required String title,
    required String date,
    required String price,
  }) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              image,
              width: 100,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(date, style: const TextStyle(color: Colors.white70)),
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _destinationCard(String image, String name) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      width: 150,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
      child: Container(
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color.fromRGBO(0, 0, 0, 0.6), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
