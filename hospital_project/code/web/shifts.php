<?php
require_once "db.php";

$sql = "
SELECT 
    sh.shift_id,
    sh.shift_date,
    sh.shift_type,
    dep.name AS department,
    s.amka,
    s.first_name,
    s.last_name,
    s.staff_type
FROM shift_assignment sa
JOIN shift sh ON sh.shift_id = sa.shift_id
JOIN staff s ON s.amka = sa.staff_amka
JOIN department dep ON dep.department_id = sh.department_id
ORDER BY sh.shift_date, sh.shift_type, dep.name, s.staff_type
LIMIT 200
";

$stmt = $pdo->query($sql);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Shifts</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 30px; background: #f5f7fb; }
        table { border-collapse: collapse; width: 100%; background: white; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background: #e9eef8; }
        a { display: inline-block; margin-bottom: 20px; }
    </style>
</head>
<body>
<a href="index.php">Back</a>
<h1>Shift Assignments</h1>

<table>
<tr>
    <th>Shift ID</th>
    <th>Date</th>
    <th>Type</th>
    <th>Department</th>
    <th>AMKA</th>
    <th>First Name</th>
    <th>Last Name</th>
    <th>Staff Type</th>
</tr>

<?php foreach ($rows as $r): ?>
<tr>
    <td><?= htmlspecialchars($r["shift_id"]) ?></td>
    <td><?= htmlspecialchars($r["shift_date"]) ?></td>
    <td><?= htmlspecialchars($r["shift_type"]) ?></td>
    <td><?= htmlspecialchars($r["department"]) ?></td>
    <td><?= htmlspecialchars($r["amka"]) ?></td>
    <td><?= htmlspecialchars($r["first_name"]) ?></td>
    <td><?= htmlspecialchars($r["last_name"]) ?></td>
    <td><?= htmlspecialchars($r["staff_type"]) ?></td>
</tr>
<?php endforeach; ?>

</table>
</body>
</html>
