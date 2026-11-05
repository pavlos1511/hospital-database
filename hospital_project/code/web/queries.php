<?php
require_once "db.php";

$selected = $_GET["q"] ?? "q01";

$queries = [
    "q01" => [
        "title" => 'Q01 - Revenue by department/year/KEN/insurance',
        "sql" => <<<'SQL'
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
ORDER BY   d.name, year, ken, insurance
SQL
    ],
    "q02" => [
        "title" => 'Q02 - Doctors by specialty',
        "sql" => <<<'SQL'
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
WHERE      d.specialty = 'Καρδιολογία' COLLATE utf8mb4_unicode_ci
ORDER BY   surgeries_as_main_surgeon DESC, last_name
SQL
    ],
    "q03" => [
        "title" => 'Q03 - Patients hospitalized >3 times in same department',
        "sql" => <<<'SQL'
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
ORDER BY   hospitalizations DESC, total_cost DESC
SQL
    ],
    "q04" => [
        "title" => 'Q04 - Doctor average ratings',
        "sql" => <<<'SQL'
SELECT
  d.amka                                           AS doctor_amka,
  s.first_name                                     AS first_name,
  s.last_name                                      AS last_name,
  COUNT(r.rating_id)                               AS total_ratings,
  ROUND(AVG(r.medical_care_score), 2)              AS avg_medical_care,
  ROUND(AVG(r.overall_experience_score), 2)        AS avg_overall_experience
FROM       doctor d
JOIN       staff  s ON s.amka = d.amka
JOIN       hospitalization h ON h.primary_doctor_amka = d.amka
JOIN       rating          r ON r.hospitalization_id = h.hospitalization_id
WHERE      d.amka = 64857675642
GROUP BY   d.amka, s.first_name, s.last_name
SQL
    ],
    "q05" => [
        "title" => 'Q05 - Young doctors with most surgeries',
        "sql" => <<<'SQL'
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
ORDER BY   surgeries DESC, last_name
SQL
    ],
    "q06" => [
        "title" => 'Q06 - Patient hospitalization history',
        "sql" => <<<'SQL'
SELECT
  h.hospitalization_id                              AS hosp_id,
  h.admission_date                                  AS admission,
  h.discharge_date                                  AS discharge,
  h.admission_icd10_code                            AS adm_icd10,
  ai.description                                    AS adm_diagnosis,
  h.discharge_icd10_code                            AS dis_icd10,
  di.description                                    AS dis_diagnosis,
  h.total_cost                                      AS total_cost,
  r.overall_experience_score                        AS overall_score,
  (SELECT ROUND(AVG(r2.overall_experience_score), 2)
   FROM   hospitalization h2
   JOIN   rating          r2 ON r2.hospitalization_id = h2.hospitalization_id
   WHERE  h2.patient_amka = 99342011154)            AS avg_overall_for_patient
FROM       hospitalization h
LEFT JOIN  icd10_diagnosis ai ON ai.icd10_code = h.admission_icd10_code
LEFT JOIN  icd10_diagnosis di ON di.icd10_code = h.discharge_icd10_code
LEFT JOIN  rating r           ON r.hospitalization_id = h.hospitalization_id
WHERE      h.patient_amka = 99342011154
ORDER BY   h.admission_date
SQL
    ],
    "q07" => [
        "title" => 'Q07 - Allergies and drugs per active substance',
        "sql" => <<<'SQL'
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
ORDER BY   allergic_patients DESC, drugs_containing DESC, substance_name
SQL
    ],
    "q08" => [
        "title" => 'Q08 - Staff without shift on selected date/department',
        "sql" => <<<'SQL'
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
    AND  sh.shift_date     = '2026-03-02'
    AND  sh.department_id  = 1
)
ORDER BY   s.staff_type, s.last_name, s.first_name
SQL
    ],
    "q09" => [
        "title" => 'Q09 - Patients with same yearly stay days',
        "sql" => <<<'SQL'
WITH patient_year_stay AS (
  SELECT
    h.patient_amka,
    YEAR(h.admission_date)                                  AS year,
    SUM(DATEDIFF(h.discharge_date, h.admission_date))       AS total_days
  FROM   hospitalization h
  WHERE  h.discharge_date IS NOT NULL
  GROUP BY h.patient_amka, YEAR(h.admission_date)
  HAVING total_days > 15
),
matching_days AS (
  SELECT
    pys1.year                                  AS year,
    pys1.total_days                            AS total_days,
    COUNT(*)                                   AS patient_count
  FROM       patient_year_stay pys1
  GROUP BY   pys1.year, pys1.total_days
  HAVING     COUNT(*) > 1
)
SELECT
  pys.patient_amka                             AS patient_amka,
  p.first_name                                 AS first_name,
  p.last_name                                  AS last_name,
  pys.year                                     AS year,
  pys.total_days                               AS total_days_in_year,
  md.patient_count                             AS patients_with_same_days
FROM       patient_year_stay pys
JOIN       matching_days     md ON md.year = pys.year AND md.total_days = pys.total_days
JOIN       patient           p  ON p.amka = pys.patient_amka
ORDER BY   pys.year, pys.total_days DESC, pys.patient_amka
SQL
    ],
    "q10" => [
        "title" => 'Q10 - Top 3 active substance pairs',
        "sql" => <<<'SQL'
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
LIMIT 3
SQL
    ],
    "q11" => [
        "title" => 'Q11 - Doctors at least 5 surgeries below top surgeon',
        "sql" => <<<'SQL'
WITH target_year AS (
  SELECT YEAR(start_datetime) AS year_value
  FROM   procedure_occurrence
  GROUP BY YEAR(start_datetime)
  HAVING COUNT(*) >= 30
  ORDER BY YEAR(start_datetime) DESC
  LIMIT 1
),
yearly_surgeries AS (
  SELECT
    po.main_surgeon_amka                        AS doctor_amka,
    COUNT(*)                                    AS surgeries_count
  FROM       procedure_occurrence po
  JOIN       target_year ty ON YEAR(po.start_datetime) = ty.year_value
  GROUP BY   po.main_surgeon_amka
),
top_surgeon AS (
  SELECT MAX(surgeries_count) AS max_surgeries FROM yearly_surgeries
)
SELECT
  ty.year_value                                  AS reference_year,
  ys.doctor_amka                                AS doctor_amka,
  st.first_name                                 AS first_name,
  st.last_name                                  AS last_name,
  d.specialty                                   AS specialty,
  d.rank                                        AS rank,
  ys.surgeries_count                            AS surgeries,
  ts.max_surgeries                              AS max_surgeries_in_year,
  (ts.max_surgeries - ys.surgeries_count)       AS difference
FROM       yearly_surgeries ys
CROSS JOIN top_surgeon       ts
CROSS JOIN target_year       ty
JOIN       doctor d  ON d.amka = ys.doctor_amka
JOIN       staff  st ON st.amka = ys.doctor_amka
WHERE      ts.max_surgeries - ys.surgeries_count >= 5
ORDER BY   ys.surgeries_count DESC, last_name
SQL
    ],
    "q12" => [
        "title" => 'Q12 - Staff per department/shift/week',
        "sql" => <<<'SQL'
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
WHERE      sh.shift_date BETWEEN '2026-03-02' AND '2026-03-08'
GROUP BY   d.name, sh.shift_date, sh.shift_type, staff_class, subclass
ORDER BY   d.name, sh.shift_date, sh.shift_type, staff_class, subclass
SQL
    ],
    "q13" => [
        "title" => 'Q13 - Doctor supervisor hierarchy',
        "sql" => <<<'SQL'
WITH RECURSIVE supervisor_chain AS (
  -- Anchor: κάθε ιατρός ως ξεκίνημα της αλυσίδας
  SELECT
    d.amka                                       AS doctor_amka,
    d.amka                                       AS current_amka,
    d.supervisor_amka                            AS supervisor_amka,
    d.rank                                       AS current_rank,
    0                                            AS level
  FROM       doctor d

  UNION ALL

  -- Recursive: ανέβα στην αλυσίδα έως το top
  SELECT
    sc.doctor_amka                               AS doctor_amka,
    d2.amka                                      AS current_amka,
    d2.supervisor_amka                           AS supervisor_amka,
    d2.rank                                      AS current_rank,
    sc.level + 1                                 AS level
  FROM       supervisor_chain sc
  JOIN       doctor d2 ON d2.amka = sc.supervisor_amka
  WHERE      sc.supervisor_amka IS NOT NULL
    AND      sc.level < 10  -- ασφάλεια έναντι κύκλων
)
SELECT
  sc.doctor_amka                                 AS doctor_amka,
  s_doc.first_name                               AS doctor_first_name,
  s_doc.last_name                                AS doctor_last_name,
  d_root.specialty                               AS doctor_specialty,
  d_root.rank                                    AS doctor_rank,
  sc.level                                       AS level,
  sc.current_amka                                AS supervisor_in_chain_amka,
  s_sup.first_name                               AS supervisor_first_name,
  s_sup.last_name                                AS supervisor_last_name,
  sc.current_rank                                AS supervisor_rank
FROM       supervisor_chain sc
JOIN       doctor d_root ON d_root.amka = sc.doctor_amka
JOIN       staff  s_doc  ON s_doc.amka  = sc.doctor_amka
JOIN       staff  s_sup  ON s_sup.amka  = sc.current_amka
WHERE      sc.level > 0  -- εξαιρούμε τον ίδιο τον ιατρό (level 0)
ORDER BY   sc.doctor_amka, sc.level
SQL
    ],
    "q14" => [
        "title" => 'Q14 - ICD10 categories with same admissions in consecutive years',
        "sql" => <<<'SQL'
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
ORDER BY   cy1.icd10_category, cy1.year
SQL
    ],
    "q15" => [
        "title" => 'Q15 - Triage statistics',
        "sql" => <<<'SQL'
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
ORDER BY   ts.urgency_level, dr.dept_referrals DESC
SQL
    ],
];

if (!array_key_exists($selected, $queries)) {
    $selected = "q01";
}

$current = $queries[$selected];

try {
    $stmt = $pdo->query($current["sql"]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $error = null;
} catch (PDOException $e) {
    $rows = [];
    $error = $e->getMessage();
}

function h($value) {
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Assignment Queries</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 30px; background: #f5f7fb; color: #172033; }
        .box { background: white; padding: 20px; border-radius: 12px; margin-bottom: 20px; box-shadow: 0 1px 4px rgba(0,0,0,0.06); }
        table { border-collapse: collapse; width: 100%; background: white; font-size: 14px; }
        th, td { border: 1px solid #ddd; padding: 8px; vertical-align: top; }
        th { background: #e9eef8; position: sticky; top: 0; }
        a { color: #123; }
        a.button { display: inline-block; margin: 4px; padding: 10px 12px; background: #e9eef8; color: #123; text-decoration: none; border-radius: 8px; }
        a.button:hover { background: #d6e2f5; }
        a.active { background: #c8d8f2; font-weight: bold; }
        .error { color: darkred; background: #ffecec; padding: 12px; border-radius: 8px; }
        .table-wrap { overflow-x: auto; }
        pre { white-space: pre-wrap; background: #f3f3f3; padding: 12px; border-radius: 8px; font-size: 13px; }
    </style>
</head>
<body>

<a href="index.php">Back</a>
<h1>Assignment Queries</h1>

<div class="box">
    <p>Select one of the assignment SQL queries:</p>
    <?php foreach ($queries as $key => $q): ?>
        <a class="button <?= $key === $selected ? 'active' : '' ?>" href="queries.php?q=<?= h($key) ?>">
            <?= h(strtoupper($key)) ?>
        </a>
    <?php endforeach; ?>
</div>

<div class="box">
    <h2><?= h($current["title"]) ?></h2>
    <details>
        <summary>Show SQL</summary>
        <pre><?= h($current["sql"]) ?></pre>
    </details>
</div>

<?php if ($error): ?>
    <div class="error">
        <strong>SQL Error:</strong><br>
        <?= h($error) ?>
    </div>
<?php else: ?>
    <p><strong>Rows returned:</strong> <?= count($rows) ?></p>

    <?php if (count($rows) === 0): ?>
        <p>No results returned.</p>
    <?php else: ?>
        <div class="table-wrap">
        <table>
            <tr>
                <?php foreach (array_keys($rows[0]) as $col): ?>
                    <th><?= h($col) ?></th>
                <?php endforeach; ?>
            </tr>

            <?php foreach ($rows as $r): ?>
                <tr>
                    <?php foreach ($r as $value): ?>
                        <td><?= h($value) ?></td>
                    <?php endforeach; ?>
                </tr>
            <?php endforeach; ?>
        </table>
        </div>
    <?php endif; ?>
<?php endif; ?>

</body>
</html>
