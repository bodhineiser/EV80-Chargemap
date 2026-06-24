import 'package:flutter/material.dart';
import '../../../core/models/charging_station.dart';
import '../../../core/models/connector.dart';

class StationDetailSheet extends StatelessWidget {
  final ChargingStation station;

  const StationDetailSheet({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                station.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    station.address,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                _badge(station.network, Colors.blue),
                if (station.manufacturer != null)
                  _badge(station.manufacturer!, Colors.green),
                if (station.model != null)
                  _badge(station.model!, Colors.orange),
              ]),
              const SizedBox(height: 16),
              Text(
                'Connectors',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (station.connectors.isEmpty)
                const Text('No connector info available',
                    style: TextStyle(color: Colors.grey))
              else
                ...station.connectors.map((c) => _connectorRow(context, c)),
            ],
          ),
        );
      },
    );
  }

  Widget _connectorRow(BuildContext context, Connector connector) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(connector.type,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          if (connector.powerKw != null)
            Text(
              '${connector.powerKw} kW',
              style: TextStyle(
                color: connector.powerKw! >= 150
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            const Text('? kW', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child:
            Text(label, style: TextStyle(color: color, fontSize: 12)),
      );
}
