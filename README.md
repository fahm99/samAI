# 🌿 SAM – Smart Agricultural Assistant

> **"Empowering farmers with smart tools, real-time insights, and a connected agricultural marketplace."**

---

## 📱 Overview

**SAM** is a comprehensive **smart agriculture mobile application** built with **Flutter**, designed to assist farmers and agricultural enthusiasts through:
- 🌾 Smart farming tools  
- 🛒 Integrated marketplace  
- 🌱 Plant health diagnostics  
- 💧 Intelligent irrigation control  

The app combines IoT, AI, and modern mobile design to make farming simpler, more efficient, and sustainable.

---

## 🖼️ Screenshots

| Home | Market | Plant | Profile |
|------|---------|--------|----------|
| ![Home](assets/home.jpg) | ![Market](assets/market.jpg) | ![Plant](assets/plant.jpg) | ![Profile](assets/profile.jpg) |

| Login | Circuit | Water Control |
|--------|----------|----------------|
| ![Login](assets/login.jpg) | ![Circuit](assets/circuit.jpg) | ![Water Control](assets/water%20control.jpg) |

---

## ⚙️ Features

### 🛒 Agricultural Marketplace
- Buy and sell agricultural products  
- Add listings with **images**, **descriptions**, and **pricing**  
- Chat directly with **buyers** and **sellers**  
- Manage **user profiles** and **your own product catalog**

### 💧 Smart Irrigation *(Coming Soon)*
- Monitor and control irrigation systems  
- Schedule watering times  
- Optimize water usage using **weather** and **soil** data  

### 🌿 Plant Disease Diagnosis *(Coming Soon)*
- Identify plant diseases using **AI-powered image recognition**  
- Receive **treatment suggestions**  
- Access a **database of common plant issues**

---

## 🧠 Technical Overview

**Built With**
- 🧩 **Flutter** – Cross-platform mobile framework  
- ☁️ **Supabase** – Backend-as-a-Service for:  
  - Authentication  
  - Cloud Firestore database  
  - Storage for images  
  - Cloud Functions  
- 🔄 **BLoC Pattern** – Robust state management  

---

## 📂 Project Structure

```bash
lib/
├── bloc/           # Business logic components
├── models/         # Data models
├── repositories/   # Data access layer
├── screens/        # App screens (UI)
└── widgets/        # Reusable UI components

assets/
├── home.jpg
├── market.jpg
├── plant.jpg
├── profile.jpg
├── login.jpg
├── circuit.jpg
└── water control.jpg
