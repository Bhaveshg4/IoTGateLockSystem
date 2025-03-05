import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CarParking extends StatefulWidget {
  const CarParking({super.key});

  @override
  State<CarParking> createState() => _CarParkingState();
}

class _CarParkingState extends State<CarParking>
    with SingleTickerProviderStateMixin {
  // Firebase Realtime Database reference
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Parking state
  bool _isParkingOpen = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Firebase listener subscription
  StreamSubscription? _parkingListener;

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

    // Listen to Firebase for real-time updates
    _parkingListener =
        _database.child('carparking/carparkingTrue').onValue.listen(
      (event) {
        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            _isParkingOpen = event.snapshot.value as bool? ?? false;
          });
        }
      },
      onError: (error) {
        print('Firebase listener error: $error');
      },
    );

    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    // Cancel the listener to prevent memory leaks
    _parkingListener?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleParking() {
    // Toggle parking state in Firebase
    _database.child('carparking/carparkingTrue').set(!_isParkingOpen);
  }

  // Responsive helper method
  double _getResponsiveValue(
    BuildContext context, {
    required double smallPhone,
    required double normalPhone,
    required double tablet,
    required double desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return smallPhone;
    if (screenWidth < 600) return normalPhone;
    if (screenWidth < 1024) return tablet;
    return desktop;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Car Parking Control',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: _getResponsiveValue(
              context,
              smallPhone: 16,
              normalPhone: 18,
              tablet: 20,
              desktop: 22,
            ),
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - kToolbarHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    _getResponsiveValue(
                      context,
                      smallPhone: 16,
                      normalPhone: 24,
                      tablet: 32,
                      desktop: 40,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildParkingStatusCard(context),
                      SizedBox(
                        height: _getResponsiveValue(
                          context,
                          smallPhone: 20,
                          normalPhone: 40,
                          tablet: 50,
                          desktop: 60,
                        ),
                      ),
                      _buildParkingControlButton(context),
                      SizedBox(
                        height: _getResponsiveValue(
                          context,
                          smallPhone: 20,
                          normalPhone: 40,
                          tablet: 50,
                          desktop: 60,
                        ),
                      ),
                      _buildParkingInstructions(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParkingStatusCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.9,
      padding: EdgeInsets.all(
        _getResponsiveValue(
          context,
          smallPhone: 12,
          normalPhone: 16,
          tablet: 20,
          desktop: 24,
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isParkingOpen
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (_isParkingOpen ? Colors.green.shade200 : Colors.red.shade200)
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
              _isParkingOpen ? Icons.garage_outlined : Icons.garage,
              color: Colors.white,
              size: _getResponsiveValue(
                context,
                smallPhone: 24,
                normalPhone: 28,
                tablet: 32,
                desktop: 36,
              ),
            ),
          ),
          SizedBox(
            width: _getResponsiveValue(
              context,
              smallPhone: 8,
              normalPhone: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isParkingOpen ? 'Parking Open' : 'Parking Closed',
                  style: GoogleFonts.poppins(
                    fontSize: _getResponsiveValue(
                      context,
                      smallPhone: 14,
                      normalPhone: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isParkingOpen
                      ? 'The parking gate is currently open'
                      : 'The parking gate is currently closed',
                  style: GoogleFonts.poppins(
                    fontSize: _getResponsiveValue(
                      context,
                      smallPhone: 12,
                      normalPhone: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .shimmer(duration: const Duration(seconds: 3))
        .shake(delay: const Duration(seconds: 3));
  }

  Widget _buildParkingControlButton(BuildContext context) {
    return GestureDetector(
      onTap: _toggleParking,
      child: Container(
        width: _getResponsiveValue(
          context,
          smallPhone: 200,
          normalPhone: 250,
          tablet: 300,
          desktop: 350,
        ),
        height: _getResponsiveValue(
          context,
          smallPhone: 200,
          normalPhone: 250,
          tablet: 300,
          desktop: 350,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: _isParkingOpen
                ? [
                    Colors.green.shade300,
                    Colors.green.shade600,
                  ]
                : [
                    Colors.red.shade300,
                    Colors.red.shade600,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (_isParkingOpen ? Colors.green.shade200 : Colors.red.shade200)
                      .withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isParkingOpen
                    ? Icons.door_back_door_outlined
                    : Icons.door_back_door,
                size: _getResponsiveValue(
                  context,
                  smallPhone: 70,
                  normalPhone: 100,
                  tablet: 120,
                  desktop: 140,
                ),
                color: Colors.white,
              ),
              SizedBox(
                height: _getResponsiveValue(
                  context,
                  smallPhone: 8,
                  normalPhone: 16,
                  tablet: 20,
                  desktop: 24,
                ),
              ),
              Text(
                _isParkingOpen ? 'CLOSE' : 'OPEN',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveValue(
                    context,
                    smallPhone: 18,
                    normalPhone: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .shimmer(duration: const Duration(seconds: 3)),
    );
  }

  Widget _buildParkingInstructions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.9,
      padding: EdgeInsets.all(
        _getResponsiveValue(
          context,
          smallPhone: 12,
          normalPhone: 16,
          tablet: 20,
          desktop: 24,
        ),
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Use',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveValue(
                context,
                smallPhone: 16,
                normalPhone: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(
            height: _getResponsiveValue(
              context,
              smallPhone: 8,
              normalPhone: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          _buildInstructionItem(
            'Tap the large button to toggle parking gate',
            Icons.touch_app_outlined,
            context,
          ),
          _buildInstructionItem(
            'Green indicates open, Red indicates closed',
            Icons.info_outline,
            context,
          ),
          _buildInstructionItem(
            'Real-time status updates from the system',
            Icons.sync_outlined,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(
      String text, IconData icon, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue.shade700,
            size: _getResponsiveValue(
              context,
              smallPhone: 16,
              normalPhone: 18,
              tablet: 20,
              desktop: 22,
            ),
          ),
          SizedBox(
            width: _getResponsiveValue(
              context,
              smallPhone: 8,
              normalPhone: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveValue(
                  context,
                  smallPhone: 12,
                  normalPhone: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
