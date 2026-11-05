-- =============================================================
-- Q03: Ασθενείς με περισσότερες από 3 νοσηλείες στο ίδιο τμήμα
--      και το συνολικό κόστος νοσηλείας τους.
-- =============================================================
USE `ygeiopolis_db`;

SELECT
  p.amka                          AS patient_amka,
  p.first_name                    AS first_name,
  p.last_name                     AS last_name,
  d.name                          AS department,
  COUNT(*)                        AS hospitalizations,
  ROUND(SUM(h.total_cost), 2)     AS total_cost
FROM       hospitalization h
JOIN       patient    p ON p.amka          = h.patient_amka
JOIN       department d ON d.department_id = h.department_id
GROUP BY   p.amka, p.first_name, p.last_name, d.name
HAVING     COUNT(*) > 3
ORDER BY   hospitalizations DESC, total_cost DESC;