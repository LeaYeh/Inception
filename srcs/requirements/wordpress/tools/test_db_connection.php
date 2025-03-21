<?php
$host = getenv('DB_HOST') ?: 'db';
$user = getenv('WP_ADMIN') ?: 'wordpress';
$pass_file = getenv('WP_ADMIN_PASSWORD_FILE') ?: '/run/secrets/wp_admin_password';
$pass = file_exists($pass_file) ? file_get_contents($pass_file) : getenv('WP_ADMIN_PASSWORD');
$db   = getenv('WP_DATABASE') ?: 'wordpress';

echo "Checking database connection...\n";
echo "Host: $host\n";
echo "User: $user\n";
echo "Database: $db\n";
echo "Password: |$pass|\n";

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
