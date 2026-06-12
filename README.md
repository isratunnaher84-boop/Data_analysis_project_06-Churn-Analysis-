# 📉 Telecom Customer Churn Analysis

End-to-end data analysis project on a telecom churn dataset of **2,666 customers** — identifying why customers leave and what the business can do about it.

---

## 📦 Dataset
 -2,666 rows, 20 features including usage metrics, plan details, customer service calls, and a churn label (14.55% positive rate).

---

## 🔄 Workflow

### 1. Data Cleaning — `churn_data_cleaning.ipynb` / `01_data_cleaning.py`
- Renamed all columns to snake_case
- Audited for nulls and duplicates (none found)
- Cast Yes/No plan columns to binary integers; Churn bool → int
- Applied IQR × 3 outlier clamping on all usage/charge columns
- Engineered 5 derived features: `total_charge`, `total_minutes`, `spend_tier`, `high_cs_calls`, `risk_score`

### 2. Analysis — `02_churn_analysis.sql`
Six business questions answered with MySQL, cross-checked against pandas:

| # | Question |
|---|---|
| Q1 | What is the overall churn rate? |
| Q2 | Which customer segments churn the most? |
| Q3 | Does the International Plan increase churn? |
| Q4 | How do customer service calls impact churn? |
| Q5 | Are high-value customers more likely to churn? |
| Q6 | What customer profile is most likely to churn? |

**Headline results:** International Plan holders churn at **43.7%** (3.9× baseline). Customers with 4+ service calls churn at **52.9%**. The highest-risk composite profile hits **80.0%** churn.

### 3. Report — `Churn_Analysis_Report.docx`
Fully formatted Word report covering the complete analysis — KPI summary, 9 embedded visualisations, data tables, findings per question, and 7 prioritised business recommendations.

---

## 🛠 Tech Stack
`Python` · `pandas` · `MySQL` · `Matplotlib` · `Seaborn` · `Jupyter Notebook`


