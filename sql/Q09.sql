-- =============================================================
-- Q09: Ασθενείς που νοσηλεύτηκαν τον ίδιο αριθμό ημερών σε διάστημα
--      ενός έτους, με συνολική διάρκεια άνω των 15 ημερών.
-- =============================================================
USE `ygeiopolis_db`;

WITH patient_year_stay AS (
  SELECT
    h.patient_amka,
    YEAR(h.admission_date)                                  AS year,
    SUM(DATEDIFF(h.discharge_date, h.admission_date))       AS total_days
  FROM   hospitalization h
  WHERE  h.discharge_date IS NOT NULL
  GROUP BY h.patient_amka, YEAR(h.admission_date)
  HAVING total_days > 15
),
matching_days AS (
  SELECT
    pys1.year                                  AS year,
    pys1.total_days                            AS total_days,
    COUNT(*)                                   AS patient_count
  FROM       patient_year_stay pys1
  GROUP BY   pys1.year, pys1.total_days
  HAVING     COUNT(*) > 1
)
SELECT
  pys.patient_amka                             AS patient_amka,
  p.first_name                                 AS first_name,
  p.last_name                                  AS last_name,
  pys.year                                     AS year,
  pys.total_days                               AS total_days_in_year,
  md.patient_count                             AS patients_with_same_days
FROM       patient_year_stay pys
JOIN       matching_days     md ON md.year = pys.year AND md.total_days = pys.total_days
JOIN       patient           p  ON p.amka = pys.patient_amka
ORDER BY   pys.year, pys.total_days DESC, pys.patient_amka;