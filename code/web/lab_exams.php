<?php
require_once "db.php";

$sql = "
SELECT
    le.exam_id,
    le.hospitalization_id,
    let.exam_name,
    let.exam_type,
    le.exam_date,
    le.result_text,
    le.numeric_value,
    le.unit,
    le.cost,
    s.first_name AS doctor_first_name,
    s.last_name AS doctor_last_name
FROM lab_exam le
JOIN lab_exam_type let ON let.exam_code = le.exam_code
JOIN staff s ON s.amka = le.doctor_amka
ORDER BY le.exam_date DESC
LIMIT 150
";

$stmt = $pdo->query($sql);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Lab Exams</title>
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
<h1>Lab Exams</h1>

<table>
<tr>
    <th>Exam ID</th>
    <th>Hospitalization</th>
    <th>Exam Name</th>
    <th>Type</th>
    <th>Date</th>
    <th>Result</th>
    <th>Numeric Value</th>
    <th>Unit</th>
    <th>Cost</th>
    <th>Doctor</th>
</tr>

<?php foreach ($rows as $r): ?>
<tr>
    <td><?= htmlspecialchars($r["exam_id"]) ?></td>
    <td><?= htmlspecialchars($r["hospitalization_id"]) ?></td>
    <td><?= htmlspecialchars($r["exam_name"]) ?></td>
    <td><?= htmlspecialchars($r["exam_type"]) ?></td>
    <td><?= htmlspecialchars($r["exam_date"]) ?></td>
    <td><?= htmlspecialchars($r["result_text"]) ?></td>
    <td><?= htmlspecialchars($r["numeric_value"]) ?></td>
    <td><?= htmlspecialchars($r["unit"]) ?></td>
    <td><?= htmlspecialchars($r["cost"]) ?></td>
    <td><?= htmlspecialchars($r["doctor_first_name"] . " " . $r["doctor_last_name"]) ?></td>
</tr>
<?php endforeach; ?>

</table>
</body>
</html>
