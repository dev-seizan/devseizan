<?php
// DevSeizan - IP Logger

$ip = $_SERVER['REMOTE_ADDR'];
$user_agent = $_SERVER['HTTP_USER_AGENT'];
$date = date("Y-m-d H:i:s");

$data = "Date: $date\nIP: $ip\nUser-Agent: $user_agent\n--------------------\n";

file_put_contents("ip.txt", $data, LOCK_EX);
?>