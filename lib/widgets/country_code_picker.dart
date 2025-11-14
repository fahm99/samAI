import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountryCodePicker extends StatefulWidget {
  final String? initialCountryCode;
  final String? initialCountryFlag;
  final String? initialCountryName;
  final Function(String countryCode, String countryFlag, String countryName)
      onChanged;
  final bool enabled;

  const CountryCodePicker({
    super.key,
    this.initialCountryCode,
    this.initialCountryFlag,
    this.initialCountryName,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  String _selectedCountryCode = '+967';
  String _selectedCountryFlag = '🇾🇪';

  @override
  void initState() {
    super.initState();
    _loadSavedCountryCode();

    if (widget.initialCountryCode != null) {
      _selectedCountryCode = widget.initialCountryCode!;
      _selectedCountryFlag = widget.initialCountryFlag ?? '🇾🇪';
    }
  }

  Future<void> _loadSavedCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('last_country_code');
    final savedFlag = prefs.getString('last_country_flag');
    prefs.getString('last_country_name');

    if (savedCode != null && widget.initialCountryCode == null) {
      setState(() {
        _selectedCountryCode = savedCode;
        _selectedCountryFlag = savedFlag ?? '🇾🇪';
      });
    }
  }

  Future<void> _saveCountryCode(String code, String flag, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_country_code', code);
    await prefs.setString('last_country_flag', flag);
    await prefs.setString('last_country_name', name);
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountryPickerBottomSheet(
        selectedCountryCode: _selectedCountryCode,
        onCountrySelected: (country) {
          setState(() {
            _selectedCountryCode = country.code;
            _selectedCountryFlag = country.flag;
          });
          _saveCountryCode(country.code, country.flag, country.name);
          widget.onChanged(country.code, country.flag, country.name);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _showCountryPicker : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
          color: widget.enabled ? Colors.white : Colors.grey.shade100,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCountryFlag,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              _selectedCountryCode,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.enabled) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CountryPickerBottomSheet extends StatefulWidget {
  final String selectedCountryCode;
  final Function(CountryInfo) onCountrySelected;

  const CountryPickerBottomSheet({
    super.key,
    required this.selectedCountryCode,
    required this.onCountrySelected,
  });

  @override
  State<CountryPickerBottomSheet> createState() =>
      _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<CountryPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryInfo> _filteredCountries = [];
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCountries = CountryData.countries;
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = CountryData.countries;
      } else {
        _filteredCountries = CountryData.countries.where((country) {
          return country.name.toLowerCase().contains(query.toLowerCase()) ||
              country.code.contains(query) ||
              country.nameAr.contains(query);
        }).toList();
      }
    });
  }

  void _addManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isNotEmpty && code.startsWith('+')) {
      final manualCountry = CountryInfo(
        name: 'رمز مخصص',
        nameAr: 'رمز مخصص',
        code: code,
        flag: '🌍',
      );
      widget.onCountrySelected(manualCountry);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'اختر رمز الدولة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن الدولة أو الرمز...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: _filterCountries,
            ),
          ),

          const SizedBox(height: 16),

          // Manual code input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualCodeController,
                    decoration: InputDecoration(
                      hintText: 'أو اكتب الرمز يدوياً (مثل: +966)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addManualCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('إضافة'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Countries list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountryCode;

                return ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    country.nameAr,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('${country.name} ${country.code}'),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                      : null,
                  selected: isSelected,
                  selectedTileColor: const Color(0xFF2E7D32).withOpacity(0.1),
                  onTap: () {
                    widget.onCountrySelected(country);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }
}

class CountryInfo {
  final String name;
  final String nameAr;
  final String code;
  final String flag;

  CountryInfo({
    required this.name,
    required this.nameAr,
    required this.code,
    required this.flag,
  });
}

class CountryData {
  static final List<CountryInfo> countries = [
    CountryInfo(name: 'Yemen', nameAr: 'اليمن', code: '+967', flag: '🇾🇪'),
    CountryInfo(
        name: 'Saudi Arabia', nameAr: 'السعودية', code: '+966', flag: '🇸🇦'),
    CountryInfo(
        name: 'United Arab Emirates',
        nameAr: 'الإمارات',
        code: '+971',
        flag: '🇦🇪'),
    CountryInfo(name: 'Egypt', nameAr: 'مصر', code: '+20', flag: '🇪🇬'),
    CountryInfo(name: 'Jordan', nameAr: 'الأردن', code: '+962', flag: '🇯🇴'),
    CountryInfo(name: 'Lebanon', nameAr: 'لبنان', code: '+961', flag: '🇱🇧'),
    CountryInfo(name: 'Syria', nameAr: 'سوريا', code: '+963', flag: '🇸🇾'),
    CountryInfo(name: 'Iraq', nameAr: 'العراق', code: '+964', flag: '🇮🇶'),
    CountryInfo(name: 'Kuwait', nameAr: 'الكويت', code: '+965', flag: '🇰🇼'),
    CountryInfo(name: 'Qatar', nameAr: 'قطر', code: '+974', flag: '🇶🇦'),
    CountryInfo(name: 'Bahrain', nameAr: 'البحرين', code: '+973', flag: '🇧🇭'),
    CountryInfo(name: 'Oman', nameAr: 'عُمان', code: '+968', flag: '🇴🇲'),
    CountryInfo(
        name: 'Palestine', nameAr: 'فلسطين', code: '+970', flag: '🇵🇸'),
    CountryInfo(name: 'Morocco', nameAr: 'المغرب', code: '+212', flag: '🇲🇦'),
    CountryInfo(name: 'Algeria', nameAr: 'الجزائر', code: '+213', flag: '🇩🇿'),
    CountryInfo(name: 'Tunisia', nameAr: 'تونس', code: '+216', flag: '🇹🇳'),
    CountryInfo(name: 'Libya', nameAr: 'ليبيا', code: '+218', flag: '🇱🇾'),
    CountryInfo(name: 'Sudan', nameAr: 'السودان', code: '+249', flag: '🇸🇩'),
    CountryInfo(name: 'Somalia', nameAr: 'الصومال', code: '+252', flag: '🇸🇴'),
    CountryInfo(name: 'Djibouti', nameAr: 'جيبوتي', code: '+253', flag: '🇩🇯'),
    CountryInfo(
        name: 'Comoros', nameAr: 'جزر القمر', code: '+269', flag: '🇰🇲'),
    CountryInfo(
        name: 'Mauritania', nameAr: 'موريتانيا', code: '+222', flag: '🇲🇷'),
    CountryInfo(
        name: 'United States',
        nameAr: 'الولايات المتحدة',
        code: '+1',
        flag: '🇺🇸'),
    CountryInfo(
        name: 'United Kingdom',
        nameAr: 'المملكة المتحدة',
        code: '+44',
        flag: '🇬🇧'),
    CountryInfo(name: 'Germany', nameAr: 'ألمانيا', code: '+49', flag: '🇩🇪'),
    CountryInfo(name: 'France', nameAr: 'فرنسا', code: '+33', flag: '🇫🇷'),
    CountryInfo(name: 'Italy', nameAr: 'إيطاليا', code: '+39', flag: '🇮🇹'),
    CountryInfo(name: 'Spain', nameAr: 'إسبانيا', code: '+34', flag: '🇪🇸'),
    CountryInfo(
        name: 'Netherlands', nameAr: 'هولندا', code: '+31', flag: '🇳🇱'),
    CountryInfo(name: 'Belgium', nameAr: 'بلجيكا', code: '+32', flag: '🇧🇪'),
    CountryInfo(
        name: 'Switzerland', nameAr: 'سويسرا', code: '+41', flag: '🇨🇭'),
    CountryInfo(name: 'Austria', nameAr: 'النمسا', code: '+43', flag: '🇦🇹'),
    CountryInfo(name: 'Sweden', nameAr: 'السويد', code: '+46', flag: '🇸🇪'),
    CountryInfo(name: 'Norway', nameAr: 'النرويج', code: '+47', flag: '🇳🇴'),
    CountryInfo(name: 'Denmark', nameAr: 'الدنمارك', code: '+45', flag: '🇩🇰'),
    CountryInfo(name: 'Finland', nameAr: 'فنلندا', code: '+358', flag: '🇫🇮'),
    CountryInfo(name: 'Russia', nameAr: 'روسيا', code: '+7', flag: '🇷🇺'),
    CountryInfo(name: 'China', nameAr: 'الصين', code: '+86', flag: '🇨🇳'),
    CountryInfo(name: 'Japan', nameAr: 'اليابان', code: '+81', flag: '🇯🇵'),
    CountryInfo(
        name: 'South Korea',
        nameAr: 'كوريا الجنوبية',
        code: '+82',
        flag: '🇰🇷'),
    CountryInfo(name: 'India', nameAr: 'الهند', code: '+91', flag: '🇮🇳'),
    CountryInfo(name: 'Pakistan', nameAr: 'باكستان', code: '+92', flag: '🇵🇰'),
    CountryInfo(
        name: 'Bangladesh', nameAr: 'بنغلاديش', code: '+880', flag: '🇧🇩'),
    CountryInfo(name: 'Turkey', nameAr: 'تركيا', code: '+90', flag: '🇹🇷'),
    CountryInfo(name: 'Iran', nameAr: 'إيران', code: '+98', flag: '🇮🇷'),
    CountryInfo(
        name: 'Afghanistan', nameAr: 'أفغانستان', code: '+93', flag: '🇦🇫'),
    CountryInfo(
        name: 'Australia', nameAr: 'أستراليا', code: '+61', flag: '🇦🇺'),
    CountryInfo(name: 'Canada', nameAr: 'كندا', code: '+1', flag: '🇨🇦'),
    CountryInfo(name: 'Brazil', nameAr: 'البرازيل', code: '+55', flag: '🇧🇷'),
    CountryInfo(
        name: 'Argentina', nameAr: 'الأرجنتين', code: '+54', flag: '🇦🇷'),
    CountryInfo(name: 'Mexico', nameAr: 'المكسيك', code: '+52', flag: '🇲🇽'),
    CountryInfo(
        name: 'South Africa',
        nameAr: 'جنوب أفريقيا',
        code: '+27',
        flag: '🇿🇦'),
    CountryInfo(name: 'Nigeria', nameAr: 'نيجيريا', code: '+234', flag: '🇳🇬'),
    CountryInfo(name: 'Kenya', nameAr: 'كينيا', code: '+254', flag: '🇰🇪'),
    CountryInfo(
        name: 'Ethiopia', nameAr: 'إثيوبيا', code: '+251', flag: '🇪🇹'),
    CountryInfo(name: 'Ghana', nameAr: 'غانا', code: '+233', flag: '🇬🇭'),
    CountryInfo(
        name: 'Tanzania', nameAr: 'تنزانيا', code: '+255', flag: '🇹🇿'),
    CountryInfo(name: 'Uganda', nameAr: 'أوغندا', code: '+256', flag: '🇺🇬'),
    CountryInfo(name: 'Rwanda', nameAr: 'رواندا', code: '+250', flag: '🇷🇼'),
    CountryInfo(name: 'Senegal', nameAr: 'السنغال', code: '+221', flag: '🇸🇳'),
    CountryInfo(name: 'Mali', nameAr: 'مالي', code: '+223', flag: '🇲🇱'),
    CountryInfo(
        name: 'Burkina Faso',
        nameAr: 'بوركينا فاسو',
        code: '+226',
        flag: '🇧🇫'),
    CountryInfo(name: 'Niger', nameAr: 'النيجر', code: '+227', flag: '🇳🇪'),
    CountryInfo(name: 'Chad', nameAr: 'تشاد', code: '+235', flag: '🇹🇩'),
    CountryInfo(
        name: 'Cameroon', nameAr: 'الكاميرون', code: '+237', flag: '🇨🇲'),
    CountryInfo(
        name: 'Central African Republic',
        nameAr: 'جمهورية أفريقيا الوسطى',
        code: '+236',
        flag: '🇨🇫'),
    CountryInfo(
        name: 'Democratic Republic of Congo',
        nameAr: 'جمهورية الكونغو الديمقراطية',
        code: '+243',
        flag: '🇨🇩'),
    CountryInfo(
        name: 'Republic of Congo',
        nameAr: 'جمهورية الكونغو',
        code: '+242',
        flag: '🇨🇬'),
    CountryInfo(name: 'Gabon', nameAr: 'الغابون', code: '+241', flag: '🇬🇦'),
    CountryInfo(
        name: 'Equatorial Guinea',
        nameAr: 'غينيا الاستوائية',
        code: '+240',
        flag: '🇬🇶'),
    CountryInfo(
        name: 'Sao Tome and Principe',
        nameAr: 'ساو تومي وبرينسيبي',
        code: '+239',
        flag: '🇸🇹'),
    CountryInfo(
        name: 'Cape Verde', nameAr: 'الرأس الأخضر', code: '+238', flag: '🇨🇻'),
  ];
}
