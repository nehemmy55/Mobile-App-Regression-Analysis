# Student Academic Performance Predictor

## Mission
To increase access to quality tech education for young Africans by building inclusive tech academies equipped with the best tutoring tools, empowering the next generation of African innovators through data-driven learning support systems.

## Dataset
**Source:** [Kaggle — Student Performance Factors](https://www.kaggle.com/datasets/lainguyn123/student-performance-factors)  
**Description:** 2,392 student records with 14 features covering study habits (weekly study time, absences), support systems (tutoring, parental support, parental education), and extracurricular engagement (sports, music, volunteering). Target variable is GPA on a 0.0–4.0 scale. All features are numerically pre-encoded — no additional label encoding required.

---

## Repository Structure

```
linear_regression_model/
│
├── summative/
│   ├── linear_regression/
│   │   └── multivariate.ipynb       # Full ML pipeline notebook
│   ├── API/                         # To be completed — Task 2
│   └── FlutterApp/                  # To be completed — Task 3
```

---

## Notebook Pipeline

| Step | Description |
|------|-------------|
| 1 | Import libraries |
| 2 | Load & explore dataset |
| 3 | Visualizations — correlation heatmap + EDA plots |
| 4 | Feature engineering (`StudyEfficiency`, `EngagementScore`) |
| 5 | Prepare features (X) and target (y) |
| 6 | Train / test split (80/20) |
| 7 | Standardize data with `StandardScaler` |
| 8 | Linear Regression model |
| 9 | Decision Tree Regressor |
| 10 | Random Forest Regressor |
| 11 | Gradient Descent loss curve (SGDRegressor) |
| 12 | Scatter plot — before vs after training with fitted line |
| 13 | Model comparison (MSE, RMSE, R²) |
| 14 | Save best model (`joblib`) |
| 15 | Prediction script — one test row |

---

## Visualizations

**1. Correlation Heatmap**  
Reveals feature relationships with GPA. `Absences` shows the strongest negative correlation; `StudyTimeWeekly` shows the strongest positive correlation. `GradeClass` is dropped due to data leakage.

**2. EDA Panel (6 plots)**  
- GPA distribution histogram  
- Absences vs GPA scatter with trend line  
- Weekly study time vs GPA scatter with trend line  
- GPA by parental support level (box plot)  
- GPA by tutoring status (box plot)  
- Weekly study time distribution histogram  

---

## Models & Results

| Model | Role |
|-------|------|
| Linear Regression | Interpretable baseline |
| Decision Tree | Non-linear single-tree model |
| **Random Forest** | **Best performer — lowest test MSE** |

The best model is automatically selected by lowest test MSE and saved for use in the API.

---

## Engineered Features

| Feature | Formula |
|---------|---------|
| `StudyEfficiency` | `StudyTimeWeekly / (Absences + 1)` |
| `EngagementScore` | Sum of Extracurricular + Sports + Music + Volunteering + Tutoring |

---

## Key Findings
- `Absences` and `StudyTimeWeekly` are the strongest predictors of GPA
- `StudyEfficiency` captures the combined impact of study time and attendance
- `ParentalSupport` and `Tutoring` meaningfully improve academic outcomes
- Random Forest consistently outperforms Linear Regression and Decision Tree

---

## How to Run

```bash
pip install pandas numpy matplotlib seaborn scikit-learn joblib
jupyter notebook summative/linear_regression/multivariate.ipynb
```

> Place `Student_performance_data__.csv` in the same directory as the notebook before running.

## Saved Files

| File | Description |
|------|-------------|
| `best_student_gpa_model.pkl` | Best performing model (used by API in Task 2) |
| `scaler.pkl` | Fitted StandardScaler (must be used with Linear Regression) |