# Hospital Management Database — "Ygeiopolis" General Hospital

A relational database for managing a general hospital: staff, patients, admissions, triage, lab exams, surgeries, prescriptions and shift scheduling. It is loaded with **real Greek and EU medical reference data** and a **reproducible synthetic dataset**, and comes with a lightweight PHP web interface.

> Semester project for the *Databases* course, School of Electrical & Computer Engineering, National Technical University of Athens (NTUA), Spring 2026.
> Team: **Pavlos Markopoulos**, **Kyriaki Tertipi**

**Tech stack:** MariaDB 10.4 / MySQL (plain SQL, no ORM) · Python (pandas, openpyxl) · PHP · XAMPP · MySQL Workbench · draw.io

---

## Highlights

- **27-table normalized schema** with 27 primary keys, 42 foreign keys, 9 unique and 46 check constraints. Allowed values are enforced with `CHECK` constraints, not `ENUM`.
- **Business rules enforced by triggers.** Examples:
  - no prescription of a drug containing a substance the patient is allergic to;
  - no overlapping surgeries in the same operating room or for the same surgeon;
  - residents must have a supervising doctor;
  - patients can rate a stay only after they have been discharged.
- **Real reference data** from official sources, cleaned and loaded with `LOAD DATA LOCAL INFILE`:
  - 11,008 ICD-10 diagnoses, 694 DRG-equivalent codes (ΚΕΝ) and 6,608 medical procedures from the Greek Ministry of Health;
  - 4,697 drugs and 1,526 active substances, filtered for Greece from 161,785 records of the EMA Article 57 dataset.
- **Deterministic synthetic data generator** in Python (fixed seed). It produces 200 patients, 210 staff, 800 hospitalizations, 1,100 triage records, 1,660 shift assignments and more. The data respects constraints that span many rows, such as rest time between shifts, at most 3 consecutive night shifts, minimum staffing per shift and acyclic supervision chains.
- **15 analytical SQL queries.** They cover revenue per department and DRG, doctor workload and ratings, patients with repeated admissions, drug-substance co-prescription pairs, triage wait-time statistics and a **recursive CTE** for the supervision hierarchy.
- **Query optimization.** 49 indexes are designed around the query workload. Two key queries were analyzed with `EXPLAIN` / `EXPLAIN ANALYZE` against `FORCE INDEX` variants.
- **PHP web UI** for browsing doctors, patients, hospitalizations, lab exams, prescriptions, shifts and query results.

## Data model

![E/R diagram](diagrams/ER.png)

The relational schema is in [`diagrams/relational.png`](diagrams/relational.png), and the MySQL Workbench model is in [`diagrams/relational.mwb`](diagrams/relational.mwb).

## Repository structure

```text
├── code/
│   ├── generate_data.py      # synthetic data generator
│   └── web/                  # PHP web interface
├── diagrams/                 # E/R and relational diagrams
├── docs/                     # full report (PDF/DOCX) and detailed documentation (Greek)
└── sql/
    ├── install.sql           # schema: tables, constraints, indexes, triggers
    ├── load.sql              # loads reference + synthetic data
    ├── synthetic_data.sql    # generated INSERT statements
    ├── data/                 # reference CSVs (ICD-10, ΚΕΝ, procedures, lab exams, EMA drugs)
    └── Q01.sql … Q15.sql     # queries, with outputs in QXX_out.txt
```

## Running it locally

**Requirements:** XAMPP (MariaDB 10.4+, Apache, PHP) and Python 3.8+.

1. **Create the schema.** Run this from the repository root, using `cmd`:
   ```cmd
   C:\xampp\mysql\bin\mysql.exe -u root < sql\install.sql
   ```
2. **(Optional) Regenerate the synthetic data:**
   ```cmd
   python code\generate_data.py --data-dir sql\data --out sql\synthetic_data.sql
   ```
3. **Load the data.** First update the file paths inside `sql/load.sql` to your local folder. Then run:
   ```cmd
   C:\xampp\mysql\bin\mysql.exe -u root --local-infile=1 --default-character-set=utf8mb4 ygeiopolis_db
   ```
   ```sql
   SET GLOBAL local_infile = 1;
   SOURCE C:/xampp/htdocs/hospital-database/sql/load.sql;
   ```
4. **Run a query:**
   ```cmd
   C:\xampp\mysql\bin\mysql.exe -u root --default-character-set=utf8mb4 ygeiopolis_db < sql\Q01.sql
   ```
5. **Open the web UI.** Place the repository in `C:\xampp\htdocs\`, start Apache and MySQL, and visit
   `http://localhost/hospital-database/code/web/index.php`

## Documentation

- [`docs/README_el.md`](docs/README_el.md) covers the design decisions, the reasoning behind each index, the triggers and the parameters of every query (in Greek).
- [`docs/report.pdf`](docs/report.pdf) is the full project report, including the `EXPLAIN` analysis (in Greek).

All personal data in this repository is synthetic.
