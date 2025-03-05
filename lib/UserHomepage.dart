import 'package:door_lock_1/Carparking/carparking.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import 'package:door_lock_1/ControlLights/controllights.dart';
import 'package:door_lock_1/Verification.dart';
import 'package:door_lock_1/sensorData/sensordataPage.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  State<UserHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<UserHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to determine screen size and orientation
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final orientation = mediaQuery.orientation;

    // Responsive sizing and spacing
    double getResponsiveValue({
      required double smallPhone,
      required double normalPhone,
      required double tablet,
    }) {
      if (screenWidth < 360) return smallPhone;
      if (screenWidth < 600) return normalPhone;
      return tablet;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade900,
                Colors.purple.shade900,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background elements
              ..._buildBackgroundElements(),

              // Main content
              SafeArea(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Determine the maximum width for the content
                      final maxWidth = orientation == Orientation.portrait
                          ? constraints.maxWidth
                          : constraints.maxWidth * 0.8;

                      return SingleChildScrollView(
                        child: SizedBox(
                          width: maxWidth,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: getResponsiveValue(
                                smallPhone: 16,
                                normalPhone: 24,
                                tablet: screenWidth * 0.1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: screenHeight * 0.05),
                                _buildHeader(screenWidth),
                                SizedBox(height: screenHeight * 0.05),
                                _buildOptions(screenWidth, context),
                                SizedBox(height: screenHeight * 0.05),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundElements() {
    return [
      // Floating circles
      Positioned(
        top: -100,
        right: -100,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.2,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: -150,
        left: -150,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.2,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            );
          },
        ),
      ),
      // Glass effect overlay
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
    ];
  }

  Widget _buildHeader(double screenWidth) {
    // Responsive font sizing
    double getTitleFontSize() {
      if (screenWidth < 360) return 28;
      if (screenWidth < 600) return 32;
      return 40;
    }

    double getSubtitleFontSize() {
      if (screenWidth < 360) return 14;
      if (screenWidth < 600) return 16;
      return 18;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.white, Colors.white70],
              ).createShader(bounds),
              child: Text(
                'User Home',
                style: TextStyle(
                  fontSize: getTitleFontSize(),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            SizedBox(height: screenWidth < 600 ? 16 : 20),
            Text(
              'Choose an option to proceed',
              style: TextStyle(
                fontSize: getSubtitleFontSize(),
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(double screenWidth, BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _OptionCard(
                icon: Icons.lock_open_rounded,
                title: 'Control lights',
                subtitle: 'Control lights from anywhere in the world',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ControlLights()));
                },
                screenWidth: screenWidth,
              ),
              SizedBox(height: screenWidth < 600 ? 24 : 32),
              _OptionCard(
                icon: Icons.lock_open_rounded,
                title: 'Unlock Door',
                subtitle: 'Access the door with unique code',
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => VerificationScreen()));
                },
                screenWidth: screenWidth,
              ),
              SizedBox(height: screenWidth < 600 ? 24 : 32),
              _OptionCard(
                icon: Icons.lock_open_rounded,
                title: 'Access Car parking',
                subtitle: 'Access the parking with a click',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => CarParking()));
                },
                screenWidth: screenWidth,
              ),
              SizedBox(height: screenWidth < 600 ? 24 : 32),
              _OptionCard(
                icon: Icons.sensors_rounded,
                title: 'Sensor Data',
                subtitle: 'View real-time sensor data',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SensorData()));
                },
                screenWidth: screenWidth,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double screenWidth;

  const _OptionCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    double getIconSize() {
      if (screenWidth < 360) return 32;
      if (screenWidth < 600) return 40;
      return 48;
    }

    double getTitleFontSize() {
      if (screenWidth < 360) return 18;
      if (screenWidth < 600) return 20;
      return 24;
    }

    double getSubtitleFontSize() {
      if (screenWidth < 360) return 12;
      if (screenWidth < 600) return 14;
      return 16;
    }

    double getPadding() {
      if (screenWidth < 360) return 16;
      if (screenWidth < 600) return 20;
      return 24;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(getPadding()),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: getIconSize(),
                    color: Colors.white,
                  ),
                  SizedBox(width: getPadding()),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: getTitleFontSize(),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: getSubtitleFontSize(),
                            color: Colors.white70,
                          ),
                        ),
                      ],
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
