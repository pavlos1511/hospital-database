-- =============================================================
-- Q01: Συνολικά έσοδα ανά τμήμα και έτος, με ανάλυση ανά ΚΕΝ
--      (βασικό κόστος vs πρόσθετη χρέωση λόγω υπέρβασης ΜΔΝ)
--      και κατανομή ανά ασφαλιστικό φορέα.
-- =============================================================
USE `ygeiopolis_db`;

SELECT
  d.name                                               AS department,
  YEAR(h.admission_date)                               AS year,
  h.ken_code                                           AS ken,
  p.insurance_provider                                 AS insurance,
  COUNT(*)                                             AS hospitalizations,
  ROUND(SUM(k.base_cost), 2)                           AS base_revenue,
  ROUND(SUM(
    CASE
      WHEN DATEDIFF(h.discharge_date, h.admission_date) > k.mean_length_of_stay
        THEN (DATEDIFF(h.discharge_date, h.admission_date) - k.mean_length_of_stay)
             * (k.base_cost / k.mean_length_of_stay)
      ELSE 0
    END
  ), 2)                                                AS overstay_revenue,
  ROUND(SUM(
    k.base_cost +
    CASE
      WHEN DATEDIFF(h.discharge_date, h.admission_date) > k.mean_length_of_stay
        THEN (DATEDIFF(h.discharge_date, h.admission_date) - k.mean_length_of_stay)
             * (k.base_cost / k.mean_length_of_stay)
      ELSE 0
    END
  ), 2)                                                AS total_revenue
FROM       hospitalization h
JOIN       department      d ON d.department_id = h.department_id
JOIN       ken              k ON k.ken_code      = h.ken_code
JOIN       patient          p ON p.amka          = h.patient_amka
WHERE      h.discharge_date IS NOT NULL
GROUP BY   d.name, YEAR(h.admission_date), h.ken_code, p.insurance_provider
ORDER BY   d.name, year, ken, insurance;