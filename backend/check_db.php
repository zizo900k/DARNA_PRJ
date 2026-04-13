<?php
try {
    $db = new PDO('mysql:host=127.0.0.1;port=3306;dbname=darna_db', 'root', '123456');
    $stmt = $db->query('SELECT id, email, created_at FROM users');
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    print_r($users);
    
    // Check validation manually
    echo "\nTotal users: " . count($users) . "\n";
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
}
