import 'package:flutter/material.dart';
import '../services/location_service.dart';

/// Widget مخصص لحقل الموقع مع إمكانية جلب الموقع الحالي
class LocationField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final bool isRequired;
  final String? Function(String?)? validator;
  final void Function(String)? onLocationChanged;
  final bool enabled;

  const LocationField({
    super.key,
    required this.controller,
    this.labelText = 'الموقع',
    this.hintText = 'اختر أو أدخل الموقع',
    this.isRequired = false,
    this.validator,
    this.onLocationChanged,
    this.enabled = true,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  bool _isLoadingLocation = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: widget.isRequired 
                ? '${widget.labelText} *' 
                : widget.labelText,
            hintText: widget.hintText,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: widget.enabled ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر الموقع الحالي
                IconButton(
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: Colors.blue),
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  tooltip: 'الحصول على الموقع الحالي',
                ),
                // زر اختيار الموقع
                IconButton(
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  onPressed: _showLocationPicker,
                  tooltip: 'اختيار الموقع',
                ),
              ],
            ) : null,
          ),
          validator: widget.validator ?? (widget.isRequired ? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال ${widget.labelText}';
            }
            return null;
          } : null),
          onChanged: (value) {
            if (widget.onLocationChanged != null) {
              widget.onLocationChanged!(value);
            }
          },
        ),
        
        // نصائح للمستخدم
        if (widget.enabled) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'يمكنك الحصول على موقعك الحالي أو اختيار من القائمة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// الحصول على الموقع الحالي
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationService = LocationService();
      final result = await locationService.getCurrentLocationWithAddress();
      
      if (result != null && mounted) {
        widget.controller.text = result.address;
        if (widget.onLocationChanged != null) {
          widget.onLocationChanged!(result.address);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم الحصول على الموقع: ${result.address}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        _showLocationError('لم يتم العثور على الموقع');
      }
    } catch (e) {
      if (mounted) {
        _showLocationError('خطأ في الحصول على الموقع: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// عرض حوار اختيار الموقع
  Future<void> _showLocationPicker() async {
    final selectedLocation = await LocationService.showLocationPicker(
      context,
      currentLocation: widget.controller.text.isNotEmpty 
          ? widget.controller.text 
          : null,
    );
    
    if (selectedLocation != null && mounted) {
      widget.controller.text = selectedLocation;
      if (widget.onLocationChanged != null) {
        widget.onLocationChanged!(selectedLocation);
      }
    }
  }

  /// عرض رسالة خطأ
  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'الإعدادات',
          textColor: Colors.white,
          onPressed: () {
            _showLocationPermissionDialog();
          },
        ),
      ),
    );
  }

  /// عرض حوار صلاحيات الموقع
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('صلاحيات الموقع'),
        content: const Text(
          'للحصول على موقعك الحالي، يحتاج التطبيق إلى:\n\n'
          '• تفعيل خدمات الموقع في الجهاز\n'
          '• السماح للتطبيق بالوصول للموقع\n\n'
          'يمكنك تفعيل هذه الصلاحيات من إعدادات الجهاز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}

/// Widget مبسط لعرض الموقع فقط
class LocationDisplayField extends StatelessWidget {
  final String? location;
  final String? labelText;
  final VoidCallback? onTap;

  const LocationDisplayField({
    super.key,
    this.location,
    this.labelText = 'الموقع',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location ?? 'غير محدد',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.edit, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// Widget لعرض الموقع مع خريطة صغيرة (اختياري)
class LocationCard extends StatelessWidget {
  final String? location;
  final String? description;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const LocationCard({
    super.key,
    this.location,
    this.description,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location ?? 'غير محدد',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
