<?php
require_once "db.php";

$sql = "
SELECT 
    s.amka,
    s.first_name,
    s.last_name,
    s.email,
    d.specialty,
    d.rank
FROM staff s
JOIN doctor d ON d.amka = s.amka
ORDER BY d.specialty, d.rank, s.last_name
LIMIT 100
";

$stmt = $pdo->query($sql);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Doctors</title>
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
<h1>Doctors</h1>

<table>
<tr>
    <th>AMKA</th>
    <th>First Name</th>
    <th>Last Name</th>
    <th>Email</th>
    <th>Specialty</th>
    <th>Rank</th>
</tr>

<?php foreach ($rows as $r): ?>
<tr>
    <td><?= htmlspecialchars($r["amka"]) ?></td>
    <td><?= htmlspecialchars($r["first_name"]) ?></td>
    <td><?= htmlspecialchars($r["last_name"]) ?></td>
    <td><?= htmlspecialchars($r["email"]) ?></td>
    <td><?= htmlspecialchars($r["specialty"]) ?></td>
    <td><?= htmlspecialchars($r["rank"]) ?></td>
</tr>
<?php endforeach; ?>

</table>
</body>
</html>
