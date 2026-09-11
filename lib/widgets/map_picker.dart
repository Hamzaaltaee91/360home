import 'package:flutter/material.dart';

import '../services/location_service.dart';

/// An interactive location selector.
///
/// Presents a tappable map surface where the user can pick a coordinate by
/// tapping, drag the marker to fine-tune the selection, or use the device's
/// current location. The selected [LatLng] is reported through [onChanged].
class MapPicker extends StatefulWidget {
  const MapPicker({
    super.key,
    this.initialLocation,
    this.onChanged,
    this.height = 260,
    this.locationService,
  });

  /// The initially selected coordinate, if any.
  final LatLng? initialLocation;

  /// Called whenever the selected coordinate changes.
  final ValueChanged<LatLng>? onChanged;

  /// Height of the map surface.
  final double height;

  /// Injectable location service (useful for testing).
  final LocationService? locationService;

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  late final LocationService _locationService =
      widget.locationService ?? LocationService();

  LatLng? _selected;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation;
  }

  void _select(LatLng value) {
    setState(() {
      _selected = value;
      _error = null;
    });
    widget.onChanged?.call(value);
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final position = await _locationService.getCurrentLocation();
      _select(LatLng(position.latitude, position.longitude));
    } catch (_) {
      setState(() => _error = 'Unable to determine current location.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _select(_fromOffset(details.localPosition, size)),
                  child: Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: CustomPaint(
                      painter: _MapGridPainter(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      child: _selected == null
                          ? Center(
                              child: Text(
                                'Tap to select a location',
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                          : _MarkerOverlay(
                              location: _selected!,
                              onDrag: (offset) => _select(
                                _fromOffset(offset, size),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _selected == null
                    ? 'No location selected'
                    : '${_selected!.latitude.toStringAsFixed(5)}, '
                        '${_selected!.longitude.toStringAsFixed(5)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: const Text('Use current'),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }

  /// Maps a local pixel offset within a [size] box to a coordinate.
  ///
  /// The mapping is a simple linear projection around the equator so that the
  /// widget remains dependency-free while still producing stable, testable
  /// coordinates.
  LatLng _fromOffset(Offset offset, Size size) {
    final x = (offset.dx / size.width).clamp(0.0, 1.0);
    final y = (offset.dy / size.height).clamp(0.0, 1.0);
    final longitude = (x * 360.0) - 180.0;
    final latitude = 90.0 - (y * 180.0);
    return LatLng(latitude, longitude);
  }
}

class _MarkerOverlay extends StatelessWidget {
  const _MarkerOverlay({required this.location, required this.onDrag});

  final LatLng location;
  final void Function(Offset offset) onDrag;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final x = ((location.longitude + 180.0) / 360.0) * size.width;
        final y = ((90.0 - location.latitude) / 180.0) * size.height;
        return Stack(
          children: [
            Positioned(
              left: x - 18,
              top: y - 36,
              child: GestureDetector(
                onPanUpdate: (details) {
                  onDrag(
                    Offset(
                      (x + details.delta.dx).clamp(0.0, size.width),
                      (y + details.delta.dy).clamp(0.0, size.height),
                    ),
                  );
                },
                child: Icon(
                  Icons.location_on,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const divisions = 6;
    for (var i = 1; i < divisions; i++) {
      final dx = size.width * i / divisions;
      final dy = size.height * i / divisions;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) => oldDelegate.color != color;
}

/// A simple latitude/longitude value object.
class LatLng {
  const LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is LatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}
