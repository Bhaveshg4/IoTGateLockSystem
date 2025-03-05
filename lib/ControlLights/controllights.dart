import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class ControlLights extends StatefulWidget {
  const ControlLights({super.key});

  @override
  State<ControlLights> createState() => _ControlLightsState();
}

class _ControlLightsState extends State<ControlLights>
    with SingleTickerProviderStateMixin {
  // Firebase Realtime Database reference
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // State for each room's light
  Map<String, bool> roomLights = {
    'Room One': false,
    'Room Two': false,
    'Room Three': false,
    'Room Four': false,
  };

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // List to store database listeners
  List<StreamSubscription> _listeners = [];

  // Method to toggle light status
  void _toggleLight(String room) {
    setState(() {
      roomLights[room] = !roomLights[room]!;
      // Update Firebase Realtime Database
      _database.child('LightsControl/$room').set(roomLights[room]);
    });
  }

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Listen to Firebase for real-time updates
    roomLights.keys.forEach((room) {
      var listener = _database.child('LightsControl/$room').onValue.listen(
        (event) {
          // Check if the widget is still mounted before calling setState
          if (mounted) {
            setState(() {
              roomLights[room] = event.snapshot.value as bool? ?? false;
            });
          }
        },
        onError: (error) {
          print('Firebase listener error for $room: $error');
        },
      );
      _listeners.add(listener);
    });

    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    // Cancel all listeners to prevent memory leaks
    _listeners.forEach((listener) => listener.cancel());
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Smart Home Lights',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.blue.shade700),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade100,
              Colors.white,
              Colors.purple.shade100,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Room Lights'),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: roomLights.length,
                        itemBuilder: (context, index) {
                          String room = roomLights.keys.elementAt(index);
                          bool isLightOn = roomLights[room]!;

                          return _buildLightControlCard(room, isLightOn);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSystemStatusCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightControlCard(String room, bool isLightOn) {
    return GestureDetector(
      onTap: () => _toggleLight(room),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Light icon with animated scale
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              transform: Matrix4.identity()..scale(isLightOn ? 1.1 : 1.0),
              child: Icon(
                isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
                size: 80,
                color: isLightOn
                    ? Colors.yellow.shade700 // Bright yellow when on
                    : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            // Room name
            Text(
              room,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Status text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isLightOn ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isLightOn ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Text(
                isLightOn ? 'ON' : 'OFF',
                style: GoogleFonts.poppins(
                  color:
                      isLightOn ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    // Count of lights on
    int lightsOn = roomLights.values.where((state) => state).length;
    bool allLightsOff = lightsOn == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: allLightsOff
              ? [Colors.blue.shade400, Colors.blue.shade600]
              : [Colors.yellow.shade400, Colors.yellow.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (allLightsOff ? Colors.blue.shade200 : Colors.yellow.shade200)
                    .withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              allLightsOff ? Icons.power_off : Icons.light_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allLightsOff ? 'All Lights Off' : 'Lights Active',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  allLightsOff
                      ? 'No rooms are currently lit'
                      : '$lightsOn room(s) currently lit',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
