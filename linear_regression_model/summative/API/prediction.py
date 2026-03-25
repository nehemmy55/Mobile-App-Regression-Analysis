from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import numpy as np
import pandas as pd
import joblib
import os
import io

from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.tree import DecisionTreeRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error


BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH  = os.path.join(BASE_DIR, "..", "linear_regression", "best_student_gpa_model.pkl")
SCALER_PATH = os.path.join(BASE_DIR, "..", "linear_regression", "scaler.pkl")



FEATURE_COLUMNS = [
    "Age", "Gender", "Ethnicity", "ParentalEducation",
    "StudyTimeWeekly", "Absences", "Tutoring", "ParentalSupport",
    "Extracurricular", "Sports", "Music", "Volunteering",
    "StudyEfficiency", "EngagementScore",
]


# initialize FastAPI app

app = FastAPI(title="GPA Prediction API", version="1.0.0")


# create CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://10.0.2.2:8000",
        "https://mobile-app-regression-analysis-936b.onrender.com",
    ],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization", "Accept"],
)


#route for root

@app.get("/")
def root():
    return {"message": "API running - go to /docs"}


# health checker

@app.get("/health")
def health():
    return {"status": "ok"}


# schema for input

class StudentData(BaseModel):
    Age:               int   = Field(..., ge=15, le=25)
    Gender:            int   = Field(..., ge=0,  le=1)
    Ethnicity:         int   = Field(..., ge=0,  le=3)
    ParentalEducation: int   = Field(..., ge=0,  le=4)
    StudyTimeWeekly:   float = Field(..., ge=0.0, le=50.0)
    Absences:          int   = Field(..., ge=0,  le=100)
    Tutoring:          int   = Field(..., ge=0,  le=1)
    ParentalSupport:   int   = Field(..., ge=0,  le=4)
    Extracurricular:   int   = Field(..., ge=0,  le=1)
    Sports:            int   = Field(..., ge=0,  le=1)
    Music:             int   = Field(..., ge=0,  le=1)
    Volunteering:      int   = Field(..., ge=0,  le=1)

    class Config:
        json_schema_extra = {
            "example": {
                "Age": 17, "Gender": 1, "Ethnicity": 0,
                "ParentalEducation": 3, "StudyTimeWeekly": 15.5,
                "Absences": 4, "Tutoring": 1, "ParentalSupport": 3,
                "Extracurricular": 1, "Sports": 0, "Music": 1, "Volunteering": 0,
            }
        }

class PredictionResponse(BaseModel):
    predicted_GPA: float




def build_feature_row(data: StudentData) -> np.ndarray:
    study_efficiency = data.StudyTimeWeekly / (data.Absences + 1)
    engagement_score = (
        data.Extracurricular + data.Sports +
        data.Music + data.Volunteering + data.Tutoring
    )

    row = [
        data.Age, data.Gender, data.Ethnicity, data.ParentalEducation,
        data.StudyTimeWeekly, data.Absences, data.Tutoring, data.ParentalSupport,
        data.Extracurricular, data.Sports, data.Music, data.Volunteering,
        study_efficiency, engagement_score,
    ]

    return np.array([row])


# LOAD MODEL

def load_artifacts():
    if not os.path.exists(MODEL_PATH) or not os.path.exists(SCALER_PATH):
        raise HTTPException(status_code=500, detail="Model files not found. Run training first.")
    return joblib.load(MODEL_PATH), joblib.load(SCALER_PATH)


#  route for prediction

@app.post("/predict", response_model=PredictionResponse)
def predict(data: StudentData):
    model, scaler = load_artifacts()

    features        = build_feature_row(data)
    features_scaled = scaler.transform(features)

    prediction = float(model.predict(features_scaled)[0])
    prediction = round(max(0.0, min(4.0, prediction)), 4)

    return {"predicted_GPA": prediction}


#  route retrain

@app.post("/retrain")
async def retrain(file: UploadFile = File(...)):

    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Upload a CSV file.")

    contents = await file.read()
    df = pd.read_csv(io.BytesIO(contents))

    df = df.drop(["StudentID", "GradeClass"], axis=1, errors="ignore")

    df["StudyEfficiency"] = df["StudyTimeWeekly"] / (df["Absences"] + 1)
    df["EngagementScore"] = (
        df["Extracurricular"] + df["Sports"] +
        df["Music"] + df["Volunteering"] + df["Tutoring"]
    )

    if "GPA" not in df.columns:
        raise HTTPException(status_code=422, detail="CSV must contain 'GPA' column.")

    X = df[FEATURE_COLUMNS]
    y = df["GPA"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    scaler = StandardScaler()
    X_train_s = scaler.fit_transform(X_train)
    X_test_s  = scaler.transform(X_test)

    models = {
        "Linear Regression": LinearRegression(),
        "Decision Tree": DecisionTreeRegressor(max_depth=8, random_state=42),
        "Random Forest": RandomForestRegressor(n_estimators=200, random_state=42),
    }

    best_model = None
    best_mse   = float("inf")
    best_name  = ""

    for name, m in models.items():
        m.fit(X_train_s, y_train)
        mse = mean_squared_error(y_test, m.predict(X_test_s))

        if mse < best_mse:
            best_mse  = mse
            best_model = m
            best_name  = name

    joblib.dump(best_model, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)

    return {
        "message": "Model retrained successfully",
        "best_model": best_name,
        "mse": round(best_mse, 4),
    }