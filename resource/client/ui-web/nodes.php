<?php require_once('auth.php'); ?>
<?php if (isset($auth) && $auth) {?>
<!DOCTYPE html>
<html>

<head>

  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <meta name="description" content="de_GWD Node Management">
  <meta name="author" content="JacyL4 & NextGen">

  <title>节点管理 - de_GWD</title>

  <!-- Custom fonts for this template-->
  <link href="vendor/fontawesome-free/css/all.min.css" rel="stylesheet" type="text/css">
  
  <!-- Custom styles for this template-->
  <link href="css/sb-admin.css" rel="stylesheet">

  <link href="favicon.ico" rel="icon" type="image/x-icon" />

  <!-- Bootstrap core JavaScript-->
  <script src="vendor/jquery/jquery.min.js"></script>
  <script src="vendor/bootstrap/js/bootstrap.bundle.min.js"></script>

  <!-- Core plugin JavaScript-->
  <script src="vendor/jquery-easing/jquery.easing.min.js"></script>

</head>

<body id="page-top" class="sidebar-toggled">
<?php $de_GWDconf = json_decode(@file_get_contents('/opt/de_GWD/0conf')); ?>
<?php $checkJellyfin = isset($de_GWDconf->app->jellyfin) ? $de_GWDconf->app->jellyfin : false; ?>
<?php $checkFileRun = file_exists('/var/www/html/filerun'); ?>
<?php $checkBitwarden = isset($de_GWDconf->app->bitwarden) ? $de_GWDconf->app->bitwarden : false; ?>

<?php 
  $FileRunPort = "80";
  if (file_exists('/etc/nginx/conf.d/filerun.conf')) {
      $FileRunWebConf = @file_get_contents('/etc/nginx/conf.d/filerun.conf'); 
      if (preg_match('/listen\s+(\d+)/i', $FileRunWebConf, $m)) { $FileRunPort = $m[1]; }
  }
  $serverName = "de_GWD";
  if (file_exists('/etc/nginx/conf.d/default.conf')) {
      $WebConf = @file_get_contents('/etc/nginx/conf.d/default.conf'); 
      if (preg_match('/server_name\s+([^;]+);/i', $WebConf, $m)) { $serverName = trim($m[1]); }
  }
?>
  <nav class="navbar navbar-expand navbar-dark bg-dark static-top">

    <a class="navbar-brand mr-1" href="index.php">寒月</a>
    <button class="btn btn-sm btn-outline-light mx-3" data-toggle="modal" data-target="#markThis">备注本机</button>

    <button id="sidebarToggle" class="btn btn-link btn-sm text-white order-1 order-sm-0" href="javascript:void(0)">
      <i class="fas fa-bars"></i>
    </button>
    <span class="float-right badge text-info"><?php @passthru('sudo /opt/de_GWD/ui-checkEditionARM 2>/dev/null');?></span>

    <!-- Navbar Search -->
    <form class="d-none d-md-inline-block form-inline ml-auto mr-0 mr-md-3 my-2 my-md-0">
    </form>

    <!-- Navbar -->
    <ul class="nav navbar-nav ml-auto ml-md-0">
      <li class="nav-item no-arrow mx-1" style="display:<?php if ($checkFileRun === true) echo 'block'; else echo 'none';?>">
        <a class="nav-link" href="javascript:void(0)" onclick="window.open(<?php if ($serverName != "de_GWD") echo "'https://$serverName:$FileRunPort'"; else echo "location.origin+':$FileRunPort'" ?>)">
          <i class="fas fa-folder"></i>
          <span>FileRun</span>
        </a>
      </li>

      <li class="nav-item no-arrow mx-1" style="display:<?php if ($checkJellyfin === 'installed') echo 'block'; else echo 'none';?>">
        <a class="nav-link" href="javascript:void(0)" onclick="window.open(location.origin+':8097')">
          <i class="fab fa-youtube"></i>
          <span>Jellyfin</span>
        </a>
      </li>

      <li class="nav-item no-arrow mx-1" style="display:<?php if ($checkBitwarden === 'installed') echo 'block'; else echo 'none';?>">
        <a class="nav-link" href="javascript:void(0)" onclick="window.open(location.origin+':8099')">
          <i class="fas fa-shield-alt"></i>
          <span>Bitwarden</span>
        </a>
      </li>
      
      <li class="nav-item no-arrow mx-1">
        <a class="nav-link" href="/admin/" onclick="javascript:event.target.port=location.port" target="_blank">
          <i class="fab fa-raspberry-pi"></i>
          <span>Pi-Hole</span>
        </a>
      </li>
    </ul>

  </nav>

  <div id="wrapper">

    <!-- Sidebar -->
    <ul class="sidebar navbar-nav toggled">
      <li class="nav-item">
        <a class="nav-link" href="index.php">
          <i class="fas fa-tachometer-alt"></i>
          <span>概览</span>
        </a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="forward.php">
          <i class="fas fa-project-diagram"></i>
          <span>中转</span></a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="ddns.php">
          <i class="fas fa-ethernet"></i>
          <span>DDNS & Wireguard</span></a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="app.php">
          <i class="fab fa-app-store-ios"></i>
          <span>应用</span></a>
      </li>
      <li class="nav-item active">
        <a class="nav-link" href="nodes.php">
          <i class="fas fa-stream"></i>
          <span>节点管理</span></a>
      </li>
      <li class="nav-item">
        <a class="nav-link" href="update.php">
          <i class="fas fa-arrow-alt-circle-up"></i>
          <span>更新</span></a>
      </li>
      <li class="nav-item">
        <a id="buttonLogout" class="nav-link" href="javascript:void(0)">
          <i class="fas fa-sign-out-alt"></i>
          <span>注销</span></a>
      </li>
    </ul>

    <div id="content-wrapper" class="mx-auto" style="max-width: 1600px;">

      <div class="container-fluid">

        <!-- Breadcrumbs-->
        <ol class="breadcrumb">
          <li class="breadcrumb-item">
            <a href="index.php">概览</a>
          </li>
          <li class="breadcrumb-item active">节点管理</li>
        </ol>

        <!-- Modal 备注本机 -->
        <div id="markThis" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="markThisLabel" aria-hidden="true">
          <div class="modal-dialog">
            <div class="modal-content">
              <div class="modal-header">
                <h5 id="markThisLabel" class="modal-title">备注本机</h5>
              </div>
              <div class="modal-body">
                <input id="markName" type="text" class="form-control" placeholder="备注名" required="required" value="<?php echo isset($de_GWDconf->address->alias) ? $de_GWDconf->address->alias : ''; ?>">
              </div>
              <div class="modal-footer">
                <button id="buttonMarkThis" type="button" class="btn btn-outline-dark btn-sm">应用</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Modal 快捷导入链接 (VLESS-REALITY / Hysteria 2 / VMess / Trojan) -->
        <div id="importLinkModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
          <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content">
              <div class="modal-header bg-dark text-white">
                <h5 class="modal-title"><i class="fas fa-file-import text-info"></i> 导入节点链接 (支持 VLESS-REALITY / Hy2 / VMess / Trojan)</h5>
                <button type="button" class="close text-white" data-dismiss="modal">&times;</button>
              </div>
              <div class="modal-body">
                <p class="text-muted small">支持直接粘贴单个或多个节点链接 (如 <code>vless://...</code>, <code>hysteria2://...</code>)，将自动识别协议、地址、端口、UUID/密码与 REALITY 参数并追加到节点列表。</p>
                <textarea id="importLinkText" class="form-control" rows="5" placeholder="请在此粘贴节点链接，例如：&#10;vless://uuid@server.com:443?security=reality&pbk=...&sni=www.microsoft.com&sid=...&fp=chrome&flow=xtls-rprx-vision#我的节点&#10;hysteria2://password@server.com:8443/?insecure=1&sni=degwd.network#Hy2节点"></textarea>
              </div>
              <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">取消</button>
                <button id="buttonDoImport" type="button" class="btn btn-info btn-sm"><i class="fas fa-check"></i> 解析并导入</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Modal 协议高级参数编辑 (VLESS-REALITY / Hy2 / VMess) -->
        <div id="advSettingsModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
          <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
              <div class="modal-header bg-dark text-white">
                <h5 class="modal-title"><i class="fas fa-cogs text-warning"></i> 节点协议高级参数</h5>
                <button type="button" class="close text-white" data-dismiss="modal">&times;</button>
              </div>
              <div class="modal-body">
                <input type="hidden" id="advRowIndex" value="">
                
                <div class="form-group">
                  <label class="small font-weight-bold">协议类型</label>
                  <select id="advProto" class="form-control form-control-sm" onchange="advProtoChanged()">
                    <option value="vless">VLESS-REALITY (推荐 · 抗封锁免证书)</option>
                    <option value="hysteria2">Hysteria 2 (推荐 · 极速抗丢包)</option>
                    <option value="vmess">VMess (经典兼容)</option>
                    <option value="trojan">Trojan (TLS 伪装)</option>
                  </select>
                </div>

                <!-- REALITY Options -->
                <div id="advRealityGroup">
                  <div class="form-group mb-2">
                    <label class="small font-weight-bold text-success">伪装域名 (SNI / ServerName)</label>
                    <input type="text" id="advSni" class="form-control form-control-sm" placeholder="例如: www.microsoft.com 或 gateway.icloud.com">
                  </div>
                  <div class="form-group mb-2">
                    <label class="small font-weight-bold text-success">公钥 (Public Key / pbk)</label>
                    <input type="text" id="advPbk" class="form-control form-control-sm" placeholder="REALITY x25519 公钥">
                  </div>
                  <div class="form-group mb-2">
                    <label class="small font-weight-bold text-success">Short ID (sid)</label>
                    <input type="text" id="advSid" class="form-control form-control-sm" placeholder="8字节十六进制 short_id">
                  </div>
                  <div class="form-group mb-2">
                    <label class="small font-weight-bold text-success">流控 (Flow)</label>
                    <select id="advFlow" class="form-control form-control-sm">
                      <option value="xtls-rprx-vision">xtls-rprx-vision (极速内核 Splice)</option>
                      <option value="">none (无流控)</option>
                    </select>
                  </div>
                </div>

                <!-- Hysteria 2 Options -->
                <div id="advHy2Group" style="display:none;">
                  <div class="form-group mb-2">
                    <label class="small font-weight-bold text-primary">认证密码 (Password)</label>
                    <input type="text" id="advHy2Pass" class="form-control form-control-sm" placeholder="Hysteria 2 认证密码">
                  </div>
                  <div class="form-check mb-2">
                    <input class="form-check-input" type="checkbox" id="advInsecure" checked>
                    <label class="form-check-label small" for="advInsecure">
                      跳过证书验证 (Insecure · 适用于自签证书)
                    </label>
                  </div>
                </div>

              </div>
              <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">取消</button>
                <button id="buttonSaveAdv" type="button" class="btn btn-primary btn-sm"><i class="fas fa-save"></i> 确定应用</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Page Content -->
        <div class="card mb-3">
          <div class="card-header">
            <i class="fas fa-stream"></i>
            节点编辑
            <span class="float-right mt-n1 mb-n2">
              <button id="buttonImportModalOpen" type="button" class="btn btn-info btn-sm mt-1" style="border-radius: 0px;" data-toggle="modal" data-target="#importLinkModal">
                <i class="fas fa-file-import"></i> 导入链接
              </button>

              <button id="buttonAddLine" type="button" class="btn btn-secondary btn-sm mt-1" style="border-radius: 0px;">
                <i class="fas fa-plus"></i> 添加
              </button>

              <button id="buttonSaveNode" type="button" class="btn btn-primary btn-sm mt-1" style="border-radius: 0px;">
                <span id="buttonSaveNodeLoading"></span>
                <span><i class="fas fa-save"></i> 保存全部</span>
              </button>
            </span>
          </div>
          <div class="card-body">
            <div class="table-responsive">
              <table class="table table-bordered table-striped text-center text-nowrap my-2">
                <thead>
                  <tr>
                    <th class="text-nowrap text-center">序号</th>
                    <th class="text-nowrap text-center">协议</th>
                    <th class="text-nowrap text-center"><———— 节点地址与端口 ————></th>
                    <th class="text-nowrap text-center"><———— 节点名称 ————></th>
                    <th class="text-nowrap text-center"><———— UUID / 密码 ————></th>
                    <th class="text-nowrap text-center"><—— PATH / 伪装SNI ——></th>
                    <th class="text-nowrap text-center">协议详情</th>
                    <th class="text-nowrap text-center"><i class="fas fa-caret-square-up fa-lg"></i></th>
                    <th class="text-nowrap text-center"><i class="fas fa-caret-square-down fa-lg"></i></th>
                    <th class="text-nowrap text-center"><i class="fas fa-trash-alt fa-lg"></i></th>
                  </tr>
                </thead>
                <tbody id="nodeTable">
<?php 
$nodes = isset($de_GWDconf->v2node) ? $de_GWDconf->v2node : [];
for( $i=0; $i<count($nodes); $i++){
  $num = $i+1;
  $proto = isset($nodes[$i]->proto) ? $nodes[$i]->proto : (isset($nodes[$i]->pbk) ? 'vless' : 'vmess');
  $domain = isset($nodes[$i]->domain) ? $nodes[$i]->domain : '';
  $tls = isset($nodes[$i]->tls) ? $nodes[$i]->tls : '';
  $name = isset($nodes[$i]->name) ? $nodes[$i]->name : '';
  $path = isset($nodes[$i]->path) ? $nodes[$i]->path : '';
  $uuid = isset($nodes[$i]->uuid) ? $nodes[$i]->uuid : '';
  $sni = isset($nodes[$i]->sni) ? $nodes[$i]->sni : ($tls ? $tls : 'www.microsoft.com');
  $pbk = isset($nodes[$i]->pbk) ? $nodes[$i]->pbk : '';
  $sid = isset($nodes[$i]->sid) ? $nodes[$i]->sid : '';
  $flow = isset($nodes[$i]->flow) ? $nodes[$i]->flow : 'xtls-rprx-vision';
  $hy2_pass = isset($nodes[$i]->hy2_pass) ? $nodes[$i]->hy2_pass : $uuid;
  $insecure = isset($nodes[$i]->insecure) ? $nodes[$i]->insecure : '1';

  $protoBadge = '<span class="badge badge-secondary">VMess</span>';
  if ($proto === 'vless') {
      $protoBadge = '<span class="badge badge-success">VLESS-REALITY</span>';
  } elseif ($proto === 'hysteria2') {
      $protoBadge = '<span class="badge badge-primary">Hysteria 2</span>';
  } elseif ($proto === 'trojan') {
      $protoBadge = '<span class="badge badge-info">Trojan</span>';
  }
?>
<tr data-proto="<?php echo htmlspecialchars($proto); ?>"
    data-sni="<?php echo htmlspecialchars($sni); ?>"
    data-pbk="<?php echo htmlspecialchars($pbk); ?>"
    data-sid="<?php echo htmlspecialchars($sid); ?>"
    data-flow="<?php echo htmlspecialchars($flow); ?>"
    data-hy2pass="<?php echo htmlspecialchars($hy2_pass); ?>"
    data-insecure="<?php echo htmlspecialchars($insecure); ?>">
  <td class="align-middle"><?php echo $num; ?></td>
  <td class="align-middle"><?php echo $protoBadge; ?></td>
  <td class="align-middle">
    <div class="input-group">
      <input type="text" class="form-control" value="<?php echo htmlspecialchars($domain); ?>">
      <div class="input-group-append">
        <button type="button" class="btn btn-secondary btn-sm" value="<?php echo htmlspecialchars($tls); ?>" onclick="commitTls(this)">TLS</button>
      </div>
    </div>
  </td>
  <td class="align-middle"><input type="text" class="form-control" value="<?php echo htmlspecialchars($name); ?>"></td>
  <td class="align-middle"><input type="text" class="form-control" value="<?php echo htmlspecialchars($uuid); ?>"></td>
  <td class="align-middle"><input type="text" class="form-control" value="<?php echo htmlspecialchars($path); ?>"></td>
  <td class="align-middle">
    <button type="button" class="btn btn-outline-info btn-sm" style="border-radius: 0px;" onclick="openAdvModal(this)">
      <i class="fas fa-sliders-h"></i> 参数
    </button>
  </td>
  <td class="align-middle"><button type="button" class="form-control btn btn-outline-secondary btn-sm" style="border-radius: 0px;" onclick="moveUp(this)"><i class="fas fa-caret-up"></i></button></td>
  <td class="align-middle"><button type="button" class="form-control btn btn-outline-secondary btn-sm" style="border-radius: 0px;" onclick="moveDown(this)"><i class="fas fa-caret-down"></i></button></td>
  <td class="align-middle"><button type="button" class="form-control btn btn-outline-danger btn-sm" style="border-radius: 0px;" onclick="deleteRow(this)"><i class="fas fa-trash-alt"></i></button></td>
</tr>
<?php } ?>
                </tbody>
              </table>
            </div>
          </div>
        </div>

      </div>
      <!-- /.container-fluid -->

      <!-- Sticky Footer -->
      <footer class="sticky-footer">
        <div class="container my-auto">
          <div class="copyright text-center my-auto">
            <span>Copyright © de_GWD NextGen by JacyL4 2017 ~ 2026</span>
          </div>
        </div>
      </footer>

    </div>
    <!-- /.content-wrapper -->

  </div>
  <!-- /#wrapper -->

<script>
// TLS Modal
function commitTls(btn){
  var i = $(btn).closest('tr').find('td').first().text();
  var tlsValue = $(btn).val();
  var modalId = 'commitTlsModal' + i;
  $('#' + modalId).remove();
  $('body').append(`
    <div id="${modalId}" class="modal fade" role="dialog" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
          <div class="modal-header bg-dark text-white py-2">
            <h6 class="modal-title">TLS 域名设置 (第 ${i} 行)</h6>
            <button type="button" class="close text-white" data-dismiss="modal">&times;</button>
          </div>
          <div class="modal-body">
            <div class="input-group">
              <input id="serverName${i}" type="text" class="form-control" value="${tlsValue}" placeholder="例如: yourdomain.com">
              <div class="input-group-append">
                <button id="serverNameSave${i}" type="button" class="btn btn-secondary btn-sm">保存</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `);
  $('#' + modalId).modal('show');

  $('#serverNameSave' + i).click(function(){
    var val = $('#serverName' + i).val();
    $(btn).val(val);
    $('#' + modalId).modal('hide');
  });
}

// Advanced Settings Modal
var currentAdvTr = null;
function openAdvModal(btn) {
  currentAdvTr = $(btn).closest('tr');
  var proto = currentAdvTr.attr('data-proto') || 'vless';
  var sni = currentAdvTr.attr('data-sni') || 'www.microsoft.com';
  var pbk = currentAdvTr.attr('data-pbk') || '';
  var sid = currentAdvTr.attr('data-sid') || '';
  var flow = currentAdvTr.attr('data-flow') || 'xtls-rprx-vision';
  var hy2pass = currentAdvTr.attr('data-hy2pass') || currentAdvTr.find('td').eq(4).find('input').val();
  var insecure = currentAdvTr.attr('data-insecure') !== '0';

  $('#advProto').val(proto);
  $('#advSni').val(sni);
  $('#advPbk').val(pbk);
  $('#advSid').val(sid);
  $('#advFlow').val(flow);
  $('#advHy2Pass').val(hy2pass);
  $('#advInsecure').prop('checked', insecure);

  advProtoChanged();
  $('#advSettingsModal').modal('show');
}

function advProtoChanged() {
  var proto = $('#advProto').val();
  if (proto === 'vless') {
    $('#advRealityGroup').show();
    $('#advHy2Group').hide();
  } else if (proto === 'hysteria2') {
    $('#advRealityGroup').hide();
    $('#advHy2Group').show();
  } else {
    $('#advRealityGroup').hide();
    $('#advHy2Group').hide();
  }
}

$('#buttonSaveAdv').click(function(){
  if (!currentAdvTr) return;
  var proto = $('#advProto').val();
  var sni = $('#advSni').val();
  var pbk = $('#advPbk').val();
  var sid = $('#advSid').val();
  var flow = $('#advFlow').val();
  var hy2pass = $('#advHy2Pass').val();
  var insecure = $('#advInsecure').is(':checked') ? '1' : '0';

  currentAdvTr.attr('data-proto', proto);
  currentAdvTr.attr('data-sni', sni);
  currentAdvTr.attr('data-pbk', pbk);
  currentAdvTr.attr('data-sid', sid);
  currentAdvTr.attr('data-flow', flow);
  currentAdvTr.attr('data-hy2pass', hy2pass);
  currentAdvTr.attr('data-insecure', insecure);

  // Update badge
  var badge = '<span class="badge badge-secondary">VMess</span>';
  if (proto === 'vless') {
    badge = '<span class="badge badge-success">VLESS-REALITY</span>';
  } else if (proto === 'hysteria2') {
    badge = '<span class="badge badge-primary">Hysteria 2</span>';
  } else if (proto === 'trojan') {
    badge = '<span class="badge badge-info">Trojan</span>';
  }
  currentAdvTr.find('td').eq(1).html(badge);

  // If path column is empty and we have sni, suggest it
  if (sni && !currentAdvTr.find('td').eq(5).find('input').val()) {
    currentAdvTr.find('td').eq(5).find('input').val(sni);
  }

  $('#advSettingsModal').modal('hide');
});

// Row movement
function moveUp(obj) { 
  var current = $(obj).closest('tr');
  var prev = current.prev();
  if (prev.length > 0) { 
    current.insertBefore(prev);
    reindexRows();
  }
}

function moveDown(obj) { 
  var current = $(obj).closest('tr');
  var next = current.next();
  if (next.length > 0) { 
    current.insertAfter(next);
    reindexRows();
  }
}

function deleteRow(obj) {
  if (confirm("确定要删除此节点吗？")) {
    $(obj).closest('tr').remove();
    reindexRows();
  }
}

function reindexRows() {
  $('#nodeTable tr').each(function(idx){
    $(this).find('td').first().text(idx + 1);
  });
}

// Parse and import URI link
$('#buttonDoImport').click(function(){
  var rawText = $('#importLinkText').val().trim();
  if (!rawText) {
    alert("请粘贴节点链接！");
    return;
  }
  var lines = rawText.split('\n');
  var importedCount = 0;

  lines.forEach(function(line){
    line = line.trim();
    if (!line) return;

    if (line.startsWith('vless://')) {
      try {
        var parsed = parseVless(line);
        appendParsedNode(parsed);
        importedCount++;
      } catch(e) { console.error("解析 VLESS 失败:", e); }
    } else if (line.startsWith('hysteria2://') || line.startsWith('hy2://')) {
      try {
        var parsed = parseHy2(line);
        appendParsedNode(parsed);
        importedCount++;
      } catch(e) { console.error("解析 Hy2 失败:", e); }
    } else {
      alert("不支持的链接格式: " + line.substring(0, 30));
    }
  });

  if (importedCount > 0) {
    $('#importLinkText').val('');
    $('#importLinkModal').modal('hide');
    reindexRows();
    alert("成功导入 " + importedCount + " 个节点！请点击 [保存全部] 保存生效。");
  }
});

function parseVless(uri) {
  var hashIdx = uri.indexOf('#');
  var tag = "VLESS-节点";
  if (hashIdx !== -1) {
    tag = decodeURIComponent(uri.substring(hashIdx + 1));
    uri = uri.substring(0, hashIdx);
  }
  var url = new URL(uri);
  var uuid = url.username;
  var domain = url.hostname + ":" + (url.port || 443);
  var params = url.searchParams;

  return {
    proto: 'vless',
    domain: domain,
    name: tag,
    uuid: uuid,
    path: params.get('path') || '',
    tls: params.get('sni') || url.hostname,
    sni: params.get('sni') || url.hostname,
    pbk: params.get('pbk') || '',
    sid: params.get('sid') || '',
    flow: params.get('flow') || 'xtls-rprx-vision',
    hy2pass: '',
    insecure: '0'
  };
}

function parseHy2(uri) {
  var hashIdx = uri.indexOf('#');
  var tag = "Hy2-节点";
  if (hashIdx !== -1) {
    tag = decodeURIComponent(uri.substring(hashIdx + 1));
    uri = uri.substring(0, hashIdx);
  }
  var url = new URL(uri);
  var pass = url.username || url.password;
  var domain = url.hostname + ":" + (url.port || 8443);
  var params = url.searchParams;

  return {
    proto: 'hysteria2',
    domain: domain,
    name: tag,
    uuid: pass,
    path: '',
    tls: params.get('sni') || url.hostname,
    sni: params.get('sni') || url.hostname,
    pbk: '',
    sid: '',
    flow: '',
    hy2pass: pass,
    insecure: (params.get('insecure') === '1' || params.get('insecure') === 'true') ? '1' : '0'
  };
}

function appendParsedNode(n) {
  var i = $("#nodeTable tr").length + 1;
  var badge = '<span class="badge badge-success">VLESS-REALITY</span>';
  if (n.proto === 'hysteria2') badge = '<span class="badge badge-primary">Hysteria 2</span>';

  $('#nodeTable').append(`
    <tr data-proto="${n.proto}"
        data-sni="${n.sni}"
        data-pbk="${n.pbk}"
        data-sid="${n.sid}"
        data-flow="${n.flow}"
        data-hy2pass="${n.hy2pass}"
        data-insecure="${n.insecure}">
      <td class="align-middle">${i}</td>
      <td class="align-middle">${badge}</td>
      <td class="align-middle">
        <div class="input-group">
          <input type="text" class="form-control" value="${n.domain}">
          <div class="input-group-append">
            <button type="button" class="btn btn-secondary btn-sm" value="${n.tls}" onclick="commitTls(this)">TLS</button>
          </div>
        </div>
      </td>
      <td class="align-middle"><input type="text" class="form-control" value="${n.name}"></td>
      <td class="align-middle"><input type="text" class="form-control" value="${n.uuid}"></td>
      <td class="align-middle"><input type="text" class="form-control" value="${n.path || n.sni}"></td>
      <td class="align-middle">
        <button type="button" class="btn btn-outline-info btn-sm" style="border-radius: 0px;" onclick="openAdvModal(this)">
          <i class="fas fa-sliders-h"></i> 参数
        </button>
      </td>
      <td class="align-middle"><button type="button" class="form-control btn btn-outline-secondary btn-sm" style="border-radius: 0px;" onclick="moveUp(this)"><i class="fas fa-caret-up"></i></button></td>
      <td class="align-middle"><button type="button" class="form-control btn btn-outline-secondary btn-sm" style="border-radius: 0px;" onclick="moveDown(this)"><i class="fas fa-caret-down"></i></button></td>
      <td class="align-middle"><button type="button" class="form-control btn btn-outline-danger btn-sm" style="border-radius: 0px;" onclick="deleteRow(this)"><i class="fas fa-trash-alt"></i></button></td>
    </tr>
  `);
}

$(function(){
  $('#buttonLogout').click(function(){
    $.get('auth.php', {logout:'true'}, function(){ window.location.href="index.php"; });
  });

  $('#buttonMarkThis').click(function(){
    var markNametxt = $('#markName').val();
    $.get('./act/markThis.php', {markName:markNametxt}, function(){ window.location.reload(); });
  });

  $('#buttonAddLine').click(function(){
    var i = $("#nodeTable tr").length + 1;
    $('#nodeTable').append(`
      <tr data-proto="vless" data-sni="www.microsoft.com" data-pbk="" data-sid="" data-flow="xtls-rprx-vision" data-hy2pass="" data-insecure="1">
        <td class="align-middle">${i}</td>
        <td class="align-middle"><span class="badge badge-success">VLESS-REALITY</span></td>
        <td class="align-middle">
          <div class="input-group">
            <input type="text" class="form-control" placeholder="example.com:443" value="">
            <div class="input-group-append">
              <button type="button" class="btn btn-secondary btn-sm" value="" onclick="commitTls(this)">TLS</button>
            </div>
          </div>
        </td>
        <td class="align-middle"><input type="text" class="form-control" placeholder="节点名称" value="新节点"></td>
        <td class="align-middle"><input type="text" class="form-control" placeholder="UUID / 密码" value=""></td>
        <td class="align-middle"><input type="text" class="form-control" placeholder="www.microsoft.com" value="www.microsoft.com"></td>
        <td class="align-middle">
          <button type="button" class="btn btn-outline-info btn-sm" style="border-radius: 0px;" onclick="openAdvModal(this)">
            <i class="fas fa-sliders-h"></i> 参数
          </button>
        </td>
        <td class="align-middle"><button type="button" class="form-control btn btn-outline-secondary btn-sm" style="border-radius: 0px;" onclick="moveUp(this)"><i class="fas fa-caret-up"></i></button></td>
        <td class="align-middle"><button type="button" class="form-control btn btn-outline-secondary btn-sm" style="border-radius: 0px;" onclick="moveDown(this)"><i class="fas fa-caret-down"></i></button></td>
        <td class="align-middle"><button type="button" class="form-control btn btn-outline-danger btn-sm" style="border-radius: 0px;" onclick="deleteRow(this)"><i class="fas fa-trash-alt"></i></button></td>
      </tr>
    `);
  });

  $('#buttonSaveNode').click(function(){
    $("#buttonSaveNodeLoading").attr("class", "spinner-border spinner-border-sm");
    var nodeList = [];
    var trList = $("#nodeTable").children("tr");
    var len = trList.length;

    for (let i = 0; i < len; i++){
      var tr = trList.eq(i);
      var tdArr = tr.find("td");
      var domain = tdArr.eq(2).find('input').val().trim();
      var tls = tdArr.eq(2).find('button').val().trim();
      var name = tdArr.eq(3).find('input').val().trim();
      var uuid = tdArr.eq(4).find('input').val().trim();
      var path = tdArr.eq(5).find('input').val().trim();

      var proto = tr.attr('data-proto') || 'vless';
      var sni = tr.attr('data-sni') || (path ? path : (tls ? tls : domain.split(':')[0]));
      var pbk = tr.attr('data-pbk') || '';
      var sid = tr.attr('data-sid') || '';
      var flow = tr.attr('data-flow') || '';
      var hy2_pass = tr.attr('data-hy2pass') || uuid;
      var insecure = tr.attr('data-insecure') || '1';

      if (!tls) tls = sni || domain.split(':')[0];

      if (domain !== '' && name !== '' && uuid !== '') {
        nodeList.push({
          domain: domain,
          tls: tls,
          name: name,
          uuid: uuid,
          path: path,
          proto: proto,
          sni: sni,
          pbk: pbk,
          sid: sid,
          flow: flow,
          hy2_pass: hy2_pass,
          insecure: insecure
        });
      }
    }

    $.get("./act/NodeSave.php", {nodeList: nodeList}, function(result){
      $("#buttonSaveNodeLoading").removeClass();
      window.location.href = "index.php";
    });
  });
});
</script>

  <!-- Custom scripts for all pages-->
  <script src="js/sb-admin.min.js"></script>
  
</body>

</html>
<?php } ?>
<?php if(!isset($auth) || !$auth){ header('Location: login.php'); } ?>