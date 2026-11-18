
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorDemoPage extends StatefulWidget {
  const SensorDemoPage({super.key});

  @override
  State<SensorDemoPage> createState() => _SensorDemoPageState();
}

class _SensorDemoPageState extends State<SensorDemoPage> {
  StreamSubscription<UserAccelerometerEvent>? _subscription;

  double _x = 0;
  double _y = 0;
  double _z = 0;
  double _peak = 0;

  bool _isRunning = false;
  String _status = 'Menunggu sensor';
  String _description = 'Tekan mulai untuk membaca gerakan perangkat.';

  double get _magnitude => math.sqrt(_x * _x + _y * _y + _z * _z);

  Color get _statusColor {
    if (!_isRunning) return Colors.grey;
    if (_magnitude < 0.8) return Colors.green;
    if (_magnitude < 2.5) return Colors.orange;
    return Colors.red;
  }

  String get _movementStatus {
    if (!_isRunning) return 'Dijeda';
    if (_magnitude < 0.8) return 'Perangkat Diam';
    if (_magnitude < 2.5) return 'Bergerak';
    return 'Gerakan Kuat';
  }

  String get _movementDescription {
    if (!_isRunning) return 'Pembacaan sensor sedang dihentikan.';
    if (_magnitude < 0.8) return 'Perangkat relatif stabil.';
    if (_magnitude < 2.5) return 'Perangkat sedang mengalami gerakan.';
    return 'Perangkat mengalami gerakan yang cukup kuat!';
  }

  @override
  void initState() {
    super.initState();
    _startSensor();
  }

  void _startSensor() {
    _subscription?.cancel();

    setState(() {
      _isRunning = true;
      _status = 'Sensor aktif';
      _description = 'Gerakkan perangkat untuk melihat perubahan.';
    });

    _subscription = userAccelerometerEventStream().listen(
      (event) {
        if (!mounted) return;

        setState(() {
          _x = event.x;
          _y = event.y;
          _z = event.z;

          if (_magnitude > _peak) {
            _peak = _magnitude;
          }
        });
      },
      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          _isRunning = false;
          _status = 'Sensor tidak tersedia';
          _description = error.toString();
        });
      },
      cancelOnError: true,
    );
  }

  void _pauseSensor() {
    _subscription?.cancel();
    _subscription = null;

    setState(() {
      _isRunning = false;
      _status = 'Sensor dijeda';
      _description = 'Tekan mulai untuk melanjutkan pembacaan.';
    });
  }

  void _resetSensor() {
    setState(() {
      _x = 0;
      _y = 0;
      _z = 0;
      _peak = 0;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Widget _buildAxisCard(String axis, double value, Color color) {
    final progress = (value.abs() / 10).clamp(0.0, 1.0);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sumbu $axis',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'm/s²',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accelerometer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sensor Dashboard',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pantau pergerakan perangkat secara real-time.',
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

              // Status gerakan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _statusColor.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.vibration,
                        color: _statusColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _movementStatus,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _statusColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _movementDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '$_status',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Pembacaan Sumbu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _buildAxisCard('X', _x, Colors.red),
                  const SizedBox(width: 10),
                  _buildAxisCard('Y', _y, Colors.green),
                  const SizedBox(width: 10),
                  _buildAxisCard('Z', _z, Colors.blue),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Informasi Gerakan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _buildInfoCard(
                    'Total Percepatan',
                    '${_magnitude.toStringAsFixed(2)} m/s²',
                    Icons.speed,
                  ),
                  const SizedBox(width: 10),
                  _buildInfoCard(
                    'Gerakan Puncak',
                    '${_peak.toStringAsFixed(2)} m/s²',
                    Icons.trending_up,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Kontrol sensor
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isRunning ? _pauseSensor : _startSensor,
                      icon: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(_isRunning ? 'Jeda Sensor' : 'Mulai Sensor'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _resetSensor,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gerakkan HP secara perlahan untuk mengamati '
                        'perubahan nilai sumbu X, Y, dan Z. '
                        'Nilai sensor menggunakan satuan m/s².',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
