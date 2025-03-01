import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:math' as math;

class SensorData extends StatefulWidget {
  const SensorData({super.key});

  @override
  State<SensorData> createState() => _SensorDataState();
}

class _SensorDataState extends State<SensorData>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Sensor data values
  double _temperature = 0.0;
  int _humidity = 0;
  int _distance = 0;
  bool _objectDetected = false;
  bool _gasDetected = false;
  int _gasValue = 0;

  // For real-time updates
  late StreamSubscription<DatabaseEvent> _sensorDataSubscription;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime _lastUpdated = DateTime.now();

  // Animation values for interactive elements
  double _waveOffset = 0.0;
  Timer? _waveAnimationTimer;

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

    // Start fetching sensor data
    _fetchSensorData();

    // Start animations
    _animationController.forward();

    // Setup wave animation
    _waveAnimationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _waveOffset += 0.05;
        if (_waveOffset > 2 * math.pi) {
          _waveOffset = 0.0;
        }
      });
    });
  }

  void _fetchSensorData() {
    try {
      final databaseRef = FirebaseDatabase.instance.ref().child('sensorData');

      // Listen to sensor data changes
      _sensorDataSubscription = databaseRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          setState(() {
            _temperature = double.parse(data['temperature'].toString());
            _humidity = int.parse(data['humidity'].toString());
            _distance = int.parse(data['distance'].toString());
            _objectDetected = data['objectDetected'] ?? false;
            _gasDetected = data['gasDetected'] ?? false;
            _gasValue = int.parse(data['gasValue'].toString());
            _isLoading = false;
            _hasError = false;
            _lastUpdated = DateTime.now();
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'No sensor data available';
          });
        }
      }, onError: (error) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load sensor data: ${error.toString()}';
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _sensorDataSubscription.cancel();
    _animationController.dispose();
    _waveAnimationTimer?.cancel();
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
          'Sensor Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.blue.shade700),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue.shade700),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchSensorData();
            },
          ),
        ],
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
          child: _isLoading
              ? _buildLoadingIndicator()
              : _hasError
                  ? _buildErrorWidget()
                  : _buildDashboard(),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading sensor data...',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 70,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _fetchSensorData();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Try Again',
                style: GoogleFonts.poppins(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSectionTitle('Environmental Sensors'),
              const SizedBox(height: 16),
              _buildCircularIndicators(),
              const SizedBox(height: 24),
              _buildSectionTitle('Safety Sensors'),
              const SizedBox(height: 16),
              _buildSafetyCards(),
              const SizedBox(height: 24),
              _buildStatusSummary(),
              const SizedBox(height: 16),
              _buildLastUpdatedCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    bool isAnyAlert = _temperature > 35 ||
        _humidity > 80 ||
        _gasDetected ||
        (_objectDetected && _distance < 10);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAnyAlert ? Colors.red.shade100 : Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAnyAlert ? Icons.device_thermostat : Icons.domain_verification,
              color: isAnyAlert ? Colors.red.shade700 : Colors.blue.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnyAlert ? 'System Alert' : 'System Status',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  isAnyAlert
                      ? 'Attention required for your system'
                      : 'All systems operating normally',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isAnyAlert ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAnyAlert ? Colors.red.shade200 : Colors.green.shade200,
              ),
            ),
            child: Text(
              isAnyAlert ? 'ALERT' : 'NORMAL',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isAnyAlert ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIndicators() {
    // Calculate percentages for indicators
    double tempPercent =
        (_temperature / 50).clamp(0.0, 1.0); // Assuming max temp is 50°C
    double humidityPercent = (_humidity / 100).clamp(0.0, 1.0);

    Color tempColor = _getTemperatureColor(_temperature);
    Color humidityColor = _getHumidityColor(_humidity);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Temperature indicator
          Column(
            children: [
              CircularPercentIndicator(
                radius: 70,
                lineWidth: 13.0,
                animation: true,
                animationDuration: 1500,
                percent: tempPercent,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.thermostat_outlined,
                      color: tempColor,
                      size: 22,
                    ),
                    Text(
                      '${_temperature.toStringAsFixed(1)}°C',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: tempColor,
                backgroundColor: tempColor.withOpacity(0.2),
                footer: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Temperature',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildTemperatureStatusText(),
            ],
          ),

          // Humidity indicator
          Column(
            children: [
              CircularPercentIndicator(
                radius: 70,
                lineWidth: 13.0,
                animation: true,
                animationDuration: 1500,
                percent: humidityPercent,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      color: humidityColor,
                      size: 22,
                    ),
                    Text(
                      '$_humidity%',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: humidityColor,
                backgroundColor: humidityColor.withOpacity(0.2),
                footer: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Humidity',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildHumidityStatusText(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureStatusText() {
    String status;
    Color color;

    if (_temperature < 10) {
      status = 'Cold';
      color = Colors.blue.shade700;
    } else if (_temperature < 20) {
      status = 'Cool';
      color = Colors.blue.shade400;
    } else if (_temperature < 30) {
      status = 'Normal';
      color = Colors.green.shade600;
    } else if (_temperature < 35) {
      status = 'Warm';
      color = Colors.orange.shade600;
    } else {
      status = 'Hot!';
      color = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHumidityStatusText() {
    String status;
    Color color;

    if (_humidity < 30) {
      status = 'Dry';
      color = Colors.orange.shade700;
    } else if (_humidity < 60) {
      status = 'Normal';
      color = Colors.green.shade600;
    } else if (_humidity < 80) {
      status = 'Humid';
      color = Colors.blue.shade600;
    } else {
      status = 'Very Humid!';
      color = Colors.blue.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 10) return Colors.blue.shade700;
    if (temp < 20) return Colors.blue.shade400;
    if (temp < 30) return Colors.green.shade600;
    if (temp < 35) return Colors.orange.shade600;
    return Colors.red.shade700;
  }

  Color _getHumidityColor(int humidity) {
    if (humidity < 30) return Colors.orange.shade700;
    if (humidity < 60) return Colors.green.shade600;
    if (humidity < 80) return Colors.blue.shade600;
    return Colors.blue.shade800;
  }

  Widget _buildSafetyCards() {
    return Row(
      children: [
        Expanded(
          child: _buildAnimatedSafetyCard(
            title: 'Gas',
            value: '$_gasValue',
            subtitle: _gasDetected ? 'Gas Detected!' : 'Normal',
            icon: Icons.cloud_outlined,
            isAlert: _gasDetected,
            alertColor: Colors.red.shade700,
            normalColor: Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnimatedSafetyCard(
            title: 'Distance',
            value: '$_distance cm',
            subtitle: _objectDetected ? 'Object Detected' : 'Clear',
            icon: Icons.sensors_outlined,
            isAlert: _objectDetected && _distance < 10,
            alertColor: Colors.amber.shade700,
            normalColor: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedSafetyCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required bool isAlert,
    required Color alertColor,
    required Color normalColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAlert
            ? alertColor.withOpacity(0.1)
            : normalColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: isAlert
            ? Border.all(color: alertColor.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAlert
                      ? alertColor.withOpacity(0.2)
                      : normalColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isAlert ? alertColor : normalColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isAlert ? alertColor : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isAlert ? alertColor : normalColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isAlert ? alertColor : normalColor).withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isAlert ? alertColor : normalColor,
                  fontWeight: isAlert ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (isAlert) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: alertColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Alert',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: alertColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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

  Widget _buildStatusSummary() {
    final bool anyAlert = _temperature > 35 ||
        _humidity > 80 ||
        _gasDetected ||
        (_objectDetected && _distance < 10);

    List<Widget> alertItems = [];

    if (_temperature > 35) {
      alertItems.add(_buildAlertItem('High Temperature: $_temperature°C'));
    }

    if (_humidity > 80) {
      alertItems.add(_buildAlertItem('High Humidity: $_humidity%'));
    }

    if (_gasDetected) {
      alertItems.add(_buildAlertItem('Gas Detected: $_gasValue'));
    }

    if (_objectDetected && _distance < 10) {
      alertItems.add(_buildAlertItem('Object Too Close: $_distance cm'));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: anyAlert
              ? [Colors.red.shade400, Colors.red.shade600]
              : [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: anyAlert
                ? Colors.red.shade200.withOpacity(0.5)
                : Colors.green.shade200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  anyAlert
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
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
                      anyAlert ? 'System Alerts' : 'All Systems Normal',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      anyAlert
                          ? 'Action required! Check alerts below.'
                          : 'All sensors are reporting within normal range.',
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
          if (alertItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            ...alertItems,
          ],
        ],
      ),
    );
  }

  Widget _buildAlertItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedCard() {
    String formattedTime =
        '${_lastUpdated.hour.toString().padLeft(2, '0')}:${_lastUpdated.minute.toString().padLeft(2, '0')}:${_lastUpdated.second.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                formattedTime,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Live',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
