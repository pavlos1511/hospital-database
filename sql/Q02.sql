-- =============================================================
-- Q02: Ιατροί συγκεκριμένης ειδικότητας με ένδειξη εφημερίας
--      και πλήθος επεμβάσεων ως κύριοι χειρουργοί.
-- =============================================================
USE `ygeiopolis_db`;

SET @specialty := 'Καρδιολογία';

SELECT
  d.amka                                                   AS amka,
  s.first_name                                             AS first_name,
  s.last_name                                              AS last_name,
  d.specialty                                              AS specialty,
  d.rank                                                   AS rank,
  CASE WHEN EXISTS (
    SELECT 1
    FROM   shift_assignment sa
    JOIN   shift sh ON sh.shift_id = sa.shift_id
    WHERE  sa.staff_amka = d.amka
      AND  YEAR(sh.shift_date) = YEAR(CURDATE())
  ) THEN 'YES' ELSE 'NO' END                               AS had_shift_this_year,
  COALESCE(po.surgery_count, 0)                            AS surgeries_as_main_surgeon
FROM       doctor    d
JOIN       staff     s  ON s.amka = d.amka
LEFT JOIN  (
  SELECT   main_surgeon_amka, COUNT(*) AS surgery_count
  FROM     procedure_occurrence
  GROUP BY main_surgeon_amka
)          po ON po.main_surgeon_amka = d.amka
WHERE      d.specialty = @specialty COLLATE utf8mb4_unicode_ci
ORDER BY   surgeries_as_main_surgeon DESC, last_name;