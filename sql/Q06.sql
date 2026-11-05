-- =============================================================
-- Q06: Για συγκεκριμένο ασθενή, ιστορικό νοσηλειών με αντίστοιχες
--      διαγνώσεις (ICD-10), συνολικό κόστος ανά νοσηλεία και μέσος
--      όρος αξιολόγησης (Συνολική εντύπωση).
-- =============================================================
USE `ygeiopolis_db`;

SET @patient_amka := 99342011154;

-- ---- (α) Κανονική εκτέλεση ----
SELECT '=== Q6: Κανονική εκτέλεση ===' AS info;

SELECT
  h.hospitalization_id                              AS hosp_id,
  h.admission_date                                  AS admission,
  h.discharge_date                                  AS discharge,
  h.admission_icd10_code                            AS adm_icd10,
  ai.description                                    AS adm_diagnosis,
  h.discharge_icd10_code                            AS dis_icd10,
  di.description                                    AS dis_diagnosis,
  h.total_cost                                      AS total_cost,
  r.overall_experience_score                        AS overall_score,
  (SELECT ROUND(AVG(r2.overall_experience_score), 2)
   FROM   hospitalization h2
   JOIN   rating          r2 ON r2.hospitalization_id = h2.hospitalization_id
   WHERE  h2.patient_amka = @patient_amka)          AS avg_overall_for_patient
FROM       hospitalization h
LEFT JOIN  icd10_diagnosis ai ON ai.icd10_code = h.admission_icd10_code
LEFT JOIN  icd10_diagnosis di ON di.icd10_code = h.discharge_icd10_code
LEFT JOIN  rating r           ON r.hospitalization_id = h.hospitalization_id
WHERE      h.patient_amka = @patient_amka
ORDER BY   h.admission_date;

-- ---- EXPLAIN της κανονικής ----
SELECT '=== EXPLAIN (κανονική) ===' AS info;
EXPLAIN
SELECT
  h.hospitalization_id, h.admission_date, h.discharge_date,
  h.admission_icd10_code, h.discharge_icd10_code,
  h.total_cost, r.overall_experience_score
FROM       hospitalization h
LEFT JOIN  icd10_diagnosis ai ON ai.icd10_code = h.admission_icd10_code
LEFT JOIN  icd10_diagnosis di ON di.icd10_code = h.discharge_icd10_code
LEFT JOIN  rating r           ON r.hospitalization_id = h.hospitalization_id
WHERE      h.patient_amka = @patient_amka;

-- ---- (β) Εναλλακτική με FORCE INDEX ----
SELECT '=== Q6: Εκτέλεση με FORCE INDEX ===' AS info;

SELECT
  h.hospitalization_id                              AS hosp_id,
  h.admission_date                                  AS admission,
  h.discharge_date                                  AS discharge,
  h.admission_icd10_code                            AS adm_icd10,
  ai.description                                    AS adm_diagnosis,
  h.discharge_icd10_code                            AS dis_icd10,
  di.description                                    AS dis_diagnosis,
  h.total_cost                                      AS total_cost,
  r.overall_experience_score                        AS overall_score
FROM       hospitalization h FORCE INDEX (idx_hosp_patient_amka)
LEFT JOIN  icd10_diagnosis ai ON ai.icd10_code = h.admission_icd10_code
LEFT JOIN  icd10_diagnosis di ON di.icd10_code = h.discharge_icd10_code
LEFT JOIN  rating r           ON r.hospitalization_id = h.hospitalization_id
WHERE      h.patient_amka = @patient_amka
ORDER BY   h.admission_date;

-- ---- EXPLAIN με FORCE INDEX ----
SELECT '=== EXPLAIN (FORCE INDEX) ===' AS info;
EXPLAIN
SELECT
  h.hospitalization_id, h.admission_date, h.discharge_date,
  h.admission_icd10_code, h.discharge_icd10_code,
  h.total_cost, r.overall_experience_score
FROM       hospitalization h FORCE INDEX (idx_hosp_patient_amka)
LEFT JOIN  icd10_diagnosis ai ON ai.icd10_code = h.admission_icd10_code
LEFT JOIN  icd10_diagnosis di ON di.icd10_code = h.discharge_icd10_code
LEFT JOIN  rating r           ON r.hospitalization_id = h.hospitalization_id
WHERE      h.patient_amka = @patient_amka;