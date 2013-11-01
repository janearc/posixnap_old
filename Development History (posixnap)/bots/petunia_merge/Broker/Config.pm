package Broker::Config;
 
use strict;
use warnings;

sub TIEHASH {
    my $self = shift;
    my $dbh  = shift;
    my $node = { 
	dbh => $dbh, 
	fetch_sth => $dbh->prepare("SELECT value FROM config WHERE key = ?"),
	update_sth => $dbh->prepare("UPDATE config SET value = ? WHERE key = ?"),
	insert_sth => $dbh->prepare("INSERT INTO config VALUES (?, ?)"),
	delete_sth => $dbh->prepare("DELETE FROM config WHERE key = ?"),
	keys_sth => $dbh->prepare("SELECT key FROM config"),
    };
    return bless $node, $self;
}

sub FETCH {
    my $self = shift;
    my $key  = shift;
    my $sth  = $self->{fetch_sth};
    $sth->execute($key);
    my ($res) = $sth->fetchrow_array;
    $sth->finish;
    return $res;
}

sub STORE {
    my $self = shift;
    my $key  = shift;
    my $value  = shift;
    my $sth  = $self->{fetch_sth};
    $sth->execute($key);
    my ($res) = $sth->fetchrow_array;
    if (defined $res) {
	$res = $self->{update_sth}->execute($value, $key);
    } else {
	$res = $self->{insert_sth}->execute($key, $value);
    }
    $sth->finish;
    return $res;
}

sub DELETE {
    my $self = shift;
    my $key  = shift;
    my $sth  = $self->{delete_sth};
    $sth->execute($key);
}
    
sub EXISTS {
    my $self = shift;
    my $key  = shift;
    my $sth  = $self->{fetch_sth};
    $sth->execute($key);
    my ($res) = $sth->fetchrow_array;
    $sth->finish;
    return $res;
}

sub FIRSTKEY {
    my $self = shift;
    $self->{keys_sth}->execute;
    my ($res) = $self->{keys_sth}->fetchrow_array;
    return $res;
}

sub NEXTKEY  {
    my $self = shift;
    my ($res) = $self->{keys_sth}->fetchrow_array;
    if (not defined $res) { $self->{keys_sth}->finish; }
    return $res;
}

sub DESTROY {
    my $self = shift;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Broker::Config - Perl extension for a hash tied to a database.

=head1 SYNOPSIS

use Broker::Config;

my %config;

tie %config, "Broker::Config", $dbh;

if ('true' eq $config{test_mode}) {...}

=head1 DESCRIPTION

This is just a simple class for a tied hash connected to a database
with a table 'config', that maps strings to strings.

=head1 BUGS

=head1 AUTHOR

Daniel R. Risacher, magnus@alum.mit.edu

=head1 SEE ALSO

perl(1), DBI(3)

=cut
