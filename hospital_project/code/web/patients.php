<?php
require_once "db.php";

$sql = "
SELECT amka, first_name, last_name, age, gender, insurance_provider
FROM patient
ORDER BY last_name, first_name
LIMIT 100
";

$stmt = $pdo->query($sql);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Patients</title>
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
<h1>Patients</h1>

<table>
<tr>
    <th>AMKA</th>
    <th>First Name</th>
    <th>Last Name</th>
    <th>Age</th>
    <th>Gender</th>
    <th>Insurance</th>
</tr>

<?php foreach ($rows as $r): ?>
<tr>
    <td><?= htmlspecialchars($r["amka"]) ?></td>
    <td><?= htmlspecialchars($r["first_name"]) ?></td>
    <td><?= htmlspecialchars($r["last_name"]) ?></td>
    <td><?= htmlspecialchars($r["age"]) ?></td>
    <td><?= htmlspecialchars($r["gender"]) ?></td>
    <td><?= htmlspecialchars($r["insurance_provider"]) ?></td>
</tr>
<?php endforeach; ?>

</table>
</body>
</html>
