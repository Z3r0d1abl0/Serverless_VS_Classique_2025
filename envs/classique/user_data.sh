#!/bin/bash
# Script user-data avec test DB PHP (Amazon Linux 2023 + PHP 8.x)
export LC_ALL=C
export LANG=C
# Log tout
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Debut script user-data avec DB"
date
# Mise a jour et installation
yum update -y
yum install -y httpd php php-mysqlnd
# Page simple qui marche
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Server OK</title></head>
<body>
<h1>Server Running</h1>
<p>Instance OK</p>
<p>Time: <script>document.write(new Date().toLocaleString())</script></p>
<p><a href="/db-test.php">Test Database</a></p>
</body>
</html>
EOF
# Health check simple
echo "OK" > /var/www/html/health
# Test DB en PHP (MySQL 8.0 + PHP 8.x) - CORRIGE
cat > /var/www/html/db-test.php << 'EOF'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
 http_response_code(200);
 exit();
}
$start_time = microtime(true);
try {
 // Configuration DB depuis variables Terraform
 $host = '${db_endpoint}';
 $dbname = '${db_name}';
 $username = '${db_username}';
 $password = '${db_password}';
 // Connexion MySQL 8.0 avec charset utf8mb4 (PHP 8.x)
 $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password, [
 PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
 PDO::ATTR_TIMEOUT => 10
 ]);
 
 $query_start = microtime(true);
 
 // SELECT corrigé - syntaxe MySQL valide sur une ligne
 $stmt = $pdo->prepare("SELECT NOW() as db_time, CONNECTION_ID() as connection_id, VERSION() as mysql_version, (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = ?) as table_count, @@read_only as read_only_status");
 $stmt->execute([$dbname]);
 $result = $stmt->fetch(PDO::FETCH_ASSOC);
 
 $query_end = microtime(true);
 $query_time = round(($query_end - $query_start) * 1000, 2);
 
 $end_time = microtime(true);
 $response_time = round(($end_time - $start_time) * 1000, 2);
 
 // Instance ID avec gestion d'erreur
 $instance_id = false;
 try {
   $context = stream_context_create(['http' => ['timeout' => 2]]);
   $instance_id = file_get_contents('http://169.254.169.254/latest/meta-data/instance-id', false, $context);
 } catch (Exception $e) {
   $instance_id = 'unavailable';
 }
 
 echo json_encode([
   'status' => 'success',
   'message' => 'Database connection successful',
   'action' => 'select',
   'architecture' => 'classic',
   'result' => [
     'current_time' => $result['db_time'],
     'connection_id' => (int)$result['connection_id'],
     'mysql_version' => $result['mysql_version'],
     'table_count' => (int)$result['table_count'],
     'read_only_status' => (int)$result['read_only_status'],
     'query_time_ms' => $query_time
   ],
   'response_time_ms' => $response_time,
   'instance_id' => $instance_id,
   'timestamp' => date('Y-m-d H:i:s')
 ]);
} catch (Exception $e) {
 $end_time = microtime(true);
 $response_time = round(($end_time - $start_time) * 1000, 2);
 http_response_code(500);
 echo json_encode([
   'status' => 'error',
   'message' => $e->getMessage(),
   'response_time_ms' => $response_time,
   'architecture' => 'classic',
   'timestamp' => date('Y-m-d H:i:s')
 ]);
}
?>
EOF
# CORS qui marche
cat > /etc/httpd/conf.d/cors.conf << 'EOF'
LoadModule headers_module modules/mod_headers.so
LoadModule rewrite_module modules/mod_rewrite.so
<IfModule mod_headers.c>
 Header always set Access-Control-Allow-Origin "*"
 Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS, HEAD"
 Header always set Access-Control-Allow-Headers "Content-Type, Authorization"
 Header always set Access-Control-Max-Age "3600"
</IfModule>
<Directory "/var/www/html">
 AllowOverride All
 Options Indexes FollowSymLinks
 Require all granted
</Directory>
EOF
# Demarrage Apache
systemctl enable httpd
systemctl start httpd
# Verification
sleep 3
systemctl status httpd
curl -I http://localhost/health
curl -s http://localhost/db-test.php || echo "DB test failed - normal on first boot"
echo "Fin script user-data"
date