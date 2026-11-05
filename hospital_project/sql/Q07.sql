-- =============================================================
-- Q07: Για κάθε δραστική ουσία, αριθμός ασθενών με αλλεργία και
--      αριθμός φαρμάκων που την περιέχουν, ταξινομημένα κατά
--      συνολικό αριθμό αλλεργικών ασθενών.
-- =============================================================
USE `ygeiopolis_db`;

SELECT
  s.substance_id                                   AS substance_id,
  s.substance_name                                 AS substance_name,
  COALESCE(pa.allergic_patients, 0)                AS allergic_patients,
  COALESCE(da.drug_count, 0)                       AS drugs_containing
FROM       active_substance s
LEFT JOIN  (
  SELECT   substance_id, COUNT(DISTINCT patient_amka) AS allergic_patients
  FROM     patient_allergy
  GROUP BY substance_id
)          pa ON pa.substance_id = s.substance_id
LEFT JOIN  (
  SELECT   substance_id, COUNT(DISTINCT drug_id) AS drug_count
  FROM     drug_active_substance
  GROUP BY substance_id
)          da ON da.substance_id = s.substance_id
WHERE      pa.allergic_patients IS NOT NULL
ORDER BY   allergic_patients DESC, drugs_containing DESC, substance_name;