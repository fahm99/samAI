import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'country_code_picker.dart';

class PhoneNumberField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialCountryCode;
  final String? initialCountryFlag;
  final String? initialCountryName;
  final String? labelText;
  final String? hintText;
  final bool isRequired;
  final bool enabled;
  final Function(String countryCode, String countryFlag, String countryName)? onCountryChanged;
  final String? Function(String?)? validator;

  const PhoneNumberField({
    super.key,
    this.controller,
    this.initialCountryCode,
    this.initialCountryFlag,
    this.initialCountryName,
    this.labelText = 'رقم الهاتف',
    this.hintText = 'أدخل رقم الهاتف',
    this.isRequired = false,
    this.enabled = true,
    this.onCountryChanged,
    this.validator,
  });

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  late TextEditingController _controller;
  String _selectedCountryCode = '+967';
  String _selectedCountryFlag = '🇾🇪';
  String _selectedCountryName = 'Yemen';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    
    if (widget.initialCountryCode != null) {
      _selectedCountryCode = widget.initialCountryCode!;
      _selectedCountryFlag = widget.initialCountryFlag ?? '🇾🇪';
      _selectedCountryName = widget.initialCountryName ?? 'Yemen';
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    if (widget.isRequired && (value == null || value.isEmpty)) {
      return 'رقم الهاتف مطلوب';
    }

    if (value != null && value.isNotEmpty) {
      // إزالة المسافات والرموز
      final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
      
      // التحقق من الطول
      if (cleanNumber.length < 7) {
        return 'رقم الهاتف قصير جداً';
      }
      
      if (cleanNumber.length > 15) {
        return 'رقم الهاتف طويل جداً';
      }

      // التحقق من صحة الرقم حسب رمز الدولة
      if (!_isValidPhoneForCountry(cleanNumber, _selectedCountryCode)) {
        return 'رقم الهاتف غير صحيح لهذه الدولة';
      }
    }

    return null;
  }

  bool _isValidPhoneForCountry(String phoneNumber, String countryCode) {
    // قواعد التحقق الأساسية لبعض الدول
    switch (countryCode) {
      case '+967': // اليمن
        return phoneNumber.length >= 9 && phoneNumber.length <= 9;
      case '+966': // السعودية
        return phoneNumber.length == 9 && phoneNumber.startsWith('5');
      case '+971': // الإمارات
        return phoneNumber.length == 9 && phoneNumber.startsWith('5');
      case '+20': // مصر
        return phoneNumber.length >= 10 && phoneNumber.length <= 11;
      case '+1': // أمريكا/كندا
        return phoneNumber.length == 10;
      case '+44': // بريطانيا
        return phoneNumber.length >= 10 && phoneNumber.length <= 11;
      default:
        // قاعدة عامة للدول الأخرى
        return phoneNumber.length >= 7 && phoneNumber.length <= 15;
    }
  }

  String _formatPhoneNumber(String value) {
    // إزالة جميع الرموز والمسافات
    final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // تطبيق تنسيق حسب رمز الدولة
    switch (_selectedCountryCode) {
      case '+967': // اليمن
        if (cleanNumber.length >= 3) {
          return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3)}';
        }
        break;
      case '+966': // السعودية
      case '+971': // الإمارات
        if (cleanNumber.length >= 2) {
          return '${cleanNumber.substring(0, 2)} ${cleanNumber.substring(2)}';
        }
        break;
      case '+1': // أمريكا/كندا
        if (cleanNumber.length >= 6) {
          return '(${cleanNumber.substring(0, 3)}) ${cleanNumber.substring(3, 6)}-${cleanNumber.substring(6)}';
        } else if (cleanNumber.length >= 3) {
          return '(${cleanNumber.substring(0, 3)}) ${cleanNumber.substring(3)}';
        }
        break;
      default:
        // تنسيق عام
        if (cleanNumber.length >= 3) {
          return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3)}';
        }
        break;
    }
    
    return cleanNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Country code picker
            CountryCodePicker(
              initialCountryCode: _selectedCountryCode,
              initialCountryFlag: _selectedCountryFlag,
              initialCountryName: _selectedCountryName,
              enabled: widget.enabled,
              onChanged: (countryCode, countryFlag, countryName) {
                setState(() {
                  _selectedCountryCode = countryCode;
                  _selectedCountryFlag = countryFlag;
                  _selectedCountryName = countryName;
                });
                
                if (widget.onCountryChanged != null) {
                  widget.onCountryChanged!(countryCode, countryFlag, countryName);
                }
                
                // إعادة التحقق من صحة الرقم عند تغيير الدولة
                if (_controller.text.isNotEmpty) {
                  setState(() {});
                }
              },
            ),
            
            // Phone number input
            Expanded(
              child: TextFormField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                enabled: widget.enabled,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, 
                    vertical: 16,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                validator: _validatePhoneNumber,
                onChanged: (value) {
                  // تطبيق التنسيق التلقائي
                  final formatted = _formatPhoneNumber(value);
                  if (formatted != value) {
                    _controller.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        
        // مثال على التنسيق
        const SizedBox(height: 8),
        Text(
          'مثال: $_selectedCountryCode ${_getExampleNumber(_selectedCountryCode)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getExampleNumber(String countryCode) {
    switch (countryCode) {
      case '+967': // اليمن
        return '777 123 456';
      case '+966': // السعودية
        return '50 123 4567';
      case '+971': // الإمارات
        return '50 123 4567';
      case '+20': // مصر
        return '10 1234 5678';
      case '+1': // أمريكا/كندا
        return '(555) 123-4567';
      case '+44': // بريطانيا
        return '7700 900123';
      default:
        return '123 456 789';
    }
  }

  // دالة للحصول على الرقم الكامل مع رمز الدولة
  String getFullPhoneNumber() {
    final cleanNumber = _controller.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.isEmpty) return '';
    return '$_selectedCountryCode$cleanNumber';
  }

  // دالة للحصول على رمز الدولة المحدد
  String getSelectedCountryCode() {
    return _selectedCountryCode;
  }

  // دالة للحصول على الرقم بدون رمز الدولة
  String getCleanPhoneNumber() {
    return _controller.text.replaceAll(RegExp(r'[^\d]'), '');
  }
}
