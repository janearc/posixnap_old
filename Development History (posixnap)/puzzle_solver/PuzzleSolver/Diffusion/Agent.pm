package PuzzleSolver::Diffusion::Agent;

use constant DEFAULT_RATE => 0.001;

use strict;
use warnings;
use PuzzleSolver::Diffusion::World qw/:checks/;
use Clone qw/clone/;

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

=head1 NAME

PuzzleSolver::Diffusion::Agent - Diffusion Agent

=head1 SYNOPSIS

 use strict;
 use PuzzleSolver::Diffusion::Agent;

 my $agent = PuzzleSolver::Diffusion::Agent -> new();

=head1 ABSTRACT

=head1 METHODS

The following methods are provided:

=over 4

=item $agent = PuzzleSolver::Diffusion::Agent -E<gt> new( %args );

This method creates and returns a Diffusion Agent.  Arguments are optional and in hash form as follows:

  KEY               DEFAULT
  --------          --------
  world             undef
  diffusion_rate    0.001

C<world> is the world this agent will act on.

C<diffusion_rate> is the rate at which coins will diffuse to other cities.  The default is that 1 coin for each 1000 coins will diffuse to the surrounding cities, a loss of 4 coins total (or the number of connecting cities).  This calue must be below 0.25 or the agent will act irrationally.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my $world = $args{world};
    if ( $world )
        { _test_world( $world ) }

    my $rate = $args{diffusion_rate} || DEFAULT_RATE();

    die "Agent: new(): diffusion rate must be below 0.25\n"
        unless $rate < 0.25;

    return bless {
        objects => {
            world => $world,
            rate => $rate,
        },
    }, $this;
}

=item $world = $agent -E<gt> world( $world );

This method sets the current world this Agent functions on.  This method also returns the current world.  If no world is set, this returns C<undef>.  If no World parameter is given, this method makes no changes to the currently stored world.

=cut

sub world {
    my $self = shift;
    if ( @_ ) {
        my $w = shift;
        _test_world( $w );
        $self -> {objects} -> {world} = $w;
    }
    return $self -> {objects} -> {world};
}

=item $agent -E<gt> diffuse();

This method carries out one step of diffusion based on the given world and parameters.  The retulting world returned by C<world()> will not be equal to the previous world.

=cut

sub diffuse {
    my $self = shift;
    die "Agent: diffuse(): A World object must be specified before running diffuse()\n"
        unless $self -> {objects} -> {world};

    my $world = $self -> {objects} -> {world};
    my $nw = clone($world);
    $nw -> {objects} -> {serial} = rand 10000;
    my $world_space = $world -> space();
    my $nw_space = $nw -> space();
    foreach my $x ( keys %{ $world_space } ) {
        foreach my $y ( keys %{ $world_space -> {$x} } ) {

            foreach my $m ( @{ $world -> motifs() } ) {
                my $city = $world_space -> {$x} -> {$y};
                my $ncity = $nw_space -> {$x} -> {$y};

                # find number of coins to move, will only be 0 if 0 coins exist
                my $coins_to_move = $city -> coins() -> {$m}
                    ? int( $city -> coins() -> {$m} * $self -> {objects} -> {rate} or 1 )
                    : 0;

                foreach my $c ( @{ $nw_space -> {$x} -> {$y} -> connections() } ) {
                    my $coins = $ncity -> coins();
                    $coins -> {$m} -= $coins_to_move;
                    $ncity -> coins( $coins );

                    $coins = $c -> coins();
                    $coins -> {$m} += $coins_to_move;
                    $c -> coins( $coins );
                }
            }
        }
    }
    $self -> {objects} -> {world} = $nw;
    1;
}

=back

=head1 EXPORTS

The following methods are optionally exported:

=over 4

=item $retval _test_percent( $p );

This method performs a sanity check on the value C<$p>.  It returns true if C<$p> is some number between 0 and 1, including 1.  On false, this method C<die()>s.

=cut

sub _test_percent {
    my $p = shift;
    my ($x, $y, $z, $sub) = caller(1);
    my $e = "Die: $sub(): expects World object\n";
    die $e unless $p > 0 and $p <= 1;
    return $p;
}

=back

=cut

#this will parse the city grid
#    copy grid
#    parse oritingal and make changes on copy
#    set copy

1;
