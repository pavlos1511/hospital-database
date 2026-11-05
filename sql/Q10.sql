-- =============================================================
-- Q10: Top-3 ζεύγη δραστικών ουσιών που συνταγογραφήθηκαν στον
--      ίδιο ασθενή κατά την ίδια νοσηλεία, ταξινομημένα κατά
--      συχνότητα εμφάνισης.
-- =============================================================
USE `ygeiopolis_db`;

WITH prescription_substances AS (
  -- Για κάθε νοσηλεία, παίρνουμε όλες τις δραστικές ουσίες των
  -- συνταγογραφημένων φαρμάκων (μέσω drug_active_substance).
  SELECT DISTINCT
    pr.hospitalization_id                      AS hospitalization_id,
    pr.patient_amka                            AS patient_amka,
    das.substance_id                           AS substance_id
  FROM   prescription pr
  JOIN   drug_active_substance das
         ON das.drug_id = pr.drug_id
)
SELECT
  s1.substance_id                              AS substance_id_1,
  asub1.substance_name                         AS substance_name_1,
  s2.substance_id                              AS substance_id_2,
  asub2.substance_name                         AS substance_name_2,
  COUNT(*)                                     AS pair_frequency
FROM       prescription_substances s1
JOIN       prescription_substances s2
           ON s1.hospitalization_id = s2.hospitalization_id
          AND s1.substance_id       < s2.substance_id    -- αποφυγή διπλοεγγραφών
JOIN       active_substance asub1 ON asub1.substance_id = s1.substance_id
JOIN       active_substance asub2 ON asub2.substance_id = s2.substance_id
GROUP BY   s1.substance_id, asub1.substance_name,
           s2.substance_id, asub2.substance_name
ORDER BY   pair_frequency DESC, substance_name_1, substance_name_2
LIMIT 3;