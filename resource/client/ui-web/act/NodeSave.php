<?php require_once('../auth.php'); ?>
<?php if (isset($auth) && $auth) {?>
<?php
$confPath = '/opt/de_GWD/0conf';
$conf = file_exists($confPath) ? json_decode(file_get_contents($confPath), true) : [];
if (!is_array($conf)) {
    $conf = [];
}

$nodeList = isset($_REQUEST['nodeList']) ? $_REQUEST['nodeList'] : [];

$conf['v2node'] = $nodeList;
$newJsonString = json_encode($conf, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
file_put_contents($confPath, $newJsonString);

// Trigger node configuration compilation & reload
exec('sudo /opt/de_GWD/ui-NodeSave r >/dev/null 2>&1 &');

echo json_encode(["status" => "ok", "count" => count($nodeList)]);
?>
<?php } ?>