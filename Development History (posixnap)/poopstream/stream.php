<?php
	require ('streamjunk.php');

	function poopstream ($to_stream) {
        	$local_root = '/export/wyrm/mp3/incoming/tarballs/';
        	$tarname = "$local_root$to_stream";
        	$files = explode("\n", `tar tf $tarname`);
        	$root = 'http://envy.posixnap.net/~jimmy/mp3/'; //where the mp3s are stored
        
		`tar xf $tarname -C /home/jimmy/public_html/mp3`;
        
		header("Mime-version: 1.0\r\n");
        	header("Content-type: audio/x-mpegurl\r\n");
        	header("Content-Transfer-Encoding: 7bit\r\n");
        
		foreach ($files as $to_m3u) {
                	$to_m3u = str_replace("%2F","/",rawurlencode($to_m3u));
                	if ( substr($to_m3u,-4,1) == "." ) {
                        	echo "$root$to_m3u\r\n";
                	}
        	}
	}

	validate_tar ($tar);
        preg_replace("/&/","\\\&", rawurldecode($tar));

	poopstream ($tar);
?>
