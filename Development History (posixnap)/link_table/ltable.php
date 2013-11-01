<?php

	// Parse with sections
	$CONF = parse_ini_file("at.ini", TRUE);
	$HEADING = $CONF[HEADINGS];
	
	define ("START_PAGE","
	<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">
	<html>
		<head>
		<style type=\"text/css\">
			body \{
				margin-top: 75px;
				margin-bottom: 75px;
				margin-left: 150px;
				margin-right: 150px;
			}
			a:link {
				color: $CONF[TABLE_LINKSFG];
			}
			a:visited {
				color: $CONF[TABLE_LINKSFG];
			}
			a:active {
				color: $CONF[TABLE_LINKSFG];
			}
		</style>
		<title>$PAGE_TITLE</title>
	</head>
	
	<body bgcolor=$CONF[BACKGROUND_COLOR]>
		<font face=$CONF[PAGE_FONT] color=$CONF[FOREGROUND_COLOR]>
			<h1>$CONF[PAGE_HEADING]</h1>");
	
	define ("END_PAGE","
		</font>
	</body>");

	echo START_PAGE;

	echo "
		
			<font size=-2>
				<table cellpadding=0 width=\"100%\" border=0>

				<tr valign=\"center\">
					<td width=\"42%\" bgcolor=$CONF[TABLE_HEADINGBG]>
						<font color=$CONF[TABLE_HEADINGFG] size=-1><center>
							$HEADING[0]
						</font></center>
					</td>
					<td width=\"16%\" bgcolor=$CONF[BACKGROUND_COLOR]>
					</td>
					<td width=\"42%\" bgcolor=$CONF[TABLE_HEADINGBG]>
						<font color=$CONF[TABLE_HEADINGFG] size=-1><center>
							$HEADING[1]
						</font></center>
					</td>
				</tr>
				<tr valign=\"top\">
					<td>";

					foreach ($CONF['BOX1'] as $link) {
						echo "<a href=\"$link\">$link<BR>";
					}

					echo "</td>
					<td></td>
					<td>";

					foreach ($CONF['BOX2'] as $link) {
						echo "<a href=\"$link\">$link<BR>";
					}
					echo "</td>
				</tr>
				<tr valign=\"center\">
					<td width=\"42%\" bgcolor=$CONF[TABLE_HEADINGBG]>
						<font color=$CONF[TABLE_HEADINGFG] size=-1><center>
							$HEADING[2]
						</font></center>
					</td>
					<td width=\"16%\" bgcolor=$CONF[BACKGROUND_COLOR]>
					</td>
					<td width=\"42%\" bgcolor=$CONF[TABLE_HEADINGBG]>
						<font color=$CONF[TABLE_HEADINGFG] size=-1><center>
							$HEADING[3]
						</font></center>
					</td>
				</tr>
				<tr valign=\"top\">
					<td>";

					foreach ($CONF['BOX3'] as $link) {
						echo "<a href=\"$link\">$link<BR>";
					} 
					echo "</td>
					<td></td>
					<td>";

					foreach ($CONF['BOX4'] as $link) {
						echo "<a href=\"$link\">$link<BR>";
					}
					echo "</td>
				</tr>
				<tr valign=\"center\">
					<td width=\"42%\" bgcolor=$CONF[TABLE_HEADINGBG]>
						<font color=$CONF[TABLE_HEADINGFG] size=-1><center>
							$HEADING[4]
						</font></center>
					</td>
					<td width=\"16%\" bgcolor=$CONF[BACKGROUND_COLOR]>
					</td>
					<td width=\"42%\" bgcolor=$CONF[TABLE_HEADINGBG]>
						<font color=$CONF[TABLE_HEADINGFG] size=-1><center>
							$HEADING[5]
						</font></center>
					</td>
				</tr>
				<tr valign=\"top\">
					<td>";

					foreach ($CONF['BOX5'] as $link) {
						echo "<a href=\"$link\">$link<BR>";
					} 
					echo "</td>
					<td></td>
					<td>";

					foreach ($CONF['BOX6'] as $link) {
						echo "<a href=\"$link\">$link<BR>";
					}
					echo "</td>
				</tr>

				</table>
			</font>
	";
	
	echo END_PAGE;
?>
