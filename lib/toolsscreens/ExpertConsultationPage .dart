import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpertConsultationPage extends StatelessWidget {
  const ExpertConsultationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استشارة الخبراء الزراعيين'),
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // AI Expert Card
          _buildAIExpertCard(context),
          const SizedBox(height: 20),
          
          // Human Experts Title
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'خبراء زراعيون متاحون للاستشارة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          
          // Human Experts List
          _buildExpertCard(
            name: 'فهيمي فؤاد أحمد العامري',
            phone: '738694238',
            image: 'assets/images/logo.png', // تأكد من إضافة الصورة في مجلد assets
            specialty: 'خبير زراعة الموز والخضروات',
            experience: '15 سنة خبرة',
          ),
          const SizedBox(height: 16),
          _buildExpertCard(
            name: 'موفق أحمد عبدالوهاب الكمالي',
            phone: '+967 772 763 067',
            image: 'assets/images/logo.png', // تأكد من إضافة الصورة في مجلد assets
            specialty: 'خبير تسميد ومبيدات زراعية',
            experience: '12 سنة خبرة',
          ),
        ],
      ),
    );
  }

  Widget _buildAIExpertCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green,
              child: Icon(Icons.psychology, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'الخبير الزراعي الذكي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'إجابات فورية على استفساراتك الزراعية باستخدام الذكاء الاصطناعي',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // يمكنك استبدال هذا بوظيفة الدردشة مع الذكاء الاصطناعي
                _showAIExpertDialog(context);
              },
              icon: const Icon(Icons.chat),
              label: const Text('محادثة مع الذكاء الاصطناعي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertCard({
    required String name,
    required String phone,
    required String image,
    required String specialty,
    required String experience,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(image),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        experience,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _launchWhatsApp(phone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat, size: 18),
                      SizedBox(width: 4),
                      Text('واتساب'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final url = 'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9+]'), '')}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showAIExpertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الخبير الزراعي الذكي'),
        content: const Text(
          'مرحباً! أنا الخبير الزراعي الذكي. كيف يمكنني مساعدتك اليوم؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // يمكنك توجيه المستخدم إلى صفحة الدردشة مع الذكاء الاصطناعي هنا
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('سيتم فتح محادثة مع الخبير الذكي قريباً'),
                ),
              );
            },
            child: const Text('ابدأ المحادثة'),
          ),
        ],
      ),
    );
  }
}