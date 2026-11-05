-- =============================================================
-- Q14: ICD-10 κατηγορίες (πρώτο γράμμα κωδικού) με τον ίδιο
--      αριθμό εισαγωγών σε δύο συνεχόμενα έτη, τουλάχιστον 5
--      περιστατικά ανά έτος.
-- =============================================================
USE `ygeiopolis_db`;

WITH category_yearly AS (
  SELECT
    LEFT(h.admission_icd10_code, 1)              AS icd10_category,
    YEAR(h.admission_date)                       AS year,
    COUNT(*)                                     AS admissions
  FROM       hospitalization h
  WHERE      h.admission_icd10_code IS NOT NULL
  GROUP BY   LEFT(h.admission_icd10_code, 1), YEAR(h.admission_date)
  HAVING     admissions >= 5
)
SELECT
  cy1.icd10_category                             AS icd10_category,
  cy1.year                                       AS year_1,
  cy1.admissions                                 AS admissions_year_1,
  cy2.year                                       AS year_2,
  cy2.admissions                                 AS admissions_year_2
FROM       category_yearly cy1
JOIN       category_yearly cy2
           ON cy1.icd10_category = cy2.icd10_category
          AND cy2.year           = cy1.year + 1
          AND cy2.admissions     = cy1.admissions
ORDER BY   cy1.icd10_category, cy1.year;