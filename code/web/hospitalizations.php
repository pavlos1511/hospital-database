<?php
require_once "db.php";

$sql = "
SELECT
    h.hospitalization_id,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    dep.name AS department,
    h.admission_date,
    h.discharge_date,
    h.admission_icd10_code,
    h.discharge_icd10_code,
    h.ken_code,
    h.total_cost,
    s.first_name AS doctor_first_name,
    s.last_name AS doctor_last_name
FROM hospitalization h
JOIN patient p ON p.amka = h.patient_amka
JOIN department dep ON dep.department_id = h.department_id
JOIN staff s ON s.amka = h.primary_doctor_amka
ORDER BY h.admission_date DESC
LIMIT 150
";

$stmt = $pdo->query($sql);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Hospitalizations</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 30px; background: #f5f7fb; }
        table { border-collapse: collapse; width: 100%; background: white; font-size: 14px; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background: #e9eef8; }
        a { display: inline-block; margin-bottom: 20px; }
    </style>
</head>
<body>
<a href="index.php">Back</a>
<h1>Hospitalizations</h1>

<table>
<tr>
    <th>ID</th>
    <th>Patient</th>
    <th>Department</th>
    <th>Admission</th>
    <th>Discharge</th>
    <th>Admission ICD-10</th>
    <th>Discharge ICD-10</th>
    <th>KEN</th>
    <th>Total Cost</th>
    <th>Primary Doctor</th>
</tr>

<?php foreach ($rows as $r): ?>
<tr>
    <td><?= htmlspecialchars($r["hospitalization_id"]) ?></td>
    <td><?= htmlspecialchars($r["patient_first_name"] . " " . $r["patient_last_name"]) ?></td>
    <td><?= htmlspecialchars($r["department"]) ?></td>
    <td><?= htmlspecialchars($r["admission_date"]) ?></td>
    <td><?= htmlspecialchars($r["discharge_date"]) ?></td>
    <td><?= htmlspecialchars($r["admission_icd10_code"]) ?></td>
    <td><?= htmlspecialchars($r["discharge_icd10_code"]) ?></td>
    <td><?= htmlspecialchars($r["ken_code"]) ?></td>
    <td><?= htmlspecialchars($r["total_cost"]) ?></td>
    <td><?= htmlspecialchars($r["doctor_first_name"] . " " . $r["doctor_last_name"]) ?></td>
</tr>
<?php endforeach; ?>

</table>
</body>
</html>
