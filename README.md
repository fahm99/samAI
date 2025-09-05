# SAM - (Your Smart Agricultural Assistant)

SAM is a comprehensive mobile application designed to support farmers and agricultural enthusiasts with smart farming tools, marketplace features, and plant health diagnostics.

## Features

### 1. Agricultural Marketplace
- Buy and sell agricultural products
- Product listings with images, descriptions, and pricing
- Chat with sellers and buyers
- User profiles and product management

### 2. Smart Irrigation
- Monitor and control irrigation systems (Coming Soon)
- Schedule watering times
- Optimize water usage based on weather and soil conditions

### 3. Plant Disease Diagnosis
- Identify plant diseases through image recognition (Coming Soon)
- Get treatment recommendations
- Access a database of common plant diseases

## Technical Details

### Built With
- Flutter for cross-platform mobile development
- Supabase for backend services:
  - Authentication
  - Cloud Firestore for database
  - Storage for images
  - Cloud Functions
- BLoC pattern for state management

### Project Structure
- `lib/`: Main source code
  - `bloc/`: Business Logic Components
  - `models/`: Data models
  - `repositories/`: Data access layer
  - `screens/`: UI screens
  - `widgets/`: Reusable UI components

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Supabase account
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository 

2. Install dependencies
```bash
flutter pub get
```



3. Run the app
```bash
flutter run
```

## Usage

### User Authentication
- Sign up with email and password
- Log in with existing credentials
- Profile management

### Marketplace
- Browse products
- Add new products with images and details
- Chat with other users
- Manage your product listings

### Smart Agriculture Features
- Navigate to Smart Irrigation for water management tools
- Use Plant Disease Diagnosis to identify plant health issues

## Roadmap

- [ ] Implement advanced search and filtering for marketplace
- [ ] Add real-time notifications
- [ ] Develop AI-powered plant disease recognition
- [ ] Integrate with IoT devices for smart irrigation
- [ ] Add weather forecasting for agricultural planning

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact


## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Supabase](https://Supabase.google.com/)
- [Font Awesome Flutter](https://pub.dev/packages/font_awesome_flutter)
- [Flutter BLoC](https://pub.dev/packages/flutter_bloc)
