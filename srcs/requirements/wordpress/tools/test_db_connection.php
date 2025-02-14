<?php
$host = getenv('MYSQL_HOST') ?: 'db';
$user = getenv('MYSQL_USER');
$pass = getenv('MYSQL_USER_PASSWORD');
$db   = getenv('MYSQL_DATABASE');

echo "Checking database connection...\n";
echo "Host: $host\n";
echo "User: $user\n";
echo "Database: $db\n";

$conn = @new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    echo "❌ Connection failed: " . $conn->connect_error . "\n";
    exit(1);
} else {
    echo "✅ Successfully connected to the database!\n";
}

$result = $conn->query("SHOW DATABASES;");
if ($result) {
    echo "Available databases:\n";
    while ($row = $result->fetch_assoc()) {
        echo "- " . $row['Database'] . "\n";
    }
} else {
    echo "❌ Failed to fetch databases: " . $conn->error . "\n";
}

$conn->close();
?>
