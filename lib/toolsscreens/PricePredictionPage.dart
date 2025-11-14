import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PricePredictionPage extends StatefulWidget {
  const PricePredictionPage({super.key});

  @override
  State<PricePredictionPage> createState() => _PricePredictionPageState();
}

class _PricePredictionPageState extends State<PricePredictionPage> {
  final List<String> crops = [
    'الموز',
    'الطماطم',
    'البطاطا',
    'البصل',
    'الذرة',
  ];
  
  final List<String> units = [
    'كيلوغرام',
    'طن',
    'صندوق',
    'شوال',
  ];
  
  String selectedCrop = 'الطماطم';
  String selectedUnit = 'كيلوغرام';
  double quantity = 1;
  final _formKey = GlobalKey<FormState>();
  
  // متوسط أسعار المنتجات بالريال اليمني لكل كيلوغرام
  final Map<String, double> basePrices = {
    'الموز': 500,
    'الطماطم': 300,
    'البطاطا': 400,
    'البصل': 350,
    'الذرة': 450,
  };
  
  // عوامل تحويل الوحدات إلى كيلوغرام
  final Map<String, double> unitConversion = {
    'كيلوغرام': 1,
    'طن': 1000,
    'صندوق': 15,  // تقديري
    'شوال': 50,   // تقديري
  };

  @override
  Widget build(BuildContext context) {
    final pricePerUnit = basePrices[selectedCrop] ?? 0;
    final conversionFactor = unitConversion[selectedUnit] ?? 1;
    final totalPrice = pricePerUnit * quantity * conversionFactor;
    final formattedPrice = NumberFormat.currency(
      symbol: 'ريال يمني',
      decimalDigits: 0,
    ).format(totalPrice);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تنبؤ أسعار المنتجات الزراعية'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crop selection
              _buildSectionHeader('اختر المنتج الزراعي'),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: selectedCrop,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: crops.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCrop = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              // Unit selection
              _buildSectionHeader('اختر وحدة القياس'),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: selectedUnit,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: units.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedUnit = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              // Quantity input
              _buildSectionHeader('الكمية'),
              TextFormField(
                initialValue: quantity.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: 'أدخل الكمية',
                  suffixText: selectedUnit,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الكمية';
                  }
                  if (double.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (double.tryParse(value) != null) {
                    setState(() {
                      quantity = double.parse(value);
                    });
                  }
                },
              ),
              const SizedBox(height: 30),
              
              // Price prediction card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'التنبؤ بالسعر',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('سعر الوحدة:'),
                          Text(
                            '${NumberFormat().format(pricePerUnit)} ريال/كجم',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الكمية:'),
                          Text(
                            '$quantity $selectedUnit',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 30, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'السعر المتوقع:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            formattedPrice,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Market trends
              _buildSectionHeader('اتجاهات السوق الأخيرة'),
              const SizedBox(height: 10),
              _buildMarketTrendItem('الطماطم', '+15% عن الشهر الماضي'),
              _buildMarketTrendItem('البصل', '-5% عن الأسبوع الماضي'),
              _buildMarketTrendItem('الموز', 'مستقر منذ أسبوعين'),
              _buildMarketTrendItem('البطاطا', '+8% عن الشهر الماضي'),
              _buildMarketTrendItem('الذرة', 'مستقر منذ شهر'),
              const SizedBox(height: 20),
              
              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ملاحظة: هذه الأسعار تقديرية بناءً على متوسطات السوق وقد تختلف حسب المنطقة والجودة والعرض والطلب.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تحديث التقدير السعري'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }
  
  Widget _buildMarketTrendItem(String product, String trend) {
    Color trendColor = Colors.grey;
    if (trend.contains('+')) trendColor = Colors.red;
    if (trend.contains('-')) trendColor = Colors.green;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: trendColor,
              shape: BoxShape.circle,
            ),
          ),
          Text(product, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(trend, style: TextStyle(color: trendColor)),
        ],
      ),
    );
  }
}