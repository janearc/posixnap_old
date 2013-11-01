<html>
<head>
<link rel="stylesheet" href="purple.css" type="text/css">
</head>         
<title>streamer</title><body><img src="poopstream.gif"></img><br>
<font face="tahoma,arial,fixed,monospaced,sans-serif" color=#005F70 size=-1>
<?php
function SplitNow($split_pat,$s,$n) {

        $vals = preg_split($split_pat,$s,$n);
        array_shift($vals);
        $i=1;
        
        foreach ($vals as $v) {
                $no_cr = preg_replace("/\x0A/","",$v);
                $no_amp = rawurlencode($no_cr);
                $ins_spaces = preg_replace("/\_/", " ",$no_cr);
                $no_tar = preg_replace("/\.tar/","",$ins_spaces);

                echo "$i. <a href=\"orange.php?to_tf=$no_amp\" class=artist>$no_tar</a>".
                "&nbsp;|&nbsp;<a href=\"stream.php?tar=$no_amp\" class=artist>stream</a>&nbsp;".
                "|&nbsp;<a href=\"dl_tar.php?tar=$no_amp&extract=1\" class=download>download (ind.)</a><br>";
                $i++;
       }
}

$str = `ls -1 /export/wyrm/mp3/incoming/tarballs`;

$splitter='/(?=^[A-Za-z0-9])/m'; // split at any letter or number

$vals = preg_split($splitter,$str); // split into array 
$num = count($vals); // and get number of elements

SplitNow($splitter,$str,$num); 

?>
</font></body></html>
