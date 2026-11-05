-- =============================================================
-- Q12: Απαιτούμενος αριθμός προσωπικού ανά τμήμα και βάρδια για
--      συγκεκριμένη εβδομάδα, με ανάλυση ανά υποκλάση:
--        - Ιατροί ανά ειδικότητα
--        - Νοσηλευτές ανά βαθμίδα
--        - Διοικητικό προσωπικό ανά ρόλο
-- =============================================================
USE `ygeiopolis_db`;

SET @week_start := '2026-03-02';
SET @week_end   := '2026-03-08';

SELECT
  d.name                                          AS department,
  sh.shift_date                                   AS shift_date,
  sh.shift_type                                   AS shift_type,
  CASE
    WHEN doc.amka IS NOT NULL THEN 'doctor'
    WHEN nu.amka  IS NOT NULL THEN 'nurse'
    WHEN ad.amka  IS NOT NULL THEN 'admin'
  END                                             AS staff_class,
  CASE
    WHEN doc.amka IS NOT NULL THEN doc.specialty
    WHEN nu.amka  IS NOT NULL THEN nu.nurse_rank
    WHEN ad.amka  IS NOT NULL THEN ad.role
  END                                             AS subclass,
  COUNT(*)                                        AS staff_count
FROM       shift_assignment sa
JOIN       shift  sh ON sh.shift_id = sa.shift_id
JOIN       department d ON d.department_id = sh.department_id
JOIN       staff   s  ON s.amka = sa.staff_amka
LEFT JOIN  doctor  doc ON doc.amka = sa.staff_amka
LEFT JOIN  nurse   nu  ON nu.amka  = sa.staff_amka
LEFT JOIN  admin_staff ad ON ad.amka = sa.staff_amka
WHERE      sh.shift_date BETWEEN @week_start AND @week_end
GROUP BY   d.name, sh.shift_date, sh.shift_type, staff_class, subclass
ORDER BY   d.name, sh.shift_date, sh.shift_type, staff_class, subclass;