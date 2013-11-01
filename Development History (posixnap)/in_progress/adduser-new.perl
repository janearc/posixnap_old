#!/usr/bin/perl
#
#	$OpenBSD: adduser.perl,v 1.39 2002/07/10 19:57:31 millert Exp $
#
# Copyright (c) 1995-1996 Wolfram Schneider <wosch@FreeBSD.org>. Berlin.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $From: adduser.perl,v 1.22 1996/12/07 21:25:12 ache Exp $

# TODO: pass 'use warnings' and 'use strict'. we're using perl 5.8 now. 
# this script looks a lot like it did in 1996.

use IPC::Open2;
use Fcntl qw(:DEFAULT :flock);

################
# main
#
my $test = 0;			# test mode, only for development
my $check_only = 0;
my %config;			# switch configs to a hash - tyler

$SIG{'INT'} = \&cleanup;
$SIG{'QUIT'} = \&cleanup;
$SIG{'HUP'} = \&cleanup;
$SIG{'TERM'} = \&cleanup;

die "You are not root!\n" if $< && !$test; 

### set_defaults sets default variables, which read_config supercedes and
### command line arguments are able to override.
set_defaults();			# initialize variables
read_config(@ARGV);		# read variables from config-file
parse_arguments(@ARGV);	# parse arguments

# XXX: these variables need to be defined
if (!$check_only &&  $#batch < 0) {
    hints();
}

# check
my $changes = 0;
variable_check();		# check for valid variables
passwd_check();			# check for valid passwdb
shells_read();			# read /etc/shells
passwd_read();			# read /etc/master.passwd
group_read();			# read /etc/group
group_check();			# check for incon*
exit 0 if $check_only;		# only check consistence and exit

exit(! batch(@batch)) if $#batch >= 0; # batch mode

# Interactive:
# main loop for creating new users
new_users();	     # add new users

#end


# Set adduser "default" variables internally before groking config file
# Adduser.conf supercedes these

#    I'm temporarily leaving behind the old defines whilst we convert 
#    to a hash. The problem with this is a really unmanageable set
#    of configs. And its hard on the eyes - tyler

sub set_defaults {
	# initialize default %config values
    $config{verbose} = 1;						# verbosity [0-2]
    $config{defaultpasswd} = "yes";				# user password for new users
    $config{dotdir} = "/etc/skel";				# copy default files from here
    $config{dotdir_bak} = $config{dotdir};		# XXX: but why?
    $config{send_message} = "no";				# send message to new users?
    $config{send_message_bak} = '/etc/adduser.message';

    $config{configfile} = "/etc/adduser.conf";	# config file for adduser
    $config{config_read} = 1;					# read config file
    $config{logfile} = "/var/log/adduser";		# logfile
    $config{home} = "/home";					# default location for home directories
    $config{etc_shells} = "/etc/shells";
    $config{etc_passwd} = "/etc/master.passwd";
    $config{etc_ptmp} = "/etc/ptmp";
    $config{group_file} = "/etc/group";			# XXX: appears unused
    $config{pwd_mkdb_cmd} = "pwd_mkdb -p";		# program for building passwd database
    $config{encryptionmethod} = "blowfish";		# one of 'md5', 'des', 'blowfish' or 'old'
    $config{rcsid} = '$OpenBSD: adduser.perl,v 1.39 2002/07/10 19:57:31 millert Exp $';

    # List of directories where shells located
    $config{path} = [ '/bin', '/usr/bin', '/usr/local/bin' ];

    # common shells, first element has higher priority
    $config{shellpref} = [ 'csh', 'sh', 'tcsh', 'ksh', 'bash' ];

    $config{encryption_methods} = [ 'blowfish', 'md5', 'des', 'old' ];

    $config{defaultshell} = 'csh';				# default shell if not empty
    $config{group_uniq} = 'USER';				# XXX: what on earth is this?

	# XXX: lose this var.
    $defaultgroup = $config{group_uniq};		# login groupname, $group_uniq means username

    $config{uid_start} = 1000;					# new users get this uid
    $config{uid_end}   = 2147483647;			# max. uid

    $config{username} = {};						# convert a username to a uid.
    $config{uid} = {}; 							# convert a uid to a username.
	# XXX: what ???
    $config{pwgid} = {};						# $config{pwgid} -> {pwgid} = username; gid from passwd db

	# XXX: i'm guessing this can go away.
    $config{password} = '';						# password for new users

    # group
	$config{groupname} = {};					# convert a groupname to a gid
	$config{groupmembers} = {};					# convert a gid to a comma delimited string.
	$config{gid} = {};							# convert a gid to a groupname

    # shell
    %shell = ();		# $shell{`basename sh`} = sh

    # only for me (=Wolfram)
    if ($test) {
	$config{home} = "/home/w/tmp/adduser/home";
	$config{etc_shells} = "./shells";
	$config{etc_passwd} = "./master.passwd";
	$config{group_file} = "./group";
	$config{pwd_mkdb_file} = "pwd_mkdb -p -d .";
	$config{configfile} = "adduser.conf";
	$config{send_message} = "./adduser.message";
	$config{logfile} = "./log.adduser";
    }

    umask 022;			# don't give login group write access

    $ENV{PATH} = "/sbin:/bin:/usr/sbin:/usr/bin";
    @passwd_backup = ();
    @group_backup = ();
    @message_buffer = ();
    @user_variable_list = ();	# user variables in /etc/adduser.conf
    $do_not_delete = '## DO NOT DELETE THIS LINE!';
}

# read shell database, see also: shells(5)
sub shells_read {
	my ($sh, $err);

	warn "Reading ".$config{etc_shells}."\n" if $config{verbose};
	open SHELLS, "<".$config{etc_shells}
		or die $config{etc_shells}.": $!\n";

	while(chomp (my $line = <SHELLS>)) {
		next if $line =~ /^#/;
		$line =~ s/\s//g;
		if (not -e $line) {
			warn "shell $line does not exist, skipping.\n";
			++$err;
			next;
		}
		elsif (not -x $line) {
			warn "shell $line is not executable, skipping.\n";
			++$err;
			next;
		}
		$shell{ &basename( $line ) } = $line;
	}

    &shell_pref_add("nologin");
    $shell{"nologin"} = "/sbin/nologin";

    return $err;
}

# add new shells if possible
sub shells_add {
    local($sh,$dir,@list);

    return 1 unless $config{verbose};

    foreach $sh (@{ $config{shellpref} }) {
	# all known shells
	if (!$shell{$sh}) {
	    # shell $sh is not defined as login shell
	    foreach $dir (@{ $config{path} }) {
		if (-x "$dir/$sh") {
		    # found shell
		    if (confirm_yn("Found shell: $dir/$sh. Add to ".$config{etc_shells}."?", "y")) {
			push(@list, "$dir/$sh");
			&shell_pref_add("$sh");
			$shell{&basename("$dir/$sh")} = "$dir/$sh";
			$changes++;
		    }
		}
	    }
	}
    }
    append_file($config{etc_shells}, @list) if $#list >= 0;
}

# add shell to preference list without duplication
sub shell_pref_add {
    local($new_shell) = @_;
    local($shell);

    foreach $shell (@{ $config{shellpref} }) {
	return if ($shell eq $new_shell);
    }
    push(@{ $config{shellpref} }, $new_shell);
}

# choose your favourite shell and return the shell
sub shell_default {
    local($e,$i,$new_shell);
    local($sh);

    $sh = &shell_default_valid($config{defaultshell});
    return $sh unless $config{verbose};

    $new_shell = &confirm_list("Enter your default shell:", 0,
		       $sh, sort(keys %shell));
    print "Your default shell is: $new_shell -> ".$shell{$new_shell}."\n";
    $changes++ if $new_shell ne $sh;
    return $new_shell;
}

sub shell_default_valid {
    local($sh) = @_;
    local($s,$e);

    return $sh if $shell{$sh};

    foreach $e (@{ $config{shellpref} }) {
	$s = $e;
	last if defined($shell{$s});
    }
    $s = "sh" unless $s;
    warn "Shell ``$sh'' is undefined, use ``$s''\n";
    return $s;
}

# return default home partition (f.e. "/home")
# create base directory if necessary 
sub home_partition {
	my $home = $config{home};
    my $h = stripdir($home);

	if (not $config{verbose} and ($h eq home_partition_valid($h))) {
		return $h;
	}

    while(1) {
		$h = confirm_list("Enter your default home partition:", 1, $home, "");
		$h = stripdir($h);
		last if $h eq home_partition_valid($h);
    }

    $changes++ if $h ne $home;
    return $h;
}

sub home_partition_valid {
    local($h) = @_;

    $h = &stripdir($h);
    # all right (I hope)
    return $h if $h =~ "^/" && -e $h && -w _ && (-d _ || -l $h);

    # Errors or todo
    if ($h !~ "^/") {
	warn "Please use absolute path for home: ``$h''.\a\n";
	return 0;
    }

    if (-e $h) {
	warn "$h exists, but is not a directory or symlink!\n"
	    unless -d $h || -l $h;
	warn "$h is not writable!\n"
	    unless -w $h;
	return 0;
    } else {
	# create home partition
	return $h if &mkdir_home($h);
    }
    return 0;
}

# check for valid passwddb
sub passwd_check {
	# XXX: what in the HELL is going on here?
    system( split(/\s+/, $config{pwd_mkdb_cmd}." -c ".$config{etc_passwd}));
    die "\nInvalid ".$config{etc_passwd}." - cannot add any users!\n" if $?;
}

# read /etc/passwd
sub passwd_read {
    local($p_username, $pw, $p_uid, $p_gid, $sh);

    warn "Checking ".$config{etc_passwd}."\n" if $config{verbose};

    open P, "<".$config{etc_passwd} 
		or die $config{etc_passwd}.": $!\n";

    # we only use this to lock the password file
    sysopen PTMP, $config{etc_ptmp}, O_RDWR|O_CREAT|O_EXCL, 0600 
		or die "Password file busy\n";

    while(<P>) {
	chomp;
	push(@passwd_backup, $_);
	($p_username, $pw, $p_uid, $p_gid, $sh) = (split(/:/, $_))[0..3,9];

	if ($config{username} -> {$p_username} and $config{verbose}) {
		warn "$p_username already exists with uid: ".$config{username} -> {$p_username}."!\n"
	}
	$config{username} -> {$p_username} = $p_uid;
	warn "User $p_username: uid $p_uid exists twice: ".$config{uid} -> {$p_uid}."\n"
	    if $config{uid} -> {$p_uid} && $config{verbose} && $p_uid;    # don't warn for uid 0
	warn "User $p_username: illegal shell: ``$sh''\n"
	    if ($config{verbose} && $sh &&
		!$shell{&basename($sh)} &&
		$p_username !~ /^(news|xten|bin|nobody|uucp)$/ &&
		$sh !~ /\/(pppd|sliplogin)$/);
	$config{uid} -> {$p_uid} = $p_username;
	$config{pwgid} -> {$p_gid} = $p_username;
    }
    close P;
}

# read /etc/group
sub group_read {
    local($g_groupname,$pw,$g_gid, $memb);

    warn "Checking $group\n" if $config{verbose};
    open(G, "$group") || die "$group: $!\n";
    while(<G>) {
	chomp;
	push(@group_backup, $_);
	($g_groupname, $pw, $g_gid, $memb) = (split(/:/, $_))[0..3];

	$config{groupmembers} -> {$g_gid} = $memb;
	warn "Groupname exists twice: $g_groupname:$g_gid ->  $g_groupname:".$config{groupname} -> {$g_groupname}."\n"
	    if $config{groupname} -> {$g_groupname} && $config{verbose};
	$config{groupname} -> {$g_groupname} = $g_gid;
	warn "Groupid exists twice:   $g_groupname:$g_gid -> ".$config{gid} -> {$g_gid}.":$g_gid\n"
	    if $config{gid} -> {$g_gid} && $config{verbose};
	$config{gid} -> {$g_gid} = $g_groupname;
    }
    close G;
}

# check gids /etc/passwd <-> /etc/group
sub group_check {
    local($c_gid, $c_username, @list);

    foreach $c_gid (keys %pwgid) {
	if (!$config{gid} -> {$c_gid}) {
	    $c_username = $config{pwgid} -> {$c_gid};
	    warn "User ``$c_username'' has gid $c_gid but a group with this " .
		"gid does not exist.\n" if $config{verbose};
	}
    }
}

#
# main loop for creating new users
#

# return username
sub new_users_name {

	# get their initial answer
	my $name = &confirm_list("Enter username", 1, "a-z0-9_-", "");

	# if they gave us something hokey
    while( &new_users_name_valid($name) ne $name ) {
		$name = &confirm_list("Enter username", 1, "a-z0-9_-", "");
		if (length($name) > 31) {
	    	warn "Username cannot exceed 31 characters\a\n";
	    	next;
		}
    }
    return $name;
}

sub new_users_name_valid {
    my ($name) = shift;

	# "a-z0-9_-" is the character class we've given them, they might
	# enter this on accident (!) so we make sure to not allow it.
    if ($name !~ /^[a-z0-9_][-a-z0-9_]*$/ or $name eq "a-z0-9_-") {
		warn "Illegal username. " .
	    	"Please use only lowercase characters or digits\a\n";
		return 0;
    } 
	elsif ($config{username} -> {$name}) {
		warn "Username ``$name'' already exists!\a\n"; 
		return 0;
    }
    return $name;
}

# return full name
sub new_users_fullname {
    local($name) = @_;
    local($fullname);

    while(1) {
	$fullname = &confirm_list("Enter full name", 1, "", "");
	last if $fullname eq &new_users_fullname_valid($fullname);
    }
    $fullname = $name unless $fullname;
    return $fullname;
}

sub new_users_fullname_valid {
    local($fullname) = @_;

    return $fullname if $fullname !~ /:/;

    warn "``:'' is not allowed!\a\n";
    return 0;
}

# return shell (full path) for user
sub new_users_shell {
    local($sh);

    $sh = &confirm_list("Enter shell", 0, $config{defaultshell}, keys %shell);
    return $shell{$sh};
}

# return free uid and gid
sub new_users_id {
    local($name) = @_;
    local($u_id, $g_id) = &next_id($name);
    local($u_id_tmp, $e);

    while(1) {
	$u_id_tmp = &confirm_list("Uid", 1, $u_id, "");
	last if $u_id_tmp =~ /^[0-9]+$/ && $u_id_tmp <= $config{uid_end} &&
		! $config{uid} -> {$u_id_tmp};
	if ($config{uid} -> {$u_id_tmp}) {
	    warn "Uid ``$u_id_tmp'' in use!\a\n";
	} else {
	    warn "Wrong uid.\a\n";
	}
    }
    # use calculated uid
    return ($u_id_tmp, $g_id) if $u_id_tmp eq $u_id;
    # recalculate gid
    $config{uid_start} = $u_id_tmp;
    return &next_id($name);
}

# add user to group
sub add_group {
    local($gid, $name) = @_;

    return 0 if
	$config{groupmembers} -> {$gid} =~ /^(.*,)?$name(,.*)?$/;

    $groupmembers_bak{$gid} = $config{groupmembers} -> {$gid};
    $config{groupmembers} -> {$gid} .= "," if $config{groupmembers} -> {$gid};
    $config{groupmembers} -> {$gid} .= "$name";

    local(@l) = split(',', $config{groupmembers} -> {$gid});
    # The maximum line length of /etc/group is 1024 characters. 
    # Longer lines will be skiped. This is a restriction of some 
    # YP environments. We add 50 characters here for the groupname 
    # to be safe
    if (length $config{groupmembers} -> {$gid} > 1024 - 50) {
	warn "WARNING, group lines cannot exceed 1024 characters. Skipping\n".
	$config{groupmembers} -> {$gid}."\a\n";
    }
    return $name;
}


# return login group
sub new_users_grplogin {
    local($name, $defaultgroup, $new_users_ok) = @_;
    local($group_login, $group);

    $group = $name;
    $group = $defaultgroup if $defaultgroup ne $config{group_uniq};

    if ($new_users_ok) {
	# clean up backup
	foreach $e (keys %groupmembers_bak) { delete $groupmembers_bak{$e}; }
    } else {
	# restore old groupmembers, user was not accept
	foreach $e (keys %groupmembers_bak) {
	    $config{groupmembers} -> {$e} = $groupmembers_bak{$e};
	}
    }

    while(1) {
	$group_login = &confirm_list("Login group", 1, $group,
				     ($name, $group));
	last if $group_login eq $group;
	last if $group_login eq $name;
	last if defined $config{groupname} -> {$group_login};
	if ($group_login eq $config{group_uniq}) {
	    $group_login = $name; last;
	}

	if (defined $config{gid} -> {$group_login}) {
	    # convert numeric groupname (gid) to groupname
	    $group_login = $config{gid} -> {$group_login};
	    last;
	}
	warn "Group does not exist!\a\n";
    }

    return ($group_login, $config{group_uniq}) if $group_login eq $name;
    return ($group_login, $group_login);
}

# return login group
sub new_users_grplogin_batch {
    local($name, $defaultgroup) = @_;
    local($group_login, $group);

    $group_login = $name;
    $group_login = $defaultgroup if $defaultgroup ne $config{group_uniq};

    if (defined $config{gid} -> {$group_login}) {
	# convert numeric groupname (gid) to groupname
	$group_login = $config{gid} -> {$group_login};
    }

    return $group_login
	if defined($config{groupname} -> {$group_login}) || $group_login eq $name;
    warn "Group ``$group_login'' does not exist\a\n";
    return 0;
}

# return other groups (string)
sub new_users_groups {
    local($name, $other_groups) = @_;
    local($string) =
	"Login group is ``$group_login''. Invite $name into other groups:";
    local($e, $flag);
    local($new_groups,$groups);

    $other_groups = "no" unless $other_groups;

    while(1) {
	$groups = &confirm_list($string, 1, $other_groups,
				("no", $other_groups, "guest"));
	# no other groups
	return "" if $groups eq "no";

	($flag, $new_groups) = &new_users_groups_valid($groups);
	last unless $flag;
    }
    $new_groups =~ s/\s*$//;
    return $new_groups;
}

sub new_users_groups_valid {
    local($groups) = @_;
    local($e, $new_groups);
    local($flag) = 0;

    foreach $e (split(/[,\s]+/, $groups)) {
	# convert numbers to groupname
	if ($e =~ /^[0-9]+$/ && $config{gid} -> {$e}) {
	    $e = $config{gid} -> {$e};
	}
	if (defined($config{groupname} -> {$e})) {
	    if ($e eq $group_login) {
		# do not add user to a group if this group
		# is also the login group.
	    } elsif (add_group($config{groupname} -> {$e}, $name)) {
		$new_groups .= "$e ";
	    } else {
		warn "$name is already member of group ``$e''\n";
	    }
	} else {
	    warn "Group ``$e'' does not exist\a\n"; $flag++;
	}
    }
    return ($flag, $new_groups);
}

# your last change
sub new_users_ok {

    print <<"EOF";

Name:	  $name
Password: ****
Fullname: $fullname
Uid:	  $u_id
Gid:	  $g_id ($group_login)
Groups:	  $group_login $new_groups
HOME:	  $config{home}/$name
Shell:	  $sh
EOF

    return &confirm_yn("OK?", "y");
}

# make password database
sub new_users_pwdmkdb {
    local($last) = @_;
    local($user);

    $user = (split(/:/, $last))[0];
	# XXX: WHAT IN THE HELL IS GOING ON HERE??
    system(split(/\s+/, $config{pwd_mkdb_cmd}."  -u $user ".$config{etc_passwd}));
    if ($?) {
	warn "$last\n";
	warn "``".$config{pwd_mkdb}."'' failed\n";
	exit($? >> 8);
    }
}

# update group database
sub new_users_group_update {
    local($e, @a);

    # Add *new* group
    if (!defined($config{groupname} -> {$group_login}) && !defined($config{gid} -> {$g_id})) {
	push(@group_backup, "$group_login:*:$g_id:");
	$config{groupname} -> {$group_login} = $g_id;
	$config{gid} -> {$g_id} = $group_login;
	# $config{groupmembers} -> {$g_id} = $group_login;
    }

    if ($new_groups || defined($config{groupname} -> {$group_login}) ||
	defined($config{gid} -> {$config{groupname} -> {$group_login}}) &&
		$config{gid} -> {$config{groupname} -> {$group_login}} ne "+") {
	# new user is member of some groups
	# new login group is already in name space
	rename($group, "$group.bak");
	foreach $e (sort {$a <=> $b} (keys %gid)) {
	    push(@a, $config{gid} -> {$e}.":*:$e:".$config{groupmembers} -> {$e});
	}
	append_file($group, @a);
    } else {
	append_file($group, $group_login.":*:".$g_id.":");
    }

}

sub new_users_passwd_update {
    # update passwd/group variables
    push(@passwd_backup, $new_entry);
    $config{username} -> {$name} = $u_id;
    $config{uid} -> {$u_id} = $name;
    $config{pwgid} -> {$g_id} = $name;
}

# optionally send message to the new user
sub new_users_sendmessage {
    return 1 if $config{send_message} eq "no";

    my ($cc) =
	&confirm_list("Send message to ``$name'' and:",
		      1, "no", ("root", "second_mail_address", 
		      "no carbon copy"));
	$cc = $cc eq "no" ? "" : $cc;

	# $config{send_message} here is set by message_default() in batch()
    my @message_buffer = message_read ($config{send_message});

    foreach my $e (@message_buffer) {
		# XXX: this is hideously unsafe. fix with Safe.pm
		print eval "\"$e\"";
    }
    print "\n";

    if (!&confirm_yn("Add anything to default message?", "n")) {
		print "Use ``.'' or ^D alone on a line to finish your message.\n";
    	my @message_buffer_append;
		while(chomp (my $read = <STDIN>)) {
			last if $read eq '.';
			push @message_buffer_append, $read."\n";
		}
    }
	# add a blank line to the top
	unshift @message_buffer_append, "\n";

	if (&confirm_yn("Send messaage?", "y")) {
    	&sendmessage("$name $cc", (@message_buffer, @message_buffer_append))
	}
}

sub sendmessage {
    local($to, @message) = @_;
    local($e);

    if (!open(M, "| mail -s Welcome $to")) {
	warn "Cannot send mail to: $to!\n";
	return 0;
    } else {
	foreach $e (@message) {
	    print M eval "\"$e\"";
	}
	close M;
    }
}


sub new_users_password {

    # empty password
    return "" if $config{defaultpasswd} ne "yes";

    my $password;

    while(1) {
	system("stty", "-echo");
	$password = confirm_list("Enter password", 1, "", "");
	system("stty", "echo");
	print "\n";
	if ($password ne "") {
	    system("stty", "-echo");
	    $newpass = &confirm_list("Enter password again", 1, "", "");
	    system("stty", "echo");
	    print "\n";
	    last if $password eq $newpass;
	    print "They didn't match, please try again\n";
	}
	elsif (!&confirm_yn("Set the password so that user cannot logon?", "n")) {
	    last;
	}
    }

    return $password;
}


sub new_users {

    print "\n" if $config{verbose};
    print "Ok, let's go.\n" .
	  "Don't worry about mistakes. I will give you the chance later to " .
	  "correct any input.\n" if $config{verbose};

    # name: Username
    # fullname: Full name
    # sh: shell
    # u_id: user id
    # g_id: group id
    # group_login: groupname of g_id
    # new_groups: some other groups
    local($name, $group_login, $fullname, $sh, $u_id, $g_id, $new_groups);
    local($groupmembers_bak, $cryptpwd);
    local($new_users_ok) = 1;


    $new_groups = "no" unless $config{groupname} -> {$new_groups};

    while(1) {
	$name = &new_users_name;
	$fullname = &new_users_fullname($name);
	$sh = &new_users_shell;
	($u_id, $g_id) = &new_users_id($name);
	($group_login, $defaultgroup) =
	    &new_users_grplogin($name, $defaultgroup, $new_users_ok);
	# do not use uniq username and login group
	$g_id = $config{groupname} -> {$group_login} if (defined($config{groupname} -> {$group_login}));

	$new_groups = &new_users_groups($name, $new_groups);
	$config{password} = new_users_password();


	if (&new_users_ok) {
	    $new_users_ok = 1;

	    $cryptpwd = "*";	# Locked by default
	    $cryptpwd = encrypt($config{password}, salt()) if length $config{password};

	    # obscure perl bug
	    $new_entry = "$name\:" . "$cryptpwd" .
		"\:$u_id\:$g_id\::0:0:$fullname:".$config{home}."/$name:$sh";
	    &append_file($config{etc_passwd}, $new_entry);
	    &new_users_pwdmkdb("$new_entry");
	    &new_users_group_update;
	    &new_users_passwd_update;  print "Added user ``$name''\n";
	    &adduser_log("$name:*:$u_id:$g_id($group_login):$fullname");
	    &home_create($name, $group_login);
	    &new_users_sendmessage;
	} else {
	    $new_users_ok = 0;
	}
	if (!&confirm_yn("Add another user?", "y")) {
	    print "Goodbye!\n" if $config{verbose};
	    last;
	}
	print "\n" if !$config{verbose};
    }
}

sub batch {
	my ($name, $groups, $fullname, $password) = @_;
    my ($sh);

    $config{defaultshell} = shell_default_valid($config{defaultshell});
    return 0 unless $config{home} = &home_partition_valid($config{home});
    return 0 if $config{dotdir} ne &dotdir_default_valid($config{dotdir});
    $config{send_message} = &message_default;

    return 0 if $name ne new_users_name_valid($name);
    $sh = $shell{$config{defaultshell}};
    ($u_id, $g_id) = &next_id($name);
    $group_login = &new_users_grplogin_batch($name, $defaultgroup);
    return 0 unless $group_login;
    $g_id = $config{groupname} -> {$group_login} if (defined($config{groupname} -> {$group_login}));
    ($flag, $new_groups) = &new_users_groups_valid($groups);
    return 0 if $flag;

    $cryptpwd = "*";	# Locked by default
    if ($password ne "" && $password ne "*") {
	if($unencrypted)	{ $cryptpwd = encrypt($password, &salt) }
	else			{ $cryptpwd = $password }
    }
    # obscure perl bug
    $new_entry = "$name\:" . "$cryptpwd" .
	"\:$u_id\:$g_id\::0:0:$fullname:".$config{home}."/$name:$sh";
    append_file($config{etc_passwd}, $new_entry);
    new_users_pwdmkdb($new_entry);
    new_users_group_update;
    new_users_passwd_update;  print "Added user ``$name''\n";
    sendmessage($name, @message_buffer) if $config{send_message} ne "no";
    adduser_log("$name:*:$u_id:$g_id($group_login):$fullname");
    home_create($name, $group_login);
}

# ask for password usage (if we're verbose)
sub password_default {
	my $p;
    if ($config{verbose}) {
		$p = &confirm_yn("Prompt for passwords by default", 
			$config{defaultpasswd} eq "yes" ? "y" : "n" 
		);
		# confirm_yn() is going to return TRUE if the user agrees. 
		# if this is false, the user has made changes.
		$changes++ unless $p;
    }
	# we need to return the opposite of defaultpasswd here if the user
	# disagreed.
    return "yes" if (($config{defaultpasswd} eq "yes" && $p) ||
		     ($config{defaultpasswd} eq "no" && !$p));
    return "no";    # otherwise
}

# get default encryption method
sub encryption_default {
    local($m) = "";
    if ($config{verbose}) {
	while (encryption_check($m) == 0) {
            $m = confirm_list(
				"Default encryption method for passwords:", 1,
				@{ $config{encryption_methods} }[0],
				@{ $config{encryption_methods} },
			);
	}
    }
    return($m);
}

# Confirm that we have a valid encryption method
sub encryption_check {
    local($m) = $_[0];

    foreach $i (@{ $config{encryption_methods} }) {
        if ($m eq $i) { return 1; }
    }
    
    if ($m =~ /^blowfish,(\d+)$/) { return 1; }
    return 0;
}

# misc
sub check_root {
}

sub usage {
    warn <<USAGE;
usage: adduser
    [-batch username [group[,group]...] [fullname] [password]]
    [-check_only]
    [-config_create]
    [-dotdir dotdir]
    [-e|-encryption method]
    [-group login_group]
    [-h|-help]
    [-home home]
    [-message message_file]
    [-noconfig]
    [-shell shell]
    [-s|-silent|-q|-quiet]
    [-uid_start uid_start]
    [-uid_end uid_end]
    [-unencrypted]
    [-v|-verbose]

home=$config{home} shell=$config{defaultshell} dotdir=$config{dotdir} login_group=$defaultgroup
message_file=$config{send_message} uid_start=$config{uid_start} uid_end=$uid_end
USAGE
    exit 1;
}

# Generate an appropriate argument to encrypt()
# That may be a DES salt or a blowfish rotation count
sub salt {
    local($salt);		# initialization
    if ($config{encryptionmethod} eq "des" or 
		$config{encryptionmethod} eq "old") {
        local($i, $rand);
        local(@itoa64) = ( '0' .. '9', 'a' .. 'z', 'A' .. 'Z' ); # 0 .. 63

        warn "calculate salt\n" if $config{verbose} > 1;

        for ($i = 0; $i < 8; $i++) {
	    srand(time + $rand + $$); 
	    $rand = rand(25*29*17 + $rand);
	    $salt .=  $itoa64[$rand & $#itoa64];
        }
    } elsif ($config{encryptionmethod} eq "md5") {
        $salt = "";
    } elsif ($config{encryptionmethod} =~ /^blowfish/ ) {
        ($config{encryptionmethod}, $salt) = split(/,/, $config{encryptionmethod});
	if ($salt eq "") { $salt = 7; }	# default rounds inf unspecified
    } else {
		if ($config{verbose}) {
        	warn $config{encryptionmethod}." encryption method invalid\n";
			warn "Falling back to blowfish,7...\n";
		}
	$config{encryptionmethod} = "blowfish";
	$salt = 7;
    }
        
    warn "Salt is: $salt\n" if $config{verbose} > 1;

    return $salt;
}

# Encrypt a password using the selected method
sub encrypt {
    local($pass, $salt) = ($_[0], $_[1]);
    local($args, $crypt);

    if ($config{encryptionmethod} eq "des" or
		$config{encryptionmethod} eq "old") {
        $args = "-s $salt";
    } elsif ($config{encryptionmethod} eq "md5") {
        $args = "-m";
    } elsif ($config{encryptionmethod} eq "blowfish") {
        $args = "-b $salt";
    }

    open2(\*ENCRD, \*ENCWR, "/usr/bin/encrypt $args");
    print ENCWR $pass."\n";
    close ENCWR;
    $crypt = <ENCRD>;
    close ENCRD;
    chomp $crypt;
    die "encrypt failed" if (wait == -1 || $? != 0);
    return($crypt);
}

# hints
sub hints {
    if ($config{verbose}) {
	print "Use option ``-silent'' if you don't want to see " .
	      "all warnings and questions.\n\n";
    }
}

#
# XXX: fucking fix this already
sub parse_arguments {
    local(@argv) = @_;

    while ($_ = $argv[0], /^-/) {
	shift @argv;
	last if /^--$/;
	if    (/^--?(v|verbose)$/)	{ $config{verbose} = 1 }
	elsif (/^--?(s|silent|q|quiet)$/)  { $config{verbose} = 0 }
	elsif (/^--?(debug)$/)	    { $config{verbose} = 2 }
	elsif (/^--?(h|help|\?)$/)	{ &usage }
	elsif (/^--?(home)$/)	 { $config{home} = $argv[0]; shift @argv }
	elsif (/^--?(shell)$/)	 { $config{defaultshell} = $argv[0]; shift @argv }
	elsif (/^--?(dotdir)$/)	 { $config{dotdir} = $argv[0]; shift @argv }
	elsif (/^--?(uid_start)$/)	 { $config{uid_start} = $argv[0]; shift @argv }
	elsif (/^--?(uid_end)$/)	 { $uid_end = $argv[0]; shift @argv }
	elsif (/^--?(group)$/)	 { $defaultgroup = $argv[0]; shift @argv }
	elsif (/^--?(check_only)$/) { $check_only = 1 }
	elsif (/^--?(message)$/) { $config{send_message} = $argv[0]; shift @argv;
				   $sendmessage = 1; }
	elsif (/^--?(unencrypted)$/)	{ $unencrypted = 1 }
	elsif (/^--?(batch)$/)	 {
	    @batch = splice(@argv, 0, 4); $config{verbose} = 0;
	    die "batch: too few arguments\n" if $#batch < 0;
	}
	# see &config_read
	elsif (/^--?(config_create)$/)	{ &hints; &create_conf; exit(0); }
	elsif (/^--?(noconfig)$/)	{ $config{config_read} = 0; }
	elsif (/^--?(e|encryption)$/) {
	    $config{encryptionmethod} = $argv[0];
	    shift @argv;
	}
	else			    { &usage }
    }
    #&usage if $#argv < 0;
}

sub basename {
    local($name) = @_;
    $name =~ s|/+$||;
    $name =~ s|.*/+||;
    return $name;
}

sub dirname {
    local($name) = @_;
    $name = &stripdir($name);
    $name =~ s|/+[^/]+$||;
    $name = "/" unless $name;	# dirname of / is /
    return $name;
}

# return 1 if $file is a readable file or link
sub filetest {
    local($file, $config{verbose}) = @_;

    if (-e $file) {
	if (-f $file || -l $file) {
	    return 1 if -r _;
	    warn "$file unreadable\n" if $config{verbose};
	} else {
	    warn "$file is not a plain file or link\n" if $config{verbose};
	}
    }
    return 0;
}

# create or recreate configuration file prompting for values
sub create_conf {
    $create_conf = 1;

    &shells_read;			# Pull in /etc/shells info
    &shells_add;			# maybe add some new shells
    $config{defaultshell} = shell_default();	# enter default shell
    $config{home} = home_partition($config{home});	# find HOME partition
    $config{dotdir} = dotdir_default();		# check $config{dotdir}
    $config{send_message} = message_default();   # send message to new user
    $config{defaultpasswd} = password_default(); # maybe use password
    $defaultencryption = encryption_default();	# Encryption method

    if ($config{send_message} ne 'no') {
	&message_create($config{send_message});
    } else {
	&message_create($config{send_message_bak});
    }
    &config_write(1);
}

# log for new user in /var/log/adduser
sub adduser_log {
    my ($string) = @_;
    my $e;

    return 1 if $config{logfile} eq "no";

    local($sec, $min, $hour, $mday, $mon, $year) = localtime;
    $year += 1900;
    $mon++;

    foreach $e ('sec', 'min', 'hour', 'mday', 'mon') {
	# '7' -> '07'
	eval "\$$e = 0 . \$$e" if (eval "\$$e" < 10);
    }

    &append_file($config{logfile}, "$year/$mon/$mday $hour:$min:$sec $string");
}

# create home directory, copy dotfiles from $config{dotdir} to $config{home}
sub home_create {
    my ($name, $group) = @_;
    my $homedir = $config{home}."/".$name;

    if (-e "$homedir") {
	warn "Home directory ``$homedir'' already exists\a\n";
	return 0;
    }

    if ($config{dotdir} eq 'no') {
		if (not mkdir $homedir, 0755 ) {
			warn "mkdir $homedir: $!\n"; return 0;
		}
		# XXX: need to get this uid from the $name and $group above.
		chown $uid, $gid, $homedir;

		# XXX: clarify
		return !$?;
    }

    # copy files from  $config{dotdir} to $homedir
    # rename 'dot.foo' files to '.foo'
    print "Copy files from ".$config{dotdir}." to $homedir\n" if $config{verbose};

	# XXX: this is FUCKED.
    system("cp", "-R", $config{dotdir}, $homedir);
    system("chmod", "-R", "u+wrX,go-w", $homedir);
    system("chown", "-R", "$name:$group", $homedir);

    # security
    opendir(D, $homedir);
    foreach $file (readdir(D)) {
	if ($file =~ /^dot\./ && -f "$homedir/$file") {
	    $file =~ s/^dot\././;
	    rename("$homedir/dot$file", "$homedir/$file");
	}
	chmod(0600, "$homedir/$file")
	    if ($file =~ /^\.(rhosts|Xauthority|kermrc|netrc)$/);
	chmod(0700, "$homedir/$file")
	    if ($file =~ /^(Mail|prv|\.(iscreen|term))$/);
    }
    closedir D;
    return 1;
}

# makes a directory hierarchy
sub mkdir_home {
    local($dir) = @_;
    $dir = &stripdir($dir);
    local($user_partition) = "/usr";
    local($dirname) = &dirname($dir);


    -e $dirname || &mkdirhier($dirname);

    if (((stat($dirname))[0]) == ((stat("/"))[0])){
	# home partition is on root partition
	# create home partition on $user_partition and make
	# a symlink from $dir to $user_partition/`basename $dir`
	# For instance: /home -> /usr/home

	local($basename) = &basename($dir);
	local($d) = "$user_partition/$basename";


	if (-d $d) {
	    warn "Oops, $d already exists\n" if $config{verbose};
	} else {
	    print "Create $d\n" if $config{verbose};
	    if (!mkdir("$d", 0755)) {
		warn "$d: $!\a\n"; return 0;
	    }
	}

	unlink($dir);		# symlink to nonexist file
	print "Create symlink: $dir -> $d\n" if $config{verbose};
	if (!symlink("$d", $dir)) {
	    warn "Symlink $d: $!\a\n"; return 0;
	}
    } else {
	print "Create $dir\n" if $config{verbose};
	if (!mkdir("$dir", 0755)) {
	    warn "Directory ``$dir'': $!\a\n"; return 0;
	}
    }
    return 1;
}

sub mkdirhier {
    local($dir) = @_;
    local($d,$p);

    $dir = &stripdir($dir);

    foreach $d (split('/', $dir)) {
	$dir = "$p/$d";
	$dir =~ s|^//|/|;
	if (! -e "$dir") {
	    print "Create $dir\n" if $config{verbose};
	    if (!mkdir("$dir", 0755)) {
		warn "$dir: $!\n"; return 0;
	    }
	}
	$p .= "/$d";
    }
    return 1;
}

# stript unused '/'
# F.i.: //usr///home// -> /usr/home
sub stripdir {
    local($dir) = @_;

    $dir =~ s|/+|/|g;		# delete double '/'
    $dir =~ s|/$||;		# delete '/' at end
    return $dir if $dir ne "";
    return '/';
}

# Read one of the elements from @list. $confirm is default.
# If !$allow accept only elements from @list.
sub confirm_list {
    my ($message, $allow, $confirm, @list) = @_;

	# this is the variable we'll use to display to the user
    my $print = $message ? $message : "";

	# add a space unless $message ends in a newline or @list is empty.
	if (($message =~ /\n$/s) or ($list == ())) {
		$print .= " ";
	}
    
    # grab the unique values of @list
	# XXX: this really seems unnecessary.
	my %u = map { $_ => 1 } @list; 
    $print .= join ' ', keys %u;
		
	# display the list for the user
    print $print." ";

	# add a newline if the list winds up being longish
	if ((length $print + length $confirm) > 60) {
		print "\n";
	}
    print "[$confirm]: ";

    while (chomp (my $read = <STDIN>)) {
		# zap leading and trailing space.
		my ($answer) = $read =~ /^\s*?([\S\s]+)\s*?/;

		# they just hit enter. return.
		return $confirm unless length $read;

		# this was free-form, so return their -original- answer.
    	return $read if $allow;

		# they picked a selection from the list, return it
		return $answer if grep { $answer } @list;

		# they goofed. let them know
    	warn "\"$answer\" is not an acceptable parameter.!\a\n";

		# prompt again.
		print "[$confirm]: ";
	}
}

# prompt the user for "yes" or "no" returns true if users answer
# matches requested default, false if not.
sub confirm_yn {
    my ($message, $confirm) = @_;
    my ($yes) = qr{\s*?(?:yes|y|1)\s*?}i;
    my ($no)  = qr{\s*?(?:no|n|0)\s*?}i;
	my $default;

    if ($confirm =~ $yes) {
		$default = "Yn";
    } 
	elsif ($confirm =~ $no) {
		$default = "yN";
    }
    print "$message [$default]: ";
    while (chomp (my $read = <STDIN>)) {
		my ($answer) = $read =~ /($yes|$no)/i;
        if (not length $read or not length $answer) {
	        # user just hit enter.
		    return 1;
	    }

		# return true if we met our default condition
		return $answer if ($confirm =~ $yes and $answer =~ $yes);
		return $answer if ($confirm =~ $no and $answer =~ $no);

		# user gave us a valid answer that disagreed with our default
		if ($answer =~ $yes or $answer =~ $no) {
			return 0;
		}

        warn "Please enter 'yes' or 'no'.\a\n";
		print "[$default]: ";
		next; 
	}
    return 0; # we should never get here.
}

# test if $config{dotdir} exist
# return "no" if $config{dotdir} not exist or dotfiles should not copied
sub dotdir_default {
    local($dir) = $config{dotdir};

    return &dotdir_default_valid($dir) unless $config{verbose};
    while($config{verbose}) {
	# XXX: this is unclear
	$dir = &confirm_list("Copy dotfiles from:", 1,
	    $dir, ("no", $config{dotdir_bak}, $dir));
	last if $dir eq &dotdir_default_valid($dir);
    }
    warn "Do not copy dotfiles.\n" if $config{verbose} && $dir eq "no";

    $changes++ if $dir ne $config{dotdir};
    return $dir;
}

sub dotdir_default_valid {
    local($dir) = @_;

    return $dir if (-e $dir && -r _ && (-d _ || -l $dir) && $dir =~ "^/");
    return $dir if $dir eq "no";
    warn "Dotdir ``$dir'' is not a directory\a\n";
    return "no";
}

# ask for messages to new users
sub message_default {
    local($file) = $config{send_message};
    local(@d) = ($file, $config{send_message_bak}, "no");

    while($config{verbose}) {
	$file = &confirm_list("Send message from file:", 1, $file, @d);
	last if $file eq "no";
	last if &filetest($file, 1);

	# maybe create message file
	&message_create($file) if &confirm_yn("Create ``$file''?", "y");
	last if &filetest($file, 0);
	last if !&confirm_yn("File ``$file'' does not exist, try again?",
			     "y");
    }

    if ($file eq "no" || !&filetest($file, 0)) {
	warn "Do not send message\n" if $config{verbose};
	$file = "no";
    } else {
	&message_read($file);
    }

    $changes++ if $file ne $config{send_message} && $config{verbose};
    return $file;
}

# create message file
sub message_create {
    local($file) = @_;

    rename($file, "$file.bak");
    if (!open(M, "> $file")) {
	warn "Messagefile ``$file'': $!\n"; return 0;
    }
    print M <<"EOF";
#
# Message file for adduser(8)
#   comment: ``#''
#   default variables: \$name, \$fullname, \$password
#   other variables:  see /etc/adduser.conf after
#		     line  ``$do_not_delete''
#

\$fullname,

your account ``\$name'' was created.
Have fun!

See also chpass(1), finger(1), passwd(1)
EOF
    close M;
    return 1;
}

# read message file into buffer
sub message_read {
    my $file = shift;
	open READ, "<$file" or warn "``$file'': $!\n\a" and return ();
	my @message_buffer = grep { /^\s*/ ? () : $_ } <READ>;
    close READ;
	return @message_buffer;
}

# write @list to $file with file-locking
sub append_file {
    local($file,@list) = @_;
    local($e);

    open(F, ">> $file") || die "$file: $!\n";
    print "Lock $file.\n" if $config{verbose} > 1;
    while(!flock(F, LOCK_EX | LOCK_NB)) {
	warn "Cannot lock file: $file\a\n";
	die "Sorry, gave up\n"
	    unless &confirm_yn("Try again?", "y");
    }
    print F join("\n", @list) . "\n";
    print "Unlock $file.\n" if $config{verbose} > 1;
    flock(F, LOCK_UN);
    close F;
}

# return free uid+gid
# uid == gid if possible
sub next_id {
    local($group) = @_;

    $config{uid_start} = 1000 if ($config{uid_start} <= 0 || $config{uid_start} >= $uid_end);
    # looking for next free uid
    while($uid{ $config{uid_start} }) {
	$config{uid_start}++;
	$config{uid_start} = 1000 if $config{uid_start} >= $config{uid_end};
	print $config{uid_start}."\n" if $config{verbose} > 1;
    }

    local($gid_start) = $config{uid_start};
    # group for user (username==groupname) already exist
    if ($config{groupname} -> {$group}) {
	$gid_start = $config{groupname} -> {$group};
    }
    # gid is in use, looking for another gid.
    # Note: uid and gid are not equal
    elsif ($config{gid} -> { $config{uid_start} }) {
	while($config{gid} -> {$gid_start} or $config{uid} -> {$gid_start}) {
	    $gid_start--;
	    $gid_start = $uid_end if $gid_start < 100;
	}
    }
    return ($config{uid_start}, $gid_start);
}

# read config file - typically /etc/adduser.conf
sub read_config {
    local($opt) = join " ", @_;
    local($user_flag) = 0;

    # don't read config file
    return 1 if $opt =~ /-(noconfig|config_create)/ || !$config{config_read};

    if (!-f $config) {
        warn("Couldn't find $config: creating a new adduser configuration file\n");
        &create_conf;
		# since we set this to defaults we've got in this file, return.
		return;
    }



	# we parse over the file looking for variables to interpolate. we
	# do this within our Safe compartment so that we dont get users
	# inserting $foo = `rm -rf /` into the file. perish the thought.
	use Safe;
	my $compartment = new Safe;
	my ($this_line, @this_file);
	$compartment -> permit(qw{ :default });
	# $compartment -> share(qw{ $this_line });

	open CONFIG, "<$config" or warn $! and return 0;
	my @thisfile = <CONFIG>;
	close CONFIG;
    foreach $this_line (@thisfile) {

		# user defined variables
		$user_flag++ if $this_line =~ /^$do_not_delete/; 
		
		# if the first regex matches, we shouldnt see $$foo outputted. both
		# millert and I am worried about this. -aja
		if ($this_line =~ /^(\w+\s*=\s*\()/) {
			# we have found an array.
			$this_line =~ s/^/@/;
			my $saferes = $compartment -> reval( $this_line );
			if ($saferes ne $this_line and $saferes !~ /trapped/) {
				# it was safe.
				$this_line = $saferes;
			}
		}
		elsif ($this_line =~ /^(\w+\s*=\s*[^(]+)/) {
			# we have found a scalar
			$this_line =~ s/^/\$/;
			my $saferes = $compartment -> reval( $this_line );
			if ($saferes ne $this_line and $saferes !~ /trapped/) {
				# it was safe.
				$this_line = $saferes;
			}
		}
		# we skip ##'s as they are comments. more on this later.
		next if $this_line =~ /^##/;

		# here we check to see that we either started with a sigil [$@] 
		# or we started with a comment or whitespace. we preserve the single
		# '# blah' lines so that the file remains commented for the user.
		if ($user_flag and 
			(($this_line =~ s/^[$@]//) or ($this_line =~ /^(#\s|\s)/))) {
			push @user_variable_list, $this_line;
	    }
	} # @thisfile
}


# write config file
sub config_write {
    local($silent) = @_;

    # nothing to do
    return 1 unless ($changes || ! -e $config{configfile} || !$config_read || $silent);

    if (!$silent) {
	if (-e $config) {
	    return 1 if &confirm_yn("\nWrite your changes to $config?", "n");
	} else {
	    return 1 unless
		&confirm_yn("\nWrite your configuration to $config?", "y");
	}
    }

    rename($config, "$config.bak");
    open(C, "> $config") || die "$config: $!\n";

    # prepare some variables
    $config{send_message} = "no" unless $config{send_message};
    $config{defaultpasswd} = "no" unless $config{defaultpasswd};
    local($shpref) = "'" . join("', '", @{ $config{shellpref} }) . "'";
    local($shpath) = "'" . join("', '", @{ $config{path} }) . "'";
    local($user_var) = join('', @user_variable_list);

    print C <<"EOF";
#
# $rcsid
# $config{configfile} - automatic generated by adduser(8)
#
# Note: adduser reads *and* writes this file.
#	You may change values, but don't add new things before the
#	line ``$do_not_delete''
#

# verbose = (0 - 2)
verbose = $config{verbose}

# Get new password for new users
# defaultpasswd =  yes | no
defaultpasswd = $config{defaultpasswd}

# Default encryption method for user passwords 
# Methods are all those listed in passwd.conf(5)
encryptionmethod = "$defaultencryption"

# copy dotfiles from this dir ("/etc/skel" or "no")
dotdir = "$config{dotdir}"

# send this file to new user ("/etc/adduser.message" or "no")
send_message = "$config{send_message}"

# config file for adduser ("/etc/adduser.conf")
config = "$config"

# logfile ("/var/log/adduser" or "no")
logfile = "$config{logfile}"

# default HOME directory ("/home")
home = "$config{home}"

# List of directories where shells located
# path = ('/bin', '/usr/bin', '/usr/local/bin')
path = ($shpath)

# common shell list, first element has higher priority
# shellpref = ( 'csh', 'sh', 'tcsh', 'ksh', 'bash' )
shellpref = ($shpref)

# defaultshell if not empty ("csh")
defaultshell = "$config{defaultshell}"

# defaultgroup ('USER' for same as username or any other valid group)
defaultgroup = $defaultgroup

# new users get this uid
uid_start = $config{uid_start}
uid_end = $uid_end

$do_not_delete
## your own variables, see /etc/adduser.message
EOF
    print C "$user_var\n" if ($user_var ne '');
    print C "\n## end\n";
    close C;
}

# check for sane variables
sub variable_check {
	# Check uid_start & uid_end
	warn "WARNING: uid_start < 1000!\n" if($config{uid_start} < 1000);
	die "ERROR: uid_start >= uid_end!\n" if($config{uid_start} >= $config{uid_end});
	# unencrypted really only usable in batch mode
	warn "WARNING: unencrypted only effective in batch mode\n"
	    if($#batch < 0 && $unencrypted);
}

sub cleanup {
    local($sig) = @_;

    print STDERR "Caught signal SIG$sig -- cleaning up.\n";
    system("stty", "echo");
    exit(0);
}

END {
	if (-e $config{etc_ptmp} && defined(fileno(PTMP))) {
		close PTMP;
		unlink $config{etc_ptmp}
			or warn << "WARNING";
Error: unable to remove $config{etc_ptmp}: $!
Please verify that $config{etc_ptmp} no longer exists.
WARNING
	}
}
