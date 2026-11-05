-- =============================================================
-- Q04: Για συγκεκριμένο ιατρό, μέσος όρος αξιολογήσεων ασθενών
--      (Ποιότητα ιατρικής φροντίδας) και Συνολική εντύπωση νοσηλείας.
--
--      Παρουσιάζονται:
--        (α) EXPLAIN ANALYZE της κανονικής εκτέλεσης
--        (β) Εναλλακτική με FORCE INDEX
--        (γ) Σύγκριση εκτιμώμενου κόστους και χρόνου εκτέλεσης
--        (δ) Ανάλυση συμπερασμάτων (στο report.pdf)
-- =============================================================
USE `ygeiopolis_db`;

SET @doctor_amka := 89830289645;

-- ---- (α) Κανονική εκτέλεση + EXPLAIN ANALYZE ----
SELECT '=== Q4: Κανονική εκτέλεση ===' AS info;

SELECT
  d.amka                                           AS doctor_amka,
  s.first_name                                     AS first_name,
  s.last_name                                      AS last_name,
  COUNT(r.rating_id)                               AS total_ratings,
  ROUND(AVG(r.medical_care_score), 2)              AS avg_medical_care,
  ROUND(AVG(r.overall_experience_score), 2)        AS avg_overall_experience
FROM       doctor d
JOIN       staff  s ON s.amka = d.amka
JOIN       hospitalization h ON h.primary_doctor_amka = d.amka
JOIN       rating          r ON r.hospitalization_id = h.hospitalization_id
WHERE      d.amka = @doctor_amka
GROUP BY   d.amka, s.first_name, s.last_name;

-- ---- EXPLAIN της κανονικής εκτέλεσης ----
SELECT '=== EXPLAIN ANALYZE (κανονική) ===' AS info;
EXPLAIN
SELECT
  d.amka, s.first_name, s.last_name,
  COUNT(r.rating_id),
  AVG(r.medical_care_score),
  AVG(r.overall_experience_score)
FROM       doctor d
JOIN       staff  s ON s.amka = d.amka
JOIN       hospitalization h ON h.primary_doctor_amka = d.amka
JOIN       rating          r ON r.hospitalization_id = h.hospitalization_id
WHERE      d.amka = @doctor_amka
GROUP BY   d.amka, s.first_name, s.last_name;

-- ---- (β) Εναλλακτική με FORCE INDEX ----
SELECT '=== Q4: Εκτέλεση με FORCE INDEX ===' AS info;

SELECT
  d.amka                                           AS doctor_amka,
  s.first_name                                     AS first_name,
  s.last_name                                      AS last_name,
  COUNT(r.rating_id)                               AS total_ratings,
  ROUND(AVG(r.medical_care_score), 2)              AS avg_medical_care,
  ROUND(AVG(r.overall_experience_score), 2)        AS avg_overall_experience
FROM       doctor d
JOIN       staff  s ON s.amka = d.amka
JOIN       hospitalization h FORCE INDEX (idx_hosp_primary_doctor)
                              ON h.primary_doctor_amka = d.amka
JOIN       rating          r FORCE INDEX (uq_rating_hosp)
                              ON r.hospitalization_id = h.hospitalization_id
WHERE      d.amka = @doctor_amka
GROUP BY   d.amka, s.first_name, s.last_name;

-- ---- EXPLAIN με FORCE INDEX ----
SELECT '=== EXPLAIN ANALYZE (FORCE INDEX) ===' AS info;
EXPLAIN
SELECT
  d.amka, s.first_name, s.last_name,
  COUNT(r.rating_id),
  AVG(r.medical_care_score),
  AVG(r.overall_experience_score)
FROM       doctor d
JOIN       staff  s ON s.amka = d.amka
JOIN       hospitalization h FORCE INDEX (idx_hosp_primary_doctor)
                              ON h.primary_doctor_amka = d.amka
JOIN       rating          r FORCE INDEX (uq_rating_hosp)
                              ON r.hospitalization_id = h.hospitalization_id
WHERE      d.amka = @doctor_amka
GROUP BY   d.amka, s.first_name, s.last_name;