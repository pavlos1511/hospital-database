-- =============================================================
-- Q08: Προσωπικό (ιατροί, νοσηλευτές, διοικητικό) που ΔΕΝ έχει
--      προγραμματισμένη εφημερία σε συγκεκριμένη ημερομηνία και
--      τμήμα.
-- =============================================================
USE `ygeiopolis_db`;

SET @target_date := '2026-03-02';
SET @target_dept := 1;  -- Καρδιολογία

SELECT
  s.amka                                           AS amka,
  s.first_name                                     AS first_name,
  s.last_name                                      AS last_name,
  s.staff_type                                     AS staff_type,
  CASE
    WHEN d.amka IS NOT NULL THEN d.specialty
    WHEN n.amka IS NOT NULL THEN n.nurse_rank
    WHEN a.amka IS NOT NULL THEN a.role
    ELSE NULL
  END                                              AS subtype_info
FROM       staff s
LEFT JOIN  doctor      d ON d.amka = s.amka
LEFT JOIN  nurse       n ON n.amka = s.amka
LEFT JOIN  admin_staff a ON a.amka = s.amka
WHERE      NOT EXISTS (
  SELECT 1
  FROM   shift_assignment sa
  JOIN   shift sh ON sh.shift_id = sa.shift_id
  WHERE  sa.staff_amka     = s.amka
    AND  sh.shift_date     = @target_date
    AND  sh.department_id  = @target_dept
)
ORDER BY   s.staff_type, s.last_name, s.first_name;