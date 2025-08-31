import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حاسبة الأسمدة والمبيدات',
      theme: ThemeData(
        fontFamily: 'Tajawal',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const FertilizerCalculator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FertilizerCalculator extends StatefulWidget {
  const FertilizerCalculator({super.key});

  @override
  State<FertilizerCalculator> createState() => _FertilizerCalculatorState();
}

class _FertilizerCalculatorState extends State<FertilizerCalculator> {
  final List<String> crops = [
    'الموز',
    'الطماطم',
    'البطاطا',
    'البصل',
    'الذرة',
    'القات'
  ];
  String selectedCrop = 'الطماطم';
  int areaSize = 1;
  int plantCount = 500;
  bool showDetails = false;
  bool showPesticides = false;

  // Nutrient data for each crop (N, P, K in kg per hectare)
  final Map<String, List<double>> cropNutrients = {
    'الموز': [150.0, 50.0, 200.0],
    'الطماطم': [120.0, 60.0, 180.0],
    'البطاطا': [100.0, 70.0, 150.0],
    'البصل': [80.0, 40.0, 120.0],
    'الذرة': [140.0, 60.0, 160.0],
    'القات': [90.0, 30.0, 110.0],
  };

  // Recommended fertilizers for each crop (Urea, MOP, DAP in kg per hectare)
  final Map<String, List<double>> cropFertilizers = {
    'الموز': [109.0, 250.0, 80.0],
    'الطماطم': [130.0, 200.0, 90.0],
    'البطاطا': [110.0, 180.0, 100.0],
    'البصل': [90.0, 150.0, 70.0],
    'الذرة': [120.0, 220.0, 85.0],
    'القات': [95.0, 130.0, 60.0],
  };

  // Recommended pesticides for each crop
  final Map<String, List<String>> cropPesticides = {
    'الموز': ['مبيد فطري كلوروثالونيل', 'مبيد حشري إيميداكلوبريد'],
    'الطماطم': ['مبيد فطري مانكوزيب', 'مبيد حشري لامدا-سيهالوثرين'],
    'البطاطا': ['مبيد فطري ميتالاكسيل', 'مبيد حشري ثياميثوكسام'],
    'البصل': ['مبيد فطري بروباموكارب', 'مبيد حشري دلتامثرين'],
    'الذرة': ['مبيد فطري تيبوكونازول', 'مبيد حشري بيتا-سيفلثرين'],
    'القات': ['مبيد فطري كبريتات النحاس', 'مبيد حشري دايميثوايت'],
  };

  @override
  Widget build(BuildContext context) {
    final nutrients = cropNutrients[selectedCrop]!;
    final fertilizers = cropFertilizers[selectedCrop]!;
    final pesticides = cropPesticides[selectedCrop]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة الأسمدة والمبيدات'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop selection
            _buildSectionHeader('اختر المحصول'),
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
                    showDetails = false;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Area size input
            _buildSectionHeader('مساحة الأرض (هكتار)'),
            Slider(
              value: areaSize.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              label: '$areaSize هكتار',
              onChanged: (double value) {
                setState(() {
                  areaSize = value.toInt();
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (areaSize > 1) areaSize--;
                    });
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$areaSize هكتار',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      if (areaSize < 100) areaSize++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Plant count input (for tree crops)
            if (selectedCrop == 'الموز' || selectedCrop == 'القات')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('عدد الأشجار'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (plantCount > 100) plantCount -= 100;
                          });
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          NumberFormat.decimalPattern().format(plantCount),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            plantCount += 100;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Nutrient requirements
            _buildSectionHeader('احتياجات المغذيات (كجم/هكتار)'),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutrientTile('N', nutrients[0], Colors.blue),
                    _buildNutrientTile('P', nutrients[1], Colors.orange),
                    _buildNutrientTile('K', nutrients[2], Colors.purple),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Fertilizer calculator
            _buildSectionHeader('حاسبة الأسمدة'),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('الكمية الموصى بها'),
                    trailing: Text(
                      '${areaSize} هكتار',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('نوع السماد', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('كجم/هكتار', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('${areaSize} هكتار', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        _buildFertilizerRow('اليوريا', fertilizers[0]),
                        _buildFertilizerRow('MOP', fertilizers[1]),
                        _buildFertilizerRow('DAP', fertilizers[2]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        showDetails = !showDetails;
                      });
                    },
                    child: Text(
                      showDetails ? 'إخفاء التفاصيل' : 'عرض التفاصيل',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        showPesticides = !showPesticides;
                      });
                    },
                    child: Text(
                      showPesticides ? 'إخفاء المبيدات' : 'عرض المبيدات',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Detailed instructions
            if (showDetails)
              _buildDetailsSection(selectedCrop),

            // Pesticides recommendations
            if (showPesticides)
              _buildPesticidesSection(pesticides),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildNutrientTile(String nutrient, double value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Text(
            nutrient,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'كجم/هكتار',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  TableRow _buildFertilizerRow(String name, double value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(name),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(value.toStringAsFixed(1)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text((value * areaSize).toStringAsFixed(1)),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(String crop) {
    // This would contain crop-specific details
    final details = {
      'الموز': '''
• يفضل تقسيم التسميد على 4-6 دفعات خلال السنة
• التسميد العضوي مهم جداً للموز (20-30 كجم سماد عضوي لكل شجرة سنوياً)
• الري المنتظم ضروري بعد كل تسميد
''',
      'الطماطم': '''
• تقسيم التسميد إلى 3 مراحل: عند الزراعة، عند الإزهار، عند العقد
• تجنب زيادة النيتروجين بعد مرحلة الإزهار
• الري بالتنقيط مع التسميد المذاب يزيد الكفاءة
''',
      'البطاطا': '''
• 50% من السماد عند الزراعة، 25% بعد 30 يوم، 25% بعد 60 يوم
• تجنب التسميد خلال الأسابيع الأخيرة قبل الحصاد
• الحفاظ على رطوبة التربة بعد التسميد
''',
      'البصل': '''
• التسميد الأساسي قبل الزراعة مهم للبصل
• تقسيم التسميد إلى 3 دفعات: عند الزراعة، بعد 30 يوم، بعد 60 يوم
• تقليل الري قبل الحصاح بأسبوعين
''',
      'الذرة': '''
• 50% من السماد عند الزراعة، 50% بعد 30-40 يوم
• التسميد الورقي مفيد في الترب الفقيرة
• الري الغزير بعد التسميد يزيد الكفاءة
''',
      'القات': '''
• التسميد العضوي أساسي (10-15 كجم لكل شجرة سنوياً)
• تقسيم التسميد الكيميائي إلى 3 دفعات في السنة
• الري المعتدل بعد التسميد
''',
    };

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تعليمات التسميد الموصى بها:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            details[crop]!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPesticidesSection(List<String> pesticides) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المبيدات الموصى بها:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          ...pesticides.map((pesticide) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_left, size: 24),
                const SizedBox(width: 4),
                Expanded(child: Text(pesticide)),
              ],
            ),
          )).toList(),
          const SizedBox(height: 8),
          const Text(
            'ملاحظة: يرجى اتباع تعليمات الاستخدام على العبوة ومراعاة فترات الأمان',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}