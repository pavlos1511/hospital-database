-- =============================================================
-- Q15: Κατανομή triage περιστατικών:
--        - ανά επίπεδο επείγοντος
--        - μέσος χρόνος αναμονής (decision_time - arrival_time)
--        - ποσοστό περιστατικών που οδήγησαν σε νοσηλεία
--        - κατανομή παραπομπών ανά τμήμα
-- =============================================================
USE `ygeiopolis_db`;

WITH triage_stats AS (
  SELECT
    tr.urgency_level                                          AS urgency_level,
    COUNT(*)                                                  AS total_cases,
    AVG(TIMESTAMPDIFF(MINUTE, tr.arrival_time, tr.decision_time))
                                                              AS avg_wait_minutes,
    SUM(CASE WHEN tr.outcome = 'hospitalized' THEN 1 ELSE 0 END)
                                                              AS hospitalized_cases
  FROM       triage_record tr
  GROUP BY   tr.urgency_level
),
dept_referrals AS (
  SELECT
    tr.urgency_level                                          AS urgency_level,
    d.name                                                    AS department,
    COUNT(*)                                                  AS dept_referrals
  FROM       triage_record tr
  JOIN       department d ON d.department_id = tr.referred_department_id
  WHERE      tr.outcome = 'hospitalized'
  GROUP BY   tr.urgency_level, d.name
)
SELECT
  ts.urgency_level                                            AS urgency_level,
  ts.total_cases                                              AS total_cases,
  ROUND(ts.avg_wait_minutes, 1)                               AS avg_wait_minutes,
  ts.hospitalized_cases                                       AS hospitalized,
  ROUND(100.0 * ts.hospitalized_cases / ts.total_cases, 1)    AS hospitalization_pct,
  dr.department                                               AS referred_department,
  dr.dept_referrals                                           AS dept_referral_count
FROM       triage_stats   ts
LEFT JOIN  dept_referrals dr ON dr.urgency_level = ts.urgency_level
ORDER BY   ts.urgency_level, dr.dept_referrals DESC;