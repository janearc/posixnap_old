<?php   
	require ('streamjunk.php');

	validate_tar ($to_tf);
	$decoded_tf = preg_replace("/&/","\\\&", rawurldecode($to_tf));

        $tar_cmd = `tar tf /export/wyrm/mp3/incoming/tarballs/$decoded_tf`;
	echo "<title>$decoded_tf</title><pre><font face=\"tahoma,arial,fixed,monospaced,sans-serif\" color=11750694><font size=+1><b><u>$decoded_tf</u></b>

</font>$tar_cmd</font></pre>";
?>
