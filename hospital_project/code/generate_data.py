#!/usr/bin/env python3
"""
generate_data.py
================

Παράγει synthetic data για τη βάση `ygeiopolis_db`, σεβόμενο όλους τους
περιορισμούς (CHECKs, triggers) που ορίζονται στο install.sql.

Διαβάζει τα reference CSVs (icd10, ken, procedures, drugs, substances)
από το `--data-dir` και γράφει ένα SQL αρχείο με INSERTs στο `--out`.
ss
Χρήση:
    python generate_data.py
    python generate_data.py --data-dir sql/data --out sql/synthetic_data.sql

Reproducible με seed = 42.
"""
import argparse
import csv
import random
from datetime import date, datetime, time, timedelta
from pathlib import Path

# ---------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------
SEED = 42

# Counts (από εκφώνηση: «ενδεικτικά»)
N_DOCTORS = 80
N_NURSES  = 100   # extra για κάλυψη βαρδιών
N_ADMINS  = 30
N_PATIENTS = 200
N_HOSPITALIZATIONS = 800
N_PRESCRIPTIONS = 300
N_LAB_EXAMS = 200
N_PROC_ROOMS = 10
N_PROC_OCCURRENCES = 280
N_DEPARTMENTS = 15
N_BEDS_PER_DEPT_RANGE = (8, 20)
N_TRIAGE_EXTRA = 300  # επιπλέον triage records που δεν οδηγούν σε νοσηλεία

# Hospitalization date range (για να έχουμε στοιχεία για Q1, Q14)
HOSP_DATE_FROM = date(2022, 1, 1)
HOSP_DATE_TO   = date(2026, 4, 1)

# Shift week — full coverage σε αυτή τη βδομάδα
SHIFT_WEEK_START = date(2026, 3, 2)   # Δευτέρα
SHIFT_WEEK_DAYS  = 7

# ---------------------------------------------------------------
# Greek names & lookup data
# ---------------------------------------------------------------
GREEK_FIRST_M = ["Γιώργος", "Νίκος", "Δημήτρης", "Κώστας", "Παναγιώτης",
                 "Γιάννης", "Χρήστος", "Στέλιος", "Μιχάλης", "Θανάσης",
                 "Σταύρος", "Πέτρος", "Ανδρέας", "Σπύρος", "Βασίλης"]
GREEK_FIRST_F = ["Μαρία", "Ελένη", "Σοφία", "Κατερίνα", "Άννα",
                 "Γεωργία", "Ευαγγελία", "Δήμητρα", "Ιωάννα", "Παρασκευή",
                 "Χριστίνα", "Βασιλική", "Αθηνά", "Νίκη", "Αλεξάνδρα"]
GREEK_LAST_M = ["Παπαδόπουλος", "Κωνσταντίνου", "Νικολάου",
              "Γεωργίου", "Δημητρίου", "Ιωαννίδης", "Αντωνίου",
              "Παππάς", "Μακρής", "Καραγιάννης",
              "Αθανασίου", "Σταυρόπουλος", "Βασιλείου",
              "Οικονόμου", "Καρράς", "Θεοδώρου", "Σπυρίδων",
              "Λεωνίδου", "Πετρίδης"]

GREEK_LAST_F = ["Παπαδοπούλου", "Ιωαννίδου", "Καραγιάννη", "Μακρή", "Παππά",
              "Σταυροπούλου", "Καρρά", "Κωνσταντίνου", "Νικολάου",
              "Γεωργίου", "Δημητρίου", "Αντωνίου", "Αθανασίου", "Βασιλείου",
              "Οικονόμου", "Θεοδώρου", "Λεωνίδου", "Πετρίδου"]

SPECIALTIES = ["Καρδιολογία", "Χειρουργική", "Παθολογία", "Ορθοπεδική",
               "Νευρολογία", "Παιδιατρική", "Γυναικολογία", "Ουρολογία",
               "Δερματολογία", "Ψυχιατρική", "Ακτινολογία", "Αναισθησιολογία",
               "ΩΡΛ", "Οφθαλμολογία", "Πνευμονολογία"]

DOCTOR_RANKS = ["Ειδικευόμενος", "Επιμελητής Β", "Επιμελητής Α", "Διευθυντής"]
NURSE_RANKS = ["Βοηθός Νοσηλευτή", "Νοσηλευτής", "Προϊστάμενος"]
ADMIN_ROLES = ["Γραμματέας", "Λογιστής", "Διαχειριστής Αρχείων",
               "Υπεύθυνος Λογιστηρίου Ασθενών", "Υπεύθυνος Προμηθειών"]

DEPARTMENT_NAMES = ["Καρδιολογία", "Χειρουργική", "Παθολογία", "ΜΕΘ",
                    "Επείγοντα", "Ορθοπεδική", "Νευρολογία", "Παιδιατρική",
                    "Γυναικολογία", "Ουρολογία", "Δερματολογία", "Ψυχιατρική",
                    "Ακτινολογία", "ΩΡΛ", "Οφθαλμολογία"]

INSURANCE_PROVIDERS = ["ΕΦΚΑ", "Ιδιωτική", "Ανασφάλιστος", "ΕΟΠΥΥ"]
GENDERS = ["Άνδρας", "Γυναίκα"]
NATIONALITIES = ["Ελληνική", "Αλβανική", "Γερμανική", "Βουλγαρική",
                 "Ρουμανική", "Ιταλική"]
OCCUPATIONS = ["Δημόσιος Υπάλληλος", "Ιδιωτικός Υπάλληλος", "Ελεύθερος Επαγγελματίας",
               "Συνταξιούχος", "Φοιτητής", "Άνεργος", "Εκπαιδευτικός",
               "Επιχειρηματίας", "Αγρότης"]

BED_TYPES = ["μονόκλινο", "πολύκλινο", "ΜΕΘ"]
ROOM_TYPES = ["χειρουργείο", "αίθουσα επέμβασης"]

# Lab exam types loaded from lab_exams.csv (Κατηγορίες Γ, Δ, Ε)

PROCEDURE_PARTICIPATION_ROLES = ["assistant_doctor", "assistant_nurse",
                                   "anesthesiologist", "other"]

# ---------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------
def sql_str(s):
    """Escape string for SQL."""
    if s is None:
        return "NULL"
    return "'" + str(s).replace("\\", "\\\\").replace("'", "''") + "'"

def sql_val(v):
    if v is None:
        return "NULL"
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, datetime):
        return sql_str(v.isoformat(sep=" "))
    if isinstance(v, date):
        return sql_str(v.isoformat())
    return sql_str(v)

def random_amka(used: set) -> int:
    while True:
        amka = random.randint(10000000000, 99999999999)
        if amka not in used:
            used.add(amka)
            return amka

def random_phone() -> str:
    return "69" + "".join(str(random.randint(0, 9)) for _ in range(8))

def random_email(first, last, domain="ygeiopolis.gr") -> str:
    base = (first[:3] + last[:5]).lower()
    return f"{base}{random.randint(100, 999)}@{domain}"

def random_date_between(d1: date, d2: date) -> date:
    delta = (d2 - d1).days
    return d1 + timedelta(days=random.randint(0, delta))

def random_datetime_between(d1: date, d2: date) -> datetime:
    base = random_date_between(d1, d2)
    return datetime.combine(base, time(random.randint(0, 23),
                                       random.randint(0, 59)))

# ---------------------------------------------------------------
# Reference data loading
# ---------------------------------------------------------------
def load_reference(data_dir: Path):
    """
    Load all reference CSVs and return their identifier lists.
    """
    def read_csv(name, sep=","):
        path = data_dir / name
        if not path.exists():
            raise FileNotFoundError(f"Missing reference file: {path}")
        with open(path, encoding="utf-8") as f:
            return list(csv.DictReader(f, delimiter=sep))

    icd10 = [r["icd10_code"].strip() for r in read_csv("icd10.csv")]
    ken   = [r["ken_code"].strip()   for r in read_csv("ken.csv")]
    procs = [r["procedure_code"].strip() for r in read_csv("procedures.csv")]

    # Lab exam types from Ministry of Health (Categories Γ, Δ, Ε)
    lab_exam_codes = [r["exam_code"].strip() for r in read_csv("lab_exams.csv")]

    # For drugs we keep the substance mapping in memory
    drugs = [r["drug_id"].strip() for r in read_csv("drugs.csv")]

    # Substances: we need to know IDs. Active_substance gets AUTO_INCREMENT IDs
    # from the load.sql (LOAD DATA INFILE). Since IDs are sequential starting at 1,
    # we'll re-derive them by reading the CSV and matching by name order.
    subs_rows = read_csv("active_substances.csv")
    substance_name_to_id = {}
    for idx, row in enumerate(subs_rows, start=1):
        substance_name_to_id[row["substance_name"].strip()] = idx

    # drug_active_substance: list of (drug_id, substance_id) tuples
    drug_to_subs = {}
    for r in read_csv("drug_active_substance.csv"):
        d_id = r["drug_id"].strip()
        s_name = r["substance_name"].strip()
        if s_name in substance_name_to_id and d_id in set(drugs):
            drug_to_subs.setdefault(d_id, set()).add(substance_name_to_id[s_name])

    print(f"  Loaded: {len(icd10)} ICD10, {len(ken)} KEN, {len(procs)} procedures, "
          f"{len(drugs)} drugs, {len(subs_rows)} substances, "
          f"{len(lab_exam_codes)} lab exam types")

    return {
        "icd10": icd10,
        "ken": ken,
        "procedures": procs,
        "drugs": drugs,
        "substances_by_name": substance_name_to_id,
        "drug_to_subs": drug_to_subs,
        "lab_exam_codes": lab_exam_codes,
    }

# ---------------------------------------------------------------
# Generators
# ---------------------------------------------------------------
def gen_departments():
    """15 departments. director_amka is set later (after doctors exist)."""
    departments = []
    for i, name in enumerate(DEPARTMENT_NAMES[:N_DEPARTMENTS], start=1):
        departments.append({
            "department_id": i,
            "name": name,
            "description": f"Τμήμα {name}",
            "floor_building": f"Όροφος {random.randint(1, 6)}, Κτήριο {random.choice(['A', 'B', 'Γ'])}",
            "director_amka": None,  # filled later
        })
    return departments


def gen_staff_and_subtypes(departments):
    """
    Generates staff + doctor + nurse + admin_staff rows.
    Doctors are created first to have AMKA pool for supervisors and directors.
    """
    used_amka = set()
    staff = []
    doctors = []
    nurses = []
    admins = []

    # ----- Doctors -----
    # Distribution of ranks (realistic):
    #   25% Ειδικευόμενος, 30% Επιμελητής Β, 30% Επιμελητής Α, 15% Διευθυντής
    rank_dist = (["Ειδικευόμενος"] * round(N_DOCTORS * 0.25) +
                 ["Επιμελητής Β"]   * round(N_DOCTORS * 0.30) +
                 ["Επιμελητής Α"]   * round(N_DOCTORS * 0.30) +
                 ["Διευθυντής"]     * round(N_DOCTORS * 0.15))
    # Ensure exactly N_DOCTORS
    while len(rank_dist) < N_DOCTORS:
        rank_dist.append("Επιμελητής Α")
    rank_dist = rank_dist[:N_DOCTORS]
    random.shuffle(rank_dist)

    # Build doctors but assign supervisor only after all are known
    doctor_buffer = []
    for i in range(N_DOCTORS):
        amka = random_amka(used_amka)
        gender_male = random.random() < 0.5
        first = random.choice(GREEK_FIRST_M if gender_male else GREEK_FIRST_F)
        last  = random.choice(GREEK_LAST_M if gender_male else GREEK_LAST_F)
        rank = rank_dist[i]
        # Age depends on rank
        if rank == "Ειδικευόμενος":
            age = random.randint(28, 35)
        elif rank == "Επιμελητής Β":
            age = random.randint(35, 45)
        elif rank == "Επιμελητής Α":
            age = random.randint(40, 55)
        else:
            age = random.randint(50, 65)
        hire_date = date.today() - timedelta(days=random.randint(365, 365*20))

        staff.append({
            "amka": amka, "first_name": first, "last_name": last,
            "age": age, "email": random_email(first, last),
            "phone": random_phone(), "hire_date": hire_date,
            "staff_type": "doctor",
        })
        doctor_buffer.append({
            "amka": amka,
            "licence_number": f"L{random.randint(10000, 99999)}-{i}",
            "specialty": random.choice(SPECIALTIES),
            "rank": rank,
            "supervisor_amka": None,  # filled below
        })

    # Assign supervisors
    seniors = [d["amka"] for d in doctor_buffer
               if d["rank"] in ("Επιμελητής Α", "Διευθυντής")]
    if not seniors:
        # fallback: pick any non-Ειδικευόμενος
        seniors = [d["amka"] for d in doctor_buffer if d["rank"] != "Ειδικευόμενος"]

    for d in doctor_buffer:
        if d["rank"] == "Ειδικευόμενος":
            # MUST have supervisor (Επιμελητής Α or Διευθυντής per spec)
            d["supervisor_amka"] = random.choice(seniors)
        elif d["rank"] in ("Επιμελητής Β", "Επιμελητής Α"):
            # Optional supervisor — pick a more senior doctor 50% of the time
            if random.random() < 0.5:
                pool = [s for s in seniors if s != d["amka"]]
                if pool:
                    d["supervisor_amka"] = random.choice(pool)
        # Διευθυντής: NEVER has supervisor (enforced by trigger)
    doctors = doctor_buffer

    # ----- Nurses -----
    for i in range(N_NURSES):
        amka = random_amka(used_amka)
        gender_male = random.random() < 0.2
        first = random.choice(GREEK_FIRST_M if gender_male else GREEK_FIRST_F)
        last  = random.choice(GREEK_LAST_M if gender_male else GREEK_LAST_F)
        age = random.randint(22, 60)
        hire_date = date.today() - timedelta(days=random.randint(180, 365*15))
        staff.append({
            "amka": amka, "first_name": first, "last_name": last,
            "age": age, "email": random_email(first, last),
            "phone": random_phone(), "hire_date": hire_date,
            "staff_type": "nurse",
        })
        nurses.append({
            "amka": amka,
            "nurse_rank": random.choice(NURSE_RANKS),
            "department_id": random.choice(departments)["department_id"],
        })

    # ----- Admins -----
    for i in range(N_ADMINS):
        amka = random_amka(used_amka)
        gender_male = random.random() < 0.5
        first = random.choice(GREEK_FIRST_M if gender_male else GREEK_FIRST_F)
        last  = random.choice(GREEK_LAST_M if gender_male else GREEK_LAST_F)
        age = random.randint(25, 65)
        hire_date = date.today() - timedelta(days=random.randint(180, 365*15))
        staff.append({
            "amka": amka, "first_name": first, "last_name": last,
            "age": age, "email": random_email(first, last),
            "phone": random_phone(), "hire_date": hire_date,
            "staff_type": "admin",
        })
        admins.append({
            "amka": amka,
            "role": random.choice(ADMIN_ROLES),
            "office": f"Γραφείο {random.randint(101, 599)}",
            "department_id": random.choice(departments)["department_id"],
        })

    # Assign directors (one per department, must be Διευθυντής or Επιμελητής Α)
    director_pool = [d for d in doctors
                     if d["rank"] in ("Διευθυντής", "Επιμελητής Α")]
    random.shuffle(director_pool)
    for i, dept in enumerate(departments):
        if i < len(director_pool):
            dept["director_amka"] = director_pool[i]["amka"]
        else:
            dept["director_amka"] = director_pool[i % len(director_pool)]["amka"]

    return staff, doctors, nurses, admins


def gen_doctor_department(doctors, departments):
    """Each doctor → 1-2 departments, biased by specialty match."""
    rows = []
    seen = set()
    for d in doctors:
        n_depts = random.choice([1, 1, 1, 2])
        # Try to match specialty to department name
        matched = [dept for dept in departments if dept["name"] == d["specialty"]]
        chosen = list(matched)
        # Fill the rest with random
        while len(chosen) < n_depts:
            cand = random.choice(departments)
            if cand not in chosen:
                chosen.append(cand)
        for dept in chosen:
            key = (d["amka"], dept["department_id"])
            if key not in seen:
                seen.add(key)
                rows.append({"doctor_amka": d["amka"],
                             "department_id": dept["department_id"]})
    return rows


def gen_beds(departments):
    beds = []
    bed_id = 1
    for dept in departments:
        n = random.randint(*N_BEDS_PER_DEPT_RANGE)
        for j in range(1, n + 1):
            beds.append({
                "bed_id": bed_id,
                "bed_number": f"{dept['department_id']:02d}-{j:03d}",
                "bed_type": random.choices(BED_TYPES, weights=[2, 5, 1])[0],
                "status": random.choices(
                    ["available", "occupied", "maintenance"],
                    weights=[6, 3, 1])[0],
                "department_id": dept["department_id"],
            })
            bed_id += 1
    return beds


def gen_patients():
    used = set()
    patients = []
    for _ in range(N_PATIENTS):
        amka = random_amka(used)
        gender = random.choice(GENDERS)
        first = random.choice(GREEK_FIRST_M if gender == "Άνδρας" else GREEK_FIRST_F)
        last = random.choice(GREEK_LAST_M if gender == "Άνδρας" else GREEK_LAST_F)
        father = random.choice(GREEK_FIRST_M)
        patients.append({
            "amka": amka,
            "first_name": first, "last_name": last, "father_name": father,
            "age": random.randint(0, 95),
            "gender": gender,
            "weight": round(random.uniform(50.0, 110.0), 1),
            "height": round(random.uniform(1.50, 1.95), 2),
            "address": f"Οδός {random.choice(['Ερμού','Σταδίου','Πανεπιστημίου','Πατησίων'])} {random.randint(1, 200)}",
            "phone": random_phone(),
            "email": random_email(first, last, "gmail.com"),
            "occupation": random.choice(OCCUPATIONS),
            "nationality": random.choice(NATIONALITIES),
            "insurance_provider": random.choice(INSURANCE_PROVIDERS),
        })
    return patients


def gen_patient_contacts(patients):
    rows = []
    cid = 1
    for p in patients:
        for _ in range(random.choice([1, 1, 2])):
            gender_male = random.random() < 0.5
            first = random.choice(GREEK_FIRST_M if gender_male else GREEK_FIRST_F)
            last = random.choice(GREEK_LAST_M if gender_male else GREEK_LAST_F)
            rows.append({
                "contact_id": cid,
                "patient_amka": p["amka"],
                "full_name": f"{first} {last}",
                "phone": random_phone(),
                "relationship": random.choice(["Σύζυγος", "Γονιός", "Παιδί",
                                               "Αδερφός/-ή", "Φίλος/-η"]),
                "notes": None,
            })
            cid += 1
    return rows


def gen_patient_allergies(patients, substances_by_name):
    """~30% of patients have 1-2 allergies."""
    if not substances_by_name:
        return []
    sub_ids = list(substances_by_name.values())
    rows = []
    seen = set()
    for p in patients:
        if random.random() < 0.30:
            for _ in range(random.choice([1, 1, 2])):
                sid = random.choice(sub_ids)
                key = (p["amka"], sid)
                if key not in seen:
                    seen.add(key)
                    rows.append({
                        "patient_amka": p["amka"],
                        "substance_id": sid,
                        "notes": random.choice([None, "Σοβαρή αντίδραση",
                                                "Ήπια ερυθρότητα"]),
                    })
    return rows


def gen_triage_records(patients, nurses, departments):
    """
    Generates triage records. Returns:
      - records (list of dicts)
      - hospitalized_triage_amkas: list of patient_amka for those hospitalized
        (drives hospitalization generation)

    Strategy: ~15% of patients are "frequent flyers" with a preferred department.
    They get 4-6 hospitalizations in that same department, ensuring Q3 returns
    meaningful results (patients with > 3 hospitalizations in same department).
    """
    rows = []
    hospitalized_pairs = []
    tid = 1
    nurse_amkas = [n["amka"] for n in nurses]
    dept_ids = [d["department_id"] for d in departments]

    # Pick ~15% of patients as "frequent flyers" with a preferred department
    n_frequent = max(1, int(len(patients) * 0.15))
    frequent_flyers = random.sample(patients, n_frequent)
    frequent_flyer_dept = {p["amka"]: random.choice(dept_ids) for p in frequent_flyers}
    frequent_flyer_amkas = set(frequent_flyer_dept.keys())

    # First, generate hospitalizations for frequent flyers (4-6 each in same dept)
    for p in frequent_flyers:
        n_visits = random.randint(4, 6)
        preferred_dept = frequent_flyer_dept[p["amka"]]
        for _ in range(n_visits):
            if len(hospitalized_pairs) >= N_HOSPITALIZATIONS:
                break
            arrival = random_datetime_between(date(2022, 1, 1), date(2026, 4, 1))
            decision = arrival + timedelta(minutes=random.randint(15, 240))
            urgency = random.choices([1, 2, 3, 4, 5], weights=[5, 15, 30, 30, 20])[0]
            rows.append({
                "triage_id": tid,
                "patient_amka": p["amka"],
                "nurse_amka": random.choice(nurse_amkas),
                "arrival_time": arrival,
                "symptoms": random.choice([
                    "Πόνος στο στήθος", "Δύσπνοια", "Πυρετός",
                    "Κοιλιακό άλγος", "Κεφαλαλγία", "Τραυματισμός",
                    "Ζάλη", "Έμετος",
                ]),
                "urgency_level": urgency,
                "outcome": "hospitalized",
                "decision_time": decision,
                "referred_department_id": preferred_dept,
            })
            hospitalized_pairs.append((p["amka"], preferred_dept, decision))
            tid += 1

    # Then fill the rest with random triage records
    n_total_remaining = (N_HOSPITALIZATIONS + N_TRIAGE_EXTRA) - len(rows)
    for _ in range(max(0, n_total_remaining)):
        p = random.choice(patients)
        nurse_amka = random.choice(nurse_amkas)
        arrival = random_datetime_between(date(2022, 1, 1), date(2026, 4, 1))
        decision = arrival + timedelta(minutes=random.randint(15, 240))
        urgency = random.choices([1, 2, 3, 4, 5], weights=[5, 15, 30, 30, 20])[0]
        outcome = random.choices(["hospitalized", "discharged"],
                                 weights=[70, 30])[0]
        ref_dept = random.choice(dept_ids) if outcome == "hospitalized" else None

        rows.append({
            "triage_id": tid,
            "patient_amka": p["amka"],
            "nurse_amka": nurse_amka,
            "arrival_time": arrival,
            "symptoms": random.choice([
                "Πόνος στο στήθος", "Δύσπνοια", "Πυρετός",
                "Κοιλιακό άλγος", "Κεφαλαλγία", "Τραυματισμός",
                "Ζάλη", "Έμετος",
            ]),
            "urgency_level": urgency,
            "outcome": outcome,
            "decision_time": decision,
            "referred_department_id": ref_dept,
        })

        if outcome == "hospitalized" and len(hospitalized_pairs) < N_HOSPITALIZATIONS:
            hospitalized_pairs.append((p["amka"], ref_dept, decision))
        tid += 1

    # If we don't have enough hospitalized triages, pad with extras
    while len(hospitalized_pairs) < N_HOSPITALIZATIONS:
        p = random.choice(patients)
        d = random.choice(dept_ids)
        t = random_datetime_between(date(2022, 1, 1), date(2026, 4, 1))
        hospitalized_pairs.append((p["amka"], d, t))

    return rows, hospitalized_pairs[:N_HOSPITALIZATIONS]


def gen_hospitalizations(hospitalized_pairs, beds, doctors, ref):
    """Generate 500 hospitalizations."""
    rows = []
    beds_by_dept = {}
    for b in beds:
        beds_by_dept.setdefault(b["department_id"], []).append(b["bed_id"])

    doctor_amkas = [d["amka"] for d in doctors]

    for hid, (patient_amka, dept_id, triage_time) in enumerate(hospitalized_pairs, 1):
        if dept_id is None:
            dept_id = random.choice(list(beds_by_dept.keys()))
        bed_id = random.choice(beds_by_dept[dept_id])

        adm = triage_time if isinstance(triage_time, datetime) \
              else random_datetime_between(HOSP_DATE_FROM, HOSP_DATE_TO)

        # 90% have discharge date (10% still hospitalized)
        if random.random() < 0.90:
            stay_days = random.randint(1, 30)
            disc = adm + timedelta(days=stay_days,
                                   hours=random.randint(1, 23))
        else:
            disc = None

        ken_code = random.choice(ref["ken"])
        adm_icd  = random.choice(ref["icd10"])
        disc_icd = random.choice(ref["icd10"]) if disc else None

        # total_cost: simplified — base cost from KEN-like range
        if disc:
            total = round(random.uniform(800, 8000), 2)
        else:
            total = None

        rows.append({
            "hospitalization_id": hid,
            "patient_amka": patient_amka,
            "department_id": dept_id,
            "bed_id": bed_id,
            "ken_code": ken_code,
            "admission_icd10_code": adm_icd,
            "discharge_icd10_code": disc_icd,
            "admission_date": adm,
            "discharge_date": disc,
            "total_cost": total,
            "primary_doctor_amka": random.choice(doctor_amkas),
        })
    return rows


def gen_ratings(hospitalizations):
    """Only for hospitalizations with discharge_date."""
    rows = []
    rid = 1
    for h in hospitalizations:
        if h["discharge_date"] is not None and random.random() < 0.80:
            rows.append({
                "rating_id": rid,
                "hospitalization_id": h["hospitalization_id"],
                "medical_care_score":      random.randint(1, 5),
                "nursing_care_score":      random.randint(1, 5),
                "cleanliness_score":       random.randint(1, 5),
                "food_score":              random.randint(1, 5),
                "overall_experience_score": random.randint(1, 5),
            })
            rid += 1
    return rows


def gen_lab_exams(hospitalizations, doctors, lab_exam_codes):
    rows = []
    doctor_amkas = [d["amka"] for d in doctors]
    for eid in range(1, N_LAB_EXAMS + 1):
        h = random.choice(hospitalizations)
        # Date within hospitalization period
        if h["discharge_date"]:
            exam_date = h["admission_date"] + timedelta(
                seconds=random.randint(
                    0, int((h["discharge_date"] - h["admission_date"]).total_seconds())))
        else:
            exam_date = h["admission_date"] + timedelta(hours=random.randint(1, 240))
        rows.append({
            "exam_id": eid,
            "hospitalization_id": h["hospitalization_id"],
            "doctor_amka": random.choice(doctor_amkas),
            "exam_code": random.choice(lab_exam_codes),  # πραγματικός κωδικός από CSV
            "exam_date": exam_date,
            "result_text": random.choice(["Φυσιολογικό", "Παθολογικό",
                                           "Οριακό", None]),
            "numeric_value": round(random.uniform(0.5, 200.0), 2)
                              if random.random() < 0.7 else None,
            "unit": random.choice(["mg/dL", "mmol/L", "%", "U/L", None]),
            "cost": round(random.uniform(20, 200), 2),
        })
    return rows


def gen_procedure_rooms():
    rows = []
    for i in range(1, N_PROC_ROOMS + 1):
        rows.append({
            "room_id": i,
            "room_name": f"Αίθουσα {i}",
            "room_type": random.choice(ROOM_TYPES),
        })
    return rows


def gen_procedure_occurrences(hospitalizations, doctors, rooms, ref):
    """
    Generates procedure_occurrence rows respecting:
      - No two procedures in same room overlap in time
      - Same surgeon not in two procedures simultaneously
    """
    rows = []
    room_schedule = {r["room_id"]: [] for r in rooms}        # list of (start, end)
    surgeon_schedule = {d["amka"]: [] for d in doctors}      # list of (start, end)
    doctor_amkas = [d["amka"] for d in doctors]

    attempts = 0
    oid = 1
    while oid <= N_PROC_OCCURRENCES and attempts < N_PROC_OCCURRENCES * 10:
        attempts += 1
        h = random.choice(hospitalizations)
        if h["discharge_date"] is None:
            continue

        room_id = random.choice([r["room_id"] for r in rooms])
        surgeon = random.choice(doctor_amkas)
        # Procedure window inside hospitalization
        max_seconds = int((h["discharge_date"] - h["admission_date"]).total_seconds())
        if max_seconds < 7200:
            continue
        offset = random.randint(0, max(0, max_seconds - 7200))
        start = h["admission_date"] + timedelta(seconds=offset)
        duration = timedelta(minutes=random.randint(30, 240))
        end = start + duration

        # Conflict checks
        def overlap(busy, s, e):
            return any(not (e <= bs or s >= be) for bs, be in busy)

        if overlap(room_schedule[room_id], start, end):
            continue
        if overlap(surgeon_schedule[surgeon], start, end):
            continue

        rows.append({
            "occurrence_id": oid,
            "hospitalization_id": h["hospitalization_id"],
            "procedure_code": random.choice(ref["procedures"]),
            "room_id": room_id,
            "main_surgeon_amka": surgeon,
            "start_datetime": start,
            "end_datetime": end,
        })
        room_schedule[room_id].append((start, end))
        surgeon_schedule[surgeon].append((start, end))
        oid += 1

    # ------------------------------------------------------------------
    # Guarantee data for Q11.
    # Q11 asks for doctors who performed at least 5 fewer procedures than
    # the doctor with the most procedures in the selected year.
    # Pure random generation may distribute procedures too evenly, so the
    # query can correctly return no rows. To make the dataset suitable for
    # the assignment, we intentionally boost one surgeon in the latest year
    # with enough procedure data, while still respecting the overlap triggers.
    # ------------------------------------------------------------------
    from collections import Counter

    year_counts = Counter(r["start_datetime"].year for r in rows)
    eligible_years = [y for y, c in year_counts.items() if c >= 30]
    if eligible_years:
        target_year = max(eligible_years)

        surgeon_counts = Counter(
            r["main_surgeon_amka"]
            for r in rows
            if r["start_datetime"].year == target_year
        )

        if surgeon_counts:
            top_surgeon, current_top = surgeon_counts.most_common(1)[0]
            desired_top = current_top + 6

            candidate_hospitalizations = [
                h for h in hospitalizations
                if h["discharge_date"] is not None
                and h["admission_date"].year <= target_year <= h["discharge_date"].year
            ]

            def overlap(busy, s, e):
                return any(not (e <= bs or s >= be) for bs, be in busy)

            extra_added = 0
            max_extra_attempts = 5000

            for _ in range(max_extra_attempts):
                if current_top + extra_added >= desired_top:
                    break
                if not candidate_hospitalizations:
                    break

                h = random.choice(candidate_hospitalizations)
                room_id = random.choice([r["room_id"] for r in rooms])

                # Pick a date within the hospitalization and within target_year.
                start_bound = max(h["admission_date"], datetime(target_year, 1, 1, 7, 0, 0))
                end_bound = min(h["discharge_date"], datetime(target_year, 12, 31, 18, 0, 0))
                if end_bound <= start_bound + timedelta(hours=2):
                    continue

                max_seconds = int((end_bound - start_bound).total_seconds())
                offset = random.randint(0, max_seconds - 7200)
                start = start_bound + timedelta(seconds=offset)
                end = start + timedelta(hours=2)

                if overlap(room_schedule[room_id], start, end):
                    continue
                if overlap(surgeon_schedule[top_surgeon], start, end):
                    continue

                rows.append({
                    "occurrence_id": oid,
                    "hospitalization_id": h["hospitalization_id"],
                    "procedure_code": random.choice(ref["procedures"]),
                    "room_id": room_id,
                    "main_surgeon_amka": top_surgeon,
                    "start_datetime": start,
                    "end_datetime": end,
                })
                room_schedule[room_id].append((start, end))
                surgeon_schedule[top_surgeon].append((start, end))
                oid += 1
                extra_added += 1

    return rows


def gen_procedure_participations(occurrences, staff_all):
    """1-3 assistants per occurrence (different from main surgeon)."""
    rows = []
    seen = set()
    for occ in occurrences:
        n_assistants = random.choice([1, 1, 2, 3])
        candidates = [s["amka"] for s in staff_all
                      if s["amka"] != occ["main_surgeon_amka"]]
        chosen = random.sample(candidates, min(n_assistants, len(candidates)))
        for amka in chosen:
            key = (occ["occurrence_id"], amka)
            if key in seen:
                continue
            seen.add(key)
            rows.append({
                "occurrence_id": occ["occurrence_id"],
                "staff_amka": amka,
                "role_in_procedure": random.choice(PROCEDURE_PARTICIPATION_ROLES),
            })
    return rows


def gen_prescriptions(hospitalizations, doctors, allergies, ref):
    """
    Generate 300 prescriptions, avoiding allergy conflicts.
    """
    # Build allergy lookup: patient_amka -> set of substance_ids
    patient_allergies = {}
    for a in allergies:
        patient_allergies.setdefault(a["patient_amka"], set()).add(a["substance_id"])

    drug_to_subs = ref["drug_to_subs"]
    drugs = ref["drugs"]
    doctor_amkas = [d["amka"] for d in doctors]

    rows = []
    seen = set()  # (doctor, patient, drug, start_date) uniqueness
    pid = 1
    attempts = 0
    while pid <= N_PRESCRIPTIONS and attempts < N_PRESCRIPTIONS * 20:
        attempts += 1
        h = random.choice(hospitalizations)
        patient = h["patient_amka"]
        drug = random.choice(drugs)

        # Allergy check
        drug_subs = drug_to_subs.get(drug, set())
        if drug_subs & patient_allergies.get(patient, set()):
            continue  # would trigger allergy violation

        start_d = h["admission_date"].date()
        end_d   = (h["discharge_date"] or
                   (h["admission_date"] + timedelta(days=10))).date()

        key = (random.choice(doctor_amkas), patient, drug, start_d)
        if key in seen:
            continue
        seen.add(key)

        rows.append({
            "prescription_id": pid,
            "doctor_amka": key[0],
            "patient_amka": key[1],
            "hospitalization_id": h["hospitalization_id"],
            "drug_id": key[2],
            "dosage": random.choice(["1 δισκίο", "2 δισκία", "5 ml", "10 mg"]),
            "frequency": random.choice(["Πρωί", "Πρωί-Βράδυ",
                                         "Πρωί-Μεσημέρι-Βράδυ", "Κάθε 8 ώρες"]),
            "start_date": start_d,
            "end_date": end_d,
        })
        pid += 1

    return rows


def gen_shifts_and_assignments(departments, doctors, nurses, admins):
    """
    Cover 7 days fully (March 2-8 2026) for all 15 departments × 3 shifts.
    Respects:
      - Max shifts/month: 15 doctors, 20 nurses, 25 admins
      - 8h rest between shifts (auto-satisfied: same staff in only one shift type)
      - Max 3 consecutive nights
    """
    shifts = []
    assignments = []

    shift_id = 1
    SHIFT_TYPES = ["morning", "afternoon", "night"]

    # Generate shift records
    shift_lookup = {}  # (dept_id, date, type) -> shift_id
    for offset in range(SHIFT_WEEK_DAYS):
        d = SHIFT_WEEK_START + timedelta(days=offset)
        for dept in departments:
            for st in SHIFT_TYPES:
                shifts.append({
                    "shift_id": shift_id,
                    "department_id": dept["department_id"],
                    "shift_date": d,
                    "shift_type": st,
                })
                shift_lookup[(dept["department_id"], d, st)] = shift_id
                shift_id += 1

    # Track shifts assigned per staff member
    staff_shift_count = {}  # amka -> count
    staff_last_shift_end = {}  # amka -> end datetime
    night_streak = {}  # amka -> count of consecutive nights

    def shift_window(d, st):
        if st == "morning":
            return (datetime.combine(d, time(7, 0)),
                    datetime.combine(d, time(15, 0)))
        if st == "afternoon":
            return (datetime.combine(d, time(15, 0)),
                    datetime.combine(d, time(23, 0)))
        return (datetime.combine(d, time(23, 0)),
                datetime.combine(d + timedelta(days=1), time(7, 0)))

    # Per-department doctor list
    # Note: doctor_department mapping isn't used here for simplicity;
    # we assign any doctor (the spec doesn't strictly require shift = doctor's dept)
    doctor_pool = list(doctors)
    nurse_pool = list(nurses)
    admin_pool = list(admins)

    # Required staffing per shift
    REQ_DOCTORS = 3
    REQ_NURSES  = 6
    REQ_ADMINS  = 2

    # Helper to check if assignment is allowed
    def can_assign(amka, d, st, max_per_month, is_night):
        # Max per month
        if staff_shift_count.get(amka, 0) >= max_per_month:
            return False
        s_start, s_end = shift_window(d, st)
        # 8h rest from previous
        last_end = staff_last_shift_end.get(amka)
        if last_end and (s_start - last_end) < timedelta(hours=8):
            return False
        # Max 3 consecutive nights
        if is_night and night_streak.get(amka, 0) >= 3:
            return False
        return True

    def record_assign(amka, d, st):
        s_start, s_end = shift_window(d, st)
        staff_shift_count[amka] = staff_shift_count.get(amka, 0) + 1
        staff_last_shift_end[amka] = s_end
        if st == "night":
            night_streak[amka] = night_streak.get(amka, 0) + 1
        else:
            night_streak[amka] = 0

    # Iterate shifts in chronological order
    sorted_shifts = sorted(shifts, key=lambda s: (s["shift_date"], s["shift_type"]))
    for sh in sorted_shifts:
        d = sh["shift_date"]
        st = sh["shift_type"]
        sid = sh["shift_id"]
        is_night = (st == "night")

        # Doctors
        random.shuffle(doctor_pool)

        # IMPORTANT:
        # The trigger trg_shift_resident_needs_senior is BEFORE INSERT and
        # checks only rows that already exist for the same shift.
        # Therefore, if we assign an Ειδικευόμενος, the Επιμελητής Α/Διευθυντής
        # must be inserted BEFORE the resident in shift_assignment.
        chosen_doctors = []
        senior_present = False

        seniors = [d_ for d_ in doctor_pool
                   if d_["rank"] in ("Επιμελητής Α", "Διευθυντής")]

        # First try to assign one senior doctor.
        for senior in seniors:
            if can_assign(senior["amka"], d, st, 15, is_night):
                chosen_doctors.append(senior)
                record_assign(senior["amka"], d, st)
                senior_present = True
                break

        # Fill remaining doctor slots. If no senior could be assigned, do NOT
        # assign residents; otherwise the trigger will correctly reject the row.
        for doc in doctor_pool:
            if len(chosen_doctors) >= REQ_DOCTORS:
                break
            if doc in chosen_doctors:
                continue
            if (not senior_present) and doc["rank"] == "Ειδικευόμενος":
                continue
            if can_assign(doc["amka"], d, st, 15, is_night):
                chosen_doctors.append(doc)
                record_assign(doc["amka"], d, st)

        # Append doctors in this order, so the senior row exists before any resident row.
        for doc in chosen_doctors:
            assignments.append({"shift_id": sid, "staff_amka": doc["amka"]})

        # Nurses
        random.shuffle(nurse_pool)
        chosen_nurses = []
        for n in nurse_pool:
            if len(chosen_nurses) >= REQ_NURSES:
                break
            if can_assign(n["amka"], d, st, 20, is_night):
                chosen_nurses.append(n)
                record_assign(n["amka"], d, st)
        for n in chosen_nurses:
            assignments.append({"shift_id": sid, "staff_amka": n["amka"]})

        # Admins
        random.shuffle(admin_pool)
        chosen_admins = []
        for a in admin_pool:
            if len(chosen_admins) >= REQ_ADMINS:
                break
            if can_assign(a["amka"], d, st, 25, is_night):
                chosen_admins.append(a)
                record_assign(a["amka"], d, st)
        for a in chosen_admins:
            assignments.append({"shift_id": sid, "staff_amka": a["amka"]})

    return shifts, assignments


# ---------------------------------------------------------------
# SQL writer
# ---------------------------------------------------------------
def write_inserts(f, table, rows, columns, batch=200):
    if not rows:
        return
    f.write(f"-- {len(rows)} rows into {table}\n")
    cols_sql = ", ".join(f"`{c}`" for c in columns)
    for i in range(0, len(rows), batch):
        chunk = rows[i:i + batch]
        f.write(f"INSERT INTO `{table}` ({cols_sql}) VALUES\n")
        values = []
        for r in chunk:
            tup = ", ".join(sql_val(r[c]) for c in columns)
            values.append(f"  ({tup})")
        f.write(",\n".join(values))
        f.write(";\n\n")


# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", default="sql/data")
    parser.add_argument("--out", default="sql/synthetic_data.sql")
    args = parser.parse_args()

    random.seed(SEED)

    print("== Loading reference CSVs ==")
    ref = load_reference(Path(args.data_dir))

    print("== Generating synthetic data ==")
    departments = gen_departments()
    staff, doctors, nurses, admins = gen_staff_and_subtypes(departments)
    doctor_dept = gen_doctor_department(doctors, departments)
    beds = gen_beds(departments)
    patients = gen_patients()
    contacts = gen_patient_contacts(patients)
    allergies = gen_patient_allergies(patients, ref["substances_by_name"])
    triage_rows, hospitalized_pairs = gen_triage_records(patients, nurses, departments)
    hospitalizations = gen_hospitalizations(hospitalized_pairs, beds, doctors, ref)
    ratings = gen_ratings(hospitalizations)
    lab_exams = gen_lab_exams(hospitalizations, doctors, ref["lab_exam_codes"])
    rooms = gen_procedure_rooms()
    occurrences = gen_procedure_occurrences(hospitalizations, doctors, rooms, ref)
    participations = gen_procedure_participations(occurrences, staff)
    prescriptions = gen_prescriptions(hospitalizations, doctors, allergies, ref)
    shifts, assignments = gen_shifts_and_assignments(
        departments, doctors, nurses, admins)

    print(f"  staff={len(staff)} (doc={len(doctors)}, nurse={len(nurses)}, "
          f"admin={len(admins)})")
    print(f"  patients={len(patients)}, allergies={len(allergies)}")
    print(f"  hospitalizations={len(hospitalizations)}, ratings={len(ratings)}")
    print(f"  lab_exams={len(lab_exams)}, prescriptions={len(prescriptions)}")
    print(f"  procedure_occurrences={len(occurrences)}, "
          f"participations={len(participations)}")
    print(f"  shifts={len(shifts)}, assignments={len(assignments)}")
    print(f"  triage_records={len(triage_rows)}")

    print(f"\n== Writing {args.out} ==")
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("-- synthetic_data.sql (auto-generated)\n")
        f.write(f"-- seed={SEED}\n")
        f.write("USE `ygeiopolis_db`;\n\n")
        f.write("SET FOREIGN_KEY_CHECKS=0;\n\n")

        # IMPORTANT: we disable triggers temporarily during bulk insert
        # because some triggers (e.g. director foreign key on departments)
        # need cross-table consistency that we manage manually.
        # We re-enable at the end.
        # Note: MySQL does NOT support disabling triggers natively;
        # we rely on insertion ORDER + verified data correctness.

        # Reference data is already loaded by LOAD DATA INFILE in load.sql.
        # Here we only write synthetic data.

        write_inserts(f, "staff", staff,
            ["amka","first_name","last_name","age","email","phone",
             "hire_date","staff_type"])

        # Doctors first WITHOUT supervisor_amka, then UPDATE
        # (to avoid FK ordering issues since supervisor_amka references doctor.amka)
        write_inserts(f, "doctor",
            [{**d, "supervisor_amka": None} for d in doctors],
            ["amka","licence_number","specialty","rank","supervisor_amka"])

        # Departments require director_amka FK to doctor — doctors exist now
        write_inserts(f, "department", departments,
            ["department_id","name","description","floor_building",
             "director_amka"])

        write_inserts(f, "nurse", nurses,
            ["amka","nurse_rank","department_id"])
        write_inserts(f, "admin_staff", admins,
            ["amka","role","office","department_id"])

        # Now update doctor supervisors
        f.write("-- Update doctor supervisors (after all doctors exist)\n")
        for d in doctors:
            if d["supervisor_amka"]:
                f.write(f"UPDATE `doctor` SET `supervisor_amka`={d['supervisor_amka']} "
                        f"WHERE `amka`={d['amka']};\n")
        f.write("\n")

        write_inserts(f, "doctor_department", doctor_dept,
            ["doctor_amka","department_id"])
        write_inserts(f, "bed", beds,
            ["bed_id","bed_number","bed_type","status","department_id"])
        write_inserts(f, "patient", patients,
            ["amka","first_name","last_name","father_name","age","gender",
             "weight","height","address","phone","email","occupation",
             "nationality","insurance_provider"])
        write_inserts(f, "patient_contact", contacts,
            ["contact_id","patient_amka","full_name","phone","relationship","notes"])
        write_inserts(f, "patient_allergy", allergies,
            ["patient_amka","substance_id","notes"])
        write_inserts(f, "triage_record", triage_rows,
            ["triage_id","patient_amka","nurse_amka","arrival_time","symptoms",
             "urgency_level","outcome","decision_time","referred_department_id"])
        write_inserts(f, "hospitalization", hospitalizations,
            ["hospitalization_id","patient_amka","department_id","bed_id",
             "ken_code","admission_icd10_code","discharge_icd10_code",
             "admission_date","discharge_date","total_cost","primary_doctor_amka"])
        write_inserts(f, "rating", ratings,
            ["rating_id","hospitalization_id","medical_care_score",
             "nursing_care_score","cleanliness_score","food_score",
             "overall_experience_score"])
        write_inserts(f, "lab_exam", lab_exams,
            ["exam_id","hospitalization_id","doctor_amka","exam_code",
             "exam_date","result_text","numeric_value","unit","cost"])
        write_inserts(f, "procedure_room", rooms,
            ["room_id","room_name","room_type"])
        write_inserts(f, "procedure_occurrence", occurrences,
            ["occurrence_id","hospitalization_id","procedure_code","room_id",
             "main_surgeon_amka","start_datetime","end_datetime"])
        write_inserts(f, "procedure_participation", participations,
            ["occurrence_id","staff_amka","role_in_procedure"])
        write_inserts(f, "prescription", prescriptions,
            ["prescription_id","doctor_amka","patient_amka","hospitalization_id",
             "drug_id","dosage","frequency","start_date","end_date"])
        write_inserts(f, "shift", shifts,
            ["shift_id","department_id","shift_date","shift_type"])
        write_inserts(f, "shift_assignment", assignments,
            ["shift_id","staff_amka"])

        f.write("\nSET FOREIGN_KEY_CHECKS=1;\n")
        f.write("-- end of synthetic_data.sql\n")

    print(f"\n✓ Done. SQL written to {out_path}")
    print(f"  Size: {out_path.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()