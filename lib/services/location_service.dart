import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

/// خدمة الموقع الجغرافي
/// تتعامل مع جلب الموقع الحالي وتحويل الإحداثيات إلى عناوين
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// قائمة المحافظات اليمنية
  static const List<String> yemeniGovernorates = [
    'صنعاء',
    'عدن',
    'تعز',
    'الحديدة',
    'إب',
    'ذمار',
    'صعدة',
    'حجة',
    'لحج',
    'أبين',
    'شبوة',
    'المهرة',
    'حضرموت',
    'الجوف',
    'مأرب',
    'البيضاء',
    'الضالع',
    'ريمة',
    'عمران',
    'المحويت',
    'الأمانة', // أمانة العاصمة
    'سقطرى',
  ];

  /// فحص صلاحيات الموقع
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// طلب صلاحيات الموقع
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// فحص إذا كانت خدمات الموقع مفعلة
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// الحصول على الموقع الحالي
  Future<Position?> getCurrentPosition() async {
    try {
      // فحص إذا كانت خدمات الموقع مفعلة
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('خدمات الموقع غير مفعلة');
      }

      // فحص الصلاحيات
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('تم رفض صلاحيات الموقع');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('تم رفض صلاحيات الموقع نهائياً');
      }

      // الحصول على الموقع
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _logger.e('خطأ في الحصول على الموقع: $e');
      print('خطأ في الحصول على الموقع: $e');
      return null;
    }
  }

  /// تحويل الإحداثيات إلى عنوان
  Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // محاولة العثور على محافظة يمنية
        String? yemeniLocation = _findYemeniGovernorate(place);
        if (yemeniLocation != null) {
          return yemeniLocation;
        }

        // إذا لم نجد محافظة يمنية، نعيد أفضل عنوان متاح
        return place.administrativeArea ??
            place.locality ??
            place.subAdministrativeArea ??
            place.country ??
            'موقع غير محدد';
      }
      return null;
    } catch (e) {
      print('خطأ في تحويل الإحداثيات إلى عنوان: $e');
      return null;
    }
  }

  /// البحث عن محافظة يمنية في بيانات الموقع
  String? _findYemeniGovernorate(Placemark place) {
    List<String> locationParts = [
      place.administrativeArea ?? '',
      place.locality ?? '',
      place.subAdministrativeArea ?? '',
      place.subLocality ?? '',
      place.thoroughfare ?? '',
    ];

    for (String governorate in yemeniGovernorates) {
      for (String part in locationParts) {
        if (part.contains(governorate) || governorate.contains(part)) {
          return governorate;
        }
      }
    }

    return null;
  }

  /// الحصول على الموقع الحالي مع العنوان
  Future<LocationResult?> getCurrentLocationWithAddress() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) return null;

      String? address = await getAddressFromCoordinates(
          position.latitude, position.longitude);

      if (address == null) return null;

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      _logger.e('خطأ في الحصول على الموقع مع العنوان: $e');
      print('خطأ في الحصول على الموقع مع العنوان: $e');
      return null;
    }
  }

  /// عرض حوار اختيار الموقع
  static Future<String?> showLocationPicker(BuildContext context,
      {String? currentLocation}) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return LocationPickerDialog(currentLocation: currentLocation);
      },
    );
  }
}

/// نتيجة الموقع
class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  String toString() {
    return 'LocationResult(lat: $latitude, lng: $longitude, address: $address)';
  }
}

/// حوار اختيار الموقع
class LocationPickerDialog extends StatefulWidget {
  final String? currentLocation;

  const LocationPickerDialog({super.key, this.currentLocation});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final LocationService _locationService = LocationService();
  final TextEditingController _customLocationController =
      TextEditingController();
  String? _selectedLocation;
  bool _isLoadingCurrentLocation = false;
  String? _currentLocationResult;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
    _customLocationController.text = widget.currentLocation ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.8; // 80% من ارتفاع الشاشة

    return AlertDialog(
      title: const Text('اختيار الموقع'),
      content: SizedBox(
        width: double.maxFinite,
        height: maxDialogHeight,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // زر الموقع الحالي
              Card(
                child: ListTile(
                  leading: _isLoadingCurrentLocation
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: Colors.blue),
                  title: const Text('استخدام الموقع الحالي'),
                  subtitle: _currentLocationResult != null
                      ? Text(_currentLocationResult!)
                      : const Text('اضغط للحصول على موقعك الحالي'),
                  onTap: _isLoadingCurrentLocation ? null : _getCurrentLocation,
                ),
              ),

              const SizedBox(height: 12),

              // قائمة المحافظات
              const Text('أو اختر من المحافظات:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // قائمة المحافظات مع ارتفاع مرن
              Container(
                height: math.min(200,
                    maxDialogHeight * 0.4), // 40% من ارتفاع الحوار أو 200 بكسل
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: LocationService.yemeniGovernorates.length,
                  itemBuilder: (context, index) {
                    final governorate =
                        LocationService.yemeniGovernorates[index];
                    return RadioListTile<String>(
                      title: Text(governorate),
                      value: governorate,
                      groupValue: _selectedLocation,
                      dense: true, // جعل العناصر أكثر إحكاماً
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value;
                          _customLocationController.text = value ?? '';
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // إدخال موقع مخصص
              TextField(
                controller: _customLocationController,
                decoration: const InputDecoration(
                  labelText: 'أو أدخل موقعاً مخصصاً',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_location),
                  isDense: true, // جعل الحقل أكثر إحكاماً
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value.isNotEmpty ? value : null;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _selectedLocation != null && _selectedLocation!.isNotEmpty
              ? () => Navigator.of(context).pop(_selectedLocation)
              : null,
          child: const Text('تأكيد'),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
      _currentLocationResult = null;
    });

    try {
      LocationResult? result =
          await _locationService.getCurrentLocationWithAddress();

      if (result != null) {
        setState(() {
          _currentLocationResult = result.address;
          _selectedLocation = result.address;
          _customLocationController.text = result.address;
        });
      } else {
        setState(() {
          _currentLocationResult = 'لم يتم العثور على الموقع';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'لم يتم العثور على الموقع. تأكد من تفعيل خدمات الموقع والصلاحيات.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _currentLocationResult = 'خطأ في الحصول على الموقع';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحصول على الموقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingCurrentLocation = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _customLocationController.dispose();
  }
}
