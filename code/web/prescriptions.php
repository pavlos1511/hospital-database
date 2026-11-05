<?php
require_once "db.php";

$sql = "
SELECT
    pr.prescription_id,
    pr.hospitalization_id,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    s.first_name AS doctor_first_name,
    s.last_name AS doctor_last_name,
    d.drug_name,
    pr.dosage,
    pr.frequency,
    pr.start_date,
    pr.end_date
FROM prescription pr
JOIN patient p ON p.amka = pr.patient_amka
JOIN staff s ON s.amka = pr.doctor_amka
JOIN drug d ON d.drug_id = pr.drug_id
ORDER BY pr.start_date DESC
LIMIT 150
";

$stmt = $pdo->query($sql);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Prescriptions</title>
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
<h1>Prescriptions</h1>

<table>
<tr>
    <th>ID</th>
    <th>Hospitalization</th>
    <th>Patient</th>
    <th>Doctor</th>
    <th>Drug</th>
    <th>Dosage</th>
    <th>Frequency</th>
    <th>Start</th>
    <th>End</th>
</tr>

<?php foreach ($rows as $r): ?>
<tr>
    <td><?= htmlspecialchars($r["prescription_id"]) ?></td>
    <td><?= htmlspecialchars($r["hospitalization_id"]) ?></td>
    <td><?= htmlspecialchars($r["patient_first_name"] . " " . $r["patient_last_name"]) ?></td>
    <td><?= htmlspecialchars($r["doctor_first_name"] . " " . $r["doctor_last_name"]) ?></td>
    <td><?= htmlspecialchars($r["drug_name"]) ?></td>
    <td><?= htmlspecialchars($r["dosage"]) ?></td>
    <td><?= htmlspecialchars($r["frequency"]) ?></td>
    <td><?= htmlspecialchars($r["start_date"]) ?></td>
    <td><?= htmlspecialchars($r["end_date"]) ?></td>
</tr>
<?php endforeach; ?>

</table>
</body>
</html>
