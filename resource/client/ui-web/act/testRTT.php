<?php
header('Content-Type: application/json; charset=utf-8');

function test_socket_rtt($host, $port = 443, $timeout = 2.0) {
    $start = microtime(true);
    $fp = @fsockopen($host, $port, $errno, $errstr, $timeout);
    if ($fp) {
        $rtt = round((microtime(true) - $start) * 1000);
        fclose($fp);
        return $rtt;
    }
    return -1;
}

$results = [
    "baidu"   => test_socket_rtt("www.baidu.com", 443, 1.5),
    "cf"      => test_socket_rtt("1.1.1.1", 443, 2.0),
    "google"  => test_socket_rtt("www.google.com", 443, 2.5),
    "youtube" => test_socket_rtt("www.youtube.com", 443, 2.5)
];

echo json_encode($results);
?>