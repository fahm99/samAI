import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({Key? key}) : super(key: key);

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  WeatherData? _weatherData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    // محاولة تحميل البيانات المحفوظة أولاً
    final cachedWeather = await WeatherService.getCachedWeatherData();
    if (cachedWeather != null && mounted) {
      setState(() {
        _weatherData = cachedWeather;
        _isLoading = false;
      });
    }

    // التحديث الخفي في الخلفية
    _loadWeatherDataSilently();
  }

  Future<void> _loadWeatherDataSilently() async {
    try {
      final weatherData = await WeatherService.getWeatherData();
      if (mounted) {
        setState(() {
          _weatherData = weatherData;
        });
      }
    } catch (e) {
      // تسجيل الخطأ فقط دون إظهاره للمستخدم
      debugPrint('خطأ في تحميل بيانات الطقس: $e');

      // إذا لم تكن هناك بيانات محفوظة، عرض بيانات افتراضية
      if (_weatherData == null && mounted) {
        setState(() {
          _weatherData = WeatherService.getDefaultWeatherData();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _weatherData == null) {
      return _buildLoadingCard();
    }

    // عرض البيانات المتاحة دائماً، حتى لو كانت قديمة أو افتراضية
    if (_weatherData != null) {
      return _buildWeatherCard(_weatherData!);
    }

    // في حالة عدم وجود أي بيانات، عرض بيانات افتراضية
    return _buildWeatherCard(WeatherService.getDefaultWeatherData());
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wb_sunny,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'جاري تحميل بيانات الطقس...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(WeatherData weather) {
    final gradientColors = WeatherService.getWeatherGradient(weather.iconCode);
    final weatherIcon = WeatherService.getWeatherIcon(weather.iconCode);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // الصف الأول: المعلومات الأساسية
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          weatherIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            weather.cityName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${weather.temperature.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      weather.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _buildWeatherInfo(
                    Icons.water_drop,
                    '${weather.humidity}%',
                    'رطوبة جوية',
                  ),
                  const SizedBox(height: 8),
                  _buildWeatherInfo(
                    Icons.air,
                    '${weather.windSpeed.round()} كم/س',
                    'سرعة الرياح',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // الصف الثاني: معلومات إضافية
          Row(
            children: [
              Expanded(
                child: _buildDetailedInfo(
                  Icons.water_drop,
                  'الرطوبة الجوية',
                  '${weather.humidity}%',
                  'الرطوبة الحالية',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailedInfo(
                  Icons.cloud_queue,
                  'وجود مطر',
                  weather.rainProbability != null
                      ? '${weather.rainProbability!.round()}%'
                      : 'غير متوقع',
                  'اليوم',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // الصف الثالث: معلومات إضافية جديدة
          Row(
            children: [
              Expanded(
                child: _buildDetailedInfo(
                  Icons.thermostat_outlined,
                  'الإحساس بالحرارة',
                  '${weather.feelsLike.round()}°',
                  'درجة مئوية',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailedInfo(
                  Icons.wb_sunny_outlined,
                  'مؤشر الأشعة',
                  weather.uvIndex.round().toString(),
                  'UV Index',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo(
      IconData icon, String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
