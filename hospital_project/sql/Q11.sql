-- =============================================================
-- Q11: Ιατροί που έχουν εκτελέσει τουλάχιστον 5 λιγότερες επεμβάσεις
--      από τον ιατρό με τις περισσότερες επεμβάσεις στο τρέχον έτος.
--
-- Παραδοχή: Ως "τρέχον έτος" χρησιμοποιείται το πιο πρόσφατο πλήρες
--           έτος με σημαντικό όγκο επεμβάσεων (≥30). Το 2026 είναι
--           ακόμα σε εξέλιξη με ελάχιστα δεδομένα.
-- =============================================================
USE `ygeiopolis_db`;

SET @target_year := (
  SELECT YEAR(start_datetime)
  FROM   procedure_occurrence
  GROUP BY YEAR(start_datetime)
  HAVING COUNT(*) >= 30
  ORDER BY YEAR(start_datetime) DESC
  LIMIT 1
);

WITH yearly_surgeries AS (
  SELECT
    po.main_surgeon_amka                        AS doctor_amka,
    COUNT(*)                                    AS surgeries_count
  FROM       procedure_occurrence po
  WHERE      YEAR(po.start_datetime) = @target_year
  GROUP BY   po.main_surgeon_amka
),
top_surgeon AS (
  SELECT MAX(surgeries_count) AS max_surgeries FROM yearly_surgeries
)
SELECT
  @target_year                                  AS reference_year,
  ys.doctor_amka                                AS doctor_amka,
  st.first_name                                 AS first_name,
  st.last_name                                  AS last_name,
  d.specialty                                   AS specialty,
  d.rank                                        AS rank,
  ys.surgeries_count                            AS surgeries,
  ts.max_surgeries                              AS max_surgeries_in_year,
  (ts.max_surgeries - ys.surgeries_count)       AS difference
FROM       yearly_surgeries ys
CROSS JOIN top_surgeon       ts
JOIN       doctor d  ON d.amka = ys.doctor_amka
JOIN       staff  st ON st.amka = ys.doctor_amka
WHERE      ts.max_surgeries - ys.surgeries_count >= 5
ORDER BY   ys.surgeries_count DESC, last_name;