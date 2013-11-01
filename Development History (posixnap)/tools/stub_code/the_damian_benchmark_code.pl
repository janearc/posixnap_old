
# perlmonks node 250434

use List::Util 'max';
sub align {
    my ($hash) = @_;
    my $len = max map length, keys %$hash;
    $hash->{sprintf "%${len}s", $_} = delete $hash->{$_} 
        for keys %$hash;
    return $hash;
}

cmpthese(10000, align {
    'Bacon, Lettuce, & Tomato' => sub {...},
    'Ham on Rye'               => sub {...},
    'Spam'                     => sub {...},
    # etc.
});

