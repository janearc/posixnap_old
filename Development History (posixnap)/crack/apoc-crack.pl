#!/usr/bin/perl -w
# Apoc-Crack.pl by Adam Rogoyski (apoc@laker.net) Temperanc on EFNet irc
# Copyright (C) 1997 Adam Rogoyski
# Simple brute force attack on a unix encrypted password. checks all
# printable 7-bit ascii characters.  
# give it a file on the command line containing just an encrypted pw.
# warning: this program may take thousands of years to finish one run.
# bash-2.00$ ./apoc-crack.pl happy.pw
# --- GNU General Public License Disclamer ---
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

use strict;
my ($encrypted, $salt, $temp, $flag, $i, $j, $k, $l, $m, $n, $o, $p, $beep);
$encrypted = <>;
$salt = substr($encrypted, 0, 2);
$temp = "";
$flag = 0;
for ($i = 33; $i < 126; $i++)
{
   $temp = crypt( chr($i), $salt);
   if ($encrypted eq $temp)
   {
      $beep = chr(7);
      printf "$encrypted = %s $beep\n", chr($i);
      $flag = 1;
      last;
   }   
}
if ($flag) { exit 0; }
else { print "Password is at least 2 Characters Long\n"; }

for ($i = 33; $i < 126; $i++) {
   if ($flag) { exit 0; }
for ($j = 33; $j < 126; $j++)
{
   $temp = crypt( chr($i) . chr($j), $salt);
   if ($encrypted eq $temp)
   {
      $beep = chr(7);
      printf "$encrypted = %s $beep\n", chr($i) . chr($j);
      $flag = 1;
      last;
   }
} }
if ($flag) { exit 0; }
else { print "Password is at least 3 Characters Long\n"; }

for ($i = 33; $i < 126; $i++) {
for ($j = 33; $j < 126; $j++) {
   if ($flag) { exit 0; }
for ($k = 33; $k < 126; $k++)
{
   $temp = crypt( chr($i) . chr($j) . chr($k), $salt);
   if ($encrypted eq $temp)
   {
      $beep = chr(7);
      printf "$encrypted = %s $beep\n", chr($i) . chr($j) . chr($k);
      $flag = 1;
      last;
   }
} } }
if ($flag) { exit 0; }
else { print "Password is at least 4 Characters Long\n"; }




for ($i = 33; $i < 126; $i++) {
for ($j = 33; $j < 126; $j++) {
for ($k = 33; $k < 126; $k++) {
   if ($flag) { exit 0; }
for ($l = 33; $l < 126; $l++) 
{
   $temp = crypt( chr($i) . chr($j) . chr($k) . chr($l), $salt);
   if ($encrypted eq $temp)
   {
      $beep = chr(7);
      printf "$encrypted = %s $beep\n", chr($i) . chr($j) . chr($k) 
                                      . chr($l);
      $flag = 1;
      last;
   }
} } } }
if ($flag) { exit 0; }
else { print "Password is at least 5 Characters Long\n"; }



for ($i = 33; $i < 126; $i++) {
for ($j = 33; $j < 126; $j++) {
for ($k = 33; $k < 126; $k++) {
for ($l = 33; $l < 126; $l++) {
   if ($flag) { exit 0; }
for ($m = 33; $m < 126; $m++)
{
   $temp = crypt( chr($i) . chr($j) . chr($k) . chr($l)
                . chr($m), $salt);
   if ($encrypted eq $temp)
   {
      $beep = chr(7);
      printf "$encrypted = %s $beep\n", chr($i) . chr($j) . chr($k) 
                                      . chr($l) . chr($m);
      $flag = 1;
      last;
   }
} } } } }
if ($flag) { exit 0; }
else { print "Password is at least 6 Characters Long\n"; }



for ($i = 33; $i < 126; $i++) {
for ($j = 33; $j < 126; $j++) {
for ($k = 33; $k < 126; $k++) {
for ($l = 33; $l < 126; $l++) {
for ($m = 33; $m < 126; $m++) {
   if ($flag) { exit 0; }
for ($n = 33; $n < 126; $n++)
{
   $temp = crypt( chr($i) . chr($j) . chr($k) . chr($l)
                . chr($m) . chr($n), $salt);
   if ($encrypted eq $temp)
   {
      $beep = chr(7);
      printf "$encrypted = %s $beep\n", chr($i) . chr($j) . chr($k) 
                                      . chr($l) . chr($m) . chr($n);
      $flag = 1;
      last;
   }
} } } } } }
if ($flag) { exit 0; }
else { print "Password is at least 7 Characters Long\n"; }



for ($i = 33; $i < 126; $i++) {
for ($j = 33; $j < 126; $j++) {
for ($k = 33; $k < 126; $k++) {
for ($l = 33; $l < 126; $l++) {
for ($m = 33; $m < 126; $m++) {
for ($n = 33; $n < 126; $n++) {
   if ($flag) { exit 0; }
for ($o = 33; $o < 126; $o++)
{
   $temp = crypt( chr($i) . chr($j) . chr($k) . chr($l)
                . chr($m) . chr($n) . chr($o), $salt);
   if ($encrypted eq $temp)
   {
      $beep = chr(7);
      printf "$encrypted = %s $beep\n", chr($i) . chr($j) . chr($k) 
                                      . chr($l) . chr($m) . chr($n)
                                      . chr($o);
      $flag = 1;
      last;
   }
} } } } } } }
if ($flag) { exit 0; }
else { print "Password is at least 8 Characters Long\n"; }



for ($i = 33; $i < 126; $i++) {
for ($j = 33; $j < 126; $j++) {
for ($k = 33; $k < 126; $k++) {
for ($l = 33; $l < 126; $l++) {
for ($m = 33; $m < 126; $m++) {
for ($n = 33; $n < 126; $n++) {
for ($o = 33; $o < 126; $o++) {
   if ($flag) { exit 0; }
for ($p = 33; $p < 126; $p++)
{
   $temp = crypt( chr($i) . chr($j) . chr($k) . chr($l)
                . chr($m) . chr($n) . chr($o) . chr($p), $salt);
   if ($encrypted eq $temp)
   {
      $beep = chr(7);
      printf "$encrypted = %s $beep\n", chr($i) . chr($j) . chr($k) 
                                      . chr($l) . chr($m) . chr($n)
                                      . chr($o) . chr($p);
      $flag = 1;
      last;
   }
} } } } } } } }
if ($flag) { exit 0; }
else { print "Password uses characters other than 7-bit Ascii\n"; }

exit 0;
