import 'package:flutter/material.dart';
import '../../../../core/models/charging_station.dart';

class StationMarker extends StatelessWidget {
  final ChargingStation station;
  final VoidCallback onTap;

  const StationMarker({
    super.key,
    required this.station,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4)
          ],
        ),
        child: const Icon(Icons.bolt, color: Colors.white, size: 14),
      ),
    );
  }
}
