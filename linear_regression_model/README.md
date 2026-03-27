# Student GPA Prediction — Model Deployment

## Mission & Problem
To increase access to quality tech education for young Africans by building inclusive tech academies equipped with the best tutoring tools, empowering the next generation of African innovators through data-driven learning support systems. This project predicts a student's GPA from study habits, attendance, tutoring, and parental involvement — enabling academies to identify at-risk students early and direct support where it matters most.

**Dataset:** [Kaggle — Student Performance Factors](https://www.kaggle.com/datasets/lainguyn123/student-performance-factors) | 2,392 students, 15 features.

---

## Live API

**Base URL:** `https://mobile-app-regression-analysis-936b.onrender.com`

**Swagger UI (test here):** [`https://mobile-app-regression-analysis-936b.onrender.com/docs`](https://mobile-app-regression-analysis-936b.onrender.com/docs)

**Prediction endpoint:** `POST /predict`

Example request body:
```json
{
  "Age": 17,
  "Gender": 1,
  "Ethnicity": 0,
  "ParentalEducation": 3,
  "StudyTimeWeekly": 15.5,
  "Absences": 4,
  "Tutoring": 1,
  "ParentalSupport": 3,
  "Extracurricular": 1,
  "Sports": 0,
  "Music": 1,
  "Volunteering": 0
}
```

Example response:
```json
{
  "predicted_GPA": 3.1245
}
```

---

## Video Demo

▶️ [YouTube Demo Link](https://youtube.com/your-link-here) ← replace with your link

---

## Repository Structure

```
linear_regression_model/
└── summative/
    ├── linear_regression/
    │   └── multivariate.ipynb
    ├── API/
    │   ├── prediction.py
    │   └── requirements.txt
    └── FlutterApp/
        ├── lib/
        │   ├── main.dart
        │   └── services/
        │       └── api_service.dart
        └── pubspec.yaml
```

---

## Running the Flutter Mobile App

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.0.0 installed
- Android device or emulator with **USB Debugging enabled**
- Run `flutter doctor` to confirm your setup is ready

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/your-username/your-repo.git
cd linear_regression_model/summative/FlutterApp
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Connect your Android device**
- On your phone: Settings → Developer Options → USB Debugging → ON
- Plug in via USB
- Run `flutter devices` to confirm your device is detected

**4. Run the app**
```bash
flutter run
```

> **Note:** The app fetches predictions from the live Render API. An internet connection is required. On first use after inactivity, the server may take up to 30 seconds to wake up — this is normal for free-tier hosting.

### Running on Android Emulator
```bash
# Open Android Studio → Device Manager → Start an emulator, then:
flutter run -d emulator-5554
```

---

## Running the API Locally (optional)

```bash
cd linear_regression_model/summative/API
pip install -r requirements.txt

# Copy trained model files from the notebook output:
cp ../linear_regression/best_student_gpa_model.pkl .
cp ../linear_regression/scaler.pkl .

uvicorn prediction:app --reload --host 0.0.0.0 --port 8000
```

Open `http://localhost:8000/docs` for local Swagger UI.