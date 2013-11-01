use strict;

our %swears = ( fuck=>['fark', 'fudge', 'frag', 'floop', 'flock'],
		fucking=>['fudging', 'freaking', 'flipping', 'fricking'],
		fuckin=>['fudgin', 'freakin'],
		ass=>['ash','@$$','butt'],
		asshole=>['fishpole','ashhill','pooper'],
		shit=>['shift','schist','poop','doodie'],
		damn=>['dang','drat','curséd','(term of mild anger)'],
		bitch=>['biznatch','blank','witch', 'dogmommie'],
		);

our @swears = sort {length $b <=> length $a} keys %swears;

print join " ", @swears;

while (my $line = <>) {

    print &replace_swears($line);

}



sub replace_swears {
    my ($line) = @_;

     for my $harsh (@swears) {
	 my $milds = $swears{$harsh};
	 my $mild = $$milds[rand $#$milds];
#	 print "$harsh $mild\n";
	 $line =~ s/$harsh/$mild/g;
     }
    return $line;
}
