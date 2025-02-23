
**Digi-Eye** is a **currency detection application** designed for visually impaired users. It utilizes **TensorFlow Lite (TFLite)** for real-time **Indian currency recognition** through the camera and provides **voice output** for accessibility. Additionally, it saves the detected currency name and timestamp to **Firebase** for record-keeping.  

## 🚀 Features  

- **📸 Automatic Camera Initialization:** The camera starts as soon as the app is launched.  
- **🎯 Currency Detection:** Detects **₹10, ₹20, ₹50, ₹100, ₹200, ₹500** denominations.  
- **🗣️ Voice Output:** Announces the detected currency denomination.  
- **🔹 Capture Button:** Captures the detected note for confirmation.  
- **☁️ Firebase Integration:**  
  - Stores detected currency names.  
  - Saves timestamps for each detection.  

## 🛠️ Tech Stack  

- **Flutter** (for UI and app development)  
- **TensorFlow Lite (TFLite)** (for machine learning-based currency detection)  
- **Firebase** (for storing detection logs)  

## 📸 Dataset Link
https://www.kaggle.com/datasets/pypiahmad/indian-rupees-and-thai-baht-banknotes

## 📦 Installation  

### Clone the Repository  
```sh
git clone https://github.com/kunal22823/DigiEye.git
cd DigiEye
flutter pub get
flutter run

