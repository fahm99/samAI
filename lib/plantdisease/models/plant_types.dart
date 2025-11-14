class PlantTypes {
  // خريطة جميع أنواع النباتات المدعومة بواسطة API
  static const Map<String, Map<String, dynamic>> allPlants = {
    'طماطم': {
      'englishName': 'tomato',
      'isSupported': true,
      'displayName': 'الطماطم',
      'icon': 'eco'
    },
    'بطاطا': {
      'englishName': 'potato',
      'isSupported': true,
      'displayName': 'البطاطا',
      'icon': 'eco'
    },
    'موز': {
      'englishName': 'banana',
      'isSupported': true,
      'displayName': 'الموز',
      'icon': 'nature'
    },
    'بصل': {
      'englishName': 'onion',
      'isSupported': true,
      'displayName': 'البصل',
      'icon': 'eco'
    },
    'قمح': {
      'englishName': 'maize',
      'isSupported': true,
      'displayName': 'القمح',
      'icon': 'grass'
    },
    'ذرة': {
      'englishName': 'corn',
      'isSupported': true,
      'displayName': 'الذرة',
      'icon': 'grass'
    },
    'فلفل': {
      'englishName': 'pepper',
      'isSupported': true,
      'displayName': 'الفلفل',
      'icon': 'eco'
    },
    'خيار': {
      'englishName': 'cucumber',
      'isSupported': true,
      'displayName': 'الخيار',
      'icon': 'eco'
    },
  };

  // جميع النباتات مدعومة الآن بواسطة API
  static Map<String, Map<String, String>> get supportedPlants {
    return Map.fromEntries(
      allPlants.entries.map((entry) => MapEntry(
            entry.key,
            {
              'englishName': entry.value['englishName'] as String,
              'displayName': entry.value['displayName'] as String,
            },
          )),
    );
  }
}
