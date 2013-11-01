<html>
<head>
<link rel="stylesheet" href="purple.css" type="text/css">
</head>
<body>
<font face="tahoma,arial,fixed,monospaced,sans-serif" color=#005F70 size=-1>
<?php
function download_tar ($which_tar) {
        $local_root = '/export/wyrm/mp3/incoming/tarballs/';
        $tarname = "$local_root$which_tar";
        $files = explode("\n", `tar tf $tarname`);
        $root = 'http://envy.posixnap.net/~jimmy/mp3/'; //where the mp3s are stored
	$no_cr = preg_replace("/.tar/","",$v);
        $ins_spaces = preg_replace("/\_/", " ",$no_cr);

        `tar xf $tarname -C /home/jimmy/public_html/mp3`;
	echo "<h1>$no_cr</h1>";
	foreach ($files as $to_m3u) {
                $to_m3u = str_replace("%2F","/",rawurlencode($to_m3u));
                if ( substr($to_m3u,-4,1) == "." ) {
                        echo "<a href=$root$to_m3u class=artist>".rawurldecode($to_m3u)."</a><br>";
                }
        }
}

if ( substr($tar,-4) != ".tar" or preg_match("/[$|;<>()\r\n\/\\\]/", rawurldecode($tar)) ) {
                echo "<font color=#ff0000>need tar file</font>";
                die; 
        }

        preg_replace("/&/","\\\&", rawurldecode($tar));

download_tar ($tar);
?>
</font>
</body>
</html>
