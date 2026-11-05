-- =============================================================
-- Q05: Νέοι ιατροί (age < 35) με τις περισσότερες χειρουργικές
--      επεμβάσεις ως κύριοι χειρουργοί.
-- =============================================================
USE `ygeiopolis_db`;

SELECT
  d.amka                                           AS doctor_amka,
  s.first_name                                     AS first_name,
  s.last_name                                      AS last_name,
  s.age                                            AS age,
  d.specialty                                      AS specialty,
  d.rank                                           AS rank,
  COUNT(*)                                         AS surgeries
FROM       doctor             d
JOIN       staff              s  ON s.amka = d.amka
JOIN       procedure_occurrence po ON po.main_surgeon_amka = d.amka
JOIN       medical_procedure   mp ON mp.procedure_code = po.procedure_code
WHERE      s.age < 35
  AND      mp.category COLLATE utf8mb4_unicode_ci = 'χειρουργική'
GROUP BY   d.amka, s.first_name, s.last_name, s.age, d.specialty, d.rank
ORDER BY   surgeries DESC, last_name;