Elvis is a modular Napster bot written in perl.  It is based loosely
on Petunia, another such bot.  To build a module for Elvis, just
create a file in the "modules" directory, or an entry in the table
"modules" (if you prefer).

This file may contain the following special subroutine definitions:

sub public   - will be called for public messages with the args:
     ($channel, $nick, $msg)
sub emote    - will be called for emote messages with the args:
     ($channel, $nick, $msg)
sub private  - will be called for private messages with the args:
     ($nick, $msg)
sub unload   - will be called just before the module is unloaded.

There is no need for a 'load' sub, because any code outside a sub
definition is run when the module is eval'd.  Each module is compiled
into a separate namespace when it is loaded, so there's no conflict
with other modules.

The following global symbols are defined:

    $dbh,	     The DBI handle
    $nap,	     The MP3::Napster object
    $daemon,	     A flag if we are running as a daemon
    $debug,	     A flag if we want debugging output
    %modules,	     A hash of module names to namespaces
    $mynick,	     The nick we are using
    $epoch_start,    The time the script was started
    %config          A tied hash that reads from the 'config' table

