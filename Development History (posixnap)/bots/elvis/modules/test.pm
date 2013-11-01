sub public {
    my ($channel, $nick, $packet) = @_;
    print STDERR "test module public: channel $channel nick $nick, packet $packet\n";
}

sub private {
    my ($nick, $packet) = @_;
    print STDERR "test module private: nick $nick, packet $packet\n";
}

sub emote {
    my ($channel, $nick, $packet) = @_;
    print STDERR "test module emote: channel $channel nick $nick, packet $packet\n";
}

print STDERR "Module test loaded, biznatch.\n";

1;
