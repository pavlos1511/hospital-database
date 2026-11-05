<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>About - Ygeiopolis Hospital DB</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f7fb; }
        .container { max-width: 900px; margin: auto; background: white; padding: 30px; border-radius: 12px; }
        a { display: inline-block; margin-bottom: 20px; color: #123; text-decoration: none; }
        .section { margin-top: 25px; }
        .tag { display: inline-block; padding: 4px 8px; border-radius: 999px; background: #edf2ff; font-size: 13px; margin-bottom: 15px; }
        ul { line-height: 1.7; }
        code { background: #f1f1f1; padding: 2px 5px; border-radius: 4px; }
    </style>
</head>
<body>
<div class="container">
    <a href="index.php">Back to Home</a>

    <h1>About the Web UI</h1>
    <span class="tag">PHP + MariaDB + XAMPP</span>

    <p>
        This web interface was developed for the Ygeiopolis Hospital database project.
        It provides a simple way to interact with the MariaDB database through a browser,
        without using phpMyAdmin.
    </p>

    <div class="section">
        <h2>Main Functionality</h2>
        <ul>
            <li>Browse patients, doctors and shift assignments.</li>
            <li>View hospitalizations, lab exams and prescriptions.</li>
            <li>Execute the assignment SQL queries Q01-Q15 through a web page.</li>
            <li>Display query results in HTML tables.</li>
        </ul>
    </div>

    <div class="section">
        <h2>Technology Stack</h2>
        <ul>
            <li>Frontend: HTML and CSS</li>
            <li>Backend: PHP</li>
            <li>Database: MariaDB / MySQL</li>
            <li>Local server: XAMPP Apache</li>
        </ul>
    </div>

    <div class="section">
        <h2>Database Connection</h2>
        <p>
            The database connection is defined in <code>db.php</code>.
            The application connects to the <code>ygeiopolis_db</code> database
            and executes SQL queries using PDO.
        </p>
    </div>

    <div class="section">
        <h2>Purpose</h2>
        <p>
            The purpose of this web UI is to demonstrate interaction with the implemented
            hospital database schema. It supports basic data browsing and execution of
            the required assignment queries directly from the browser.
        </p>
    </div>
</div>
</body>
</html>
