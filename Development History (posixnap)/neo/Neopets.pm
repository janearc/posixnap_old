#!/usr/bin/perl -w

package Neopets;

use strict;
use warnings;

use Neopets::Agent;
use Neopets::Config;

=head1 NAME

Neopets - A NeoPets manipulation module suite

=head1 SYNOPSIS

=head1 ABSTRACT

=head1 METHODS

The following methods are provided:

=over 4

=item $neo = Neopets -> new();

This constructor takes hashref arguments
and returns a NeoPets object.  Optional
arguments are:
  debug => 1|0,
  cookie_file => location of cookiefile, relative to NP_HOME,
These arguments specify what objects to create:
  all            => 1|0,
    # create all objects
  neopia         => 1|0,
    # create all objects existing in neopia
  games          => 1|0,
    # load all game modules
  obj            => 1|0,
    # create one of each data object
  util           => 1|0,
    # create utility objects, such as ShopWizard
  central        => 1|0,
    # all objects in Neopia Central
  faerieland     => 1|0,
  lostdesert     => 1|0,
  meridell       => 1|0,
  mysteryisland  => 1|0,
  terrormountain => 1|0,
  tyrannia       => 1|0

=cut

sub new {
    my $that = shift;
    my $this = ref ( $that ) || $that;
    my ( $args ) = @_;

    my $debug = $args -> {debug};
    my $cf = $args -> {cookie_file};
    my $agent = Neopets::Agent -> new(
        { cookie_file => $cf,
          debug => $debug,
        } );

    # which objects to create
    my $all = $args -> {all};
    my $neopia = $args -> {neopia} || $all;
    my $games = $args -> {games} || $all;
    my $obj = $args -> {obj} || $all;
    my $util = $args -> {util} || $all;
    my $central = $args -> {central} || $neopia;
    my $faerie = $args -> {faerieland} || $neopia;
    my $desert = $args -> {lostdesert} || $neopia;
    my $meridell = $args -> {meridell} || $neopia;
    my $misland = $args -> {mysteryisland} || $neopia;
    my $terror = $args -> {terrormountain} || $neopia;
    my $tyrannia = $args -> {tyrannia} || $neopia;

    # standard args
    my $c = {
        agent => \$agent,
        debug => $debug,
    };

    my $objects = {
        agent => $agent,
        config => Neopets::Config -> new(),
    };

    if ( $games ) {
        require Neopets::Games::Cliffhanger;
        require Neopets::Games::NeoQuest;

        $objects = {
            %{ $objects },
            Cliffhanger => Neopets::Games::Cliffhanger -> new($c),
            NeoQuest => Neopets::Games::NeoQuest -> new($c),
        };
    }

    if ( $util ) {
        require Neopets::Inventory;
        require Neopets::NeoMail::NeoFriends;
        require Neopets::Common;
        require Neopets::Pet;
        require Neopets::Shops;
        require Neopets::Shops::Mine;
        require Neopets::Shops::Wizard;

        $objects = {
            %{ $objects },
            Common => Neopets::Common -> new($c),
            Inventory => Neopets::Inventory -> new($c),
            NeoFriends => Neopets::NeoMail::NeoFriends -> new($c),
            Pet => Neopets::Pet -> new($c),
            Shops => Neopets::Shops -> new($c),
            MyShop => Neopets::Shops::Mine -> new($c),
            Wizard => Neopets::Shops::Wizard -> new($c),
        };
    }

    if ( $obj ) {
        $objects = {
            %{ $objects },
            ItemObject => Neopets::Item::Simple -> new(),
            PetObj => Neopets::Pet::Simple -> new(),
        };
    }

    if ( $central ) {
        require Neopets::Neopia::Shops;
        require Neopets::Neopia::Central::Bank;
        require Neopets::Neopia::Central::MarketPlace::SoupKitchen;
        require Neopets::Neopia::Central::MoneyTree;

        $objects = {
            %{ $objects },
            NeopiaShops => Neopets::Neopia::Shops -> new($c),
            Bank => Neopets::Neopia::Central::Bank -> new($c),
            SoupKitchen => Neopets::Neopia::Central::MarketPlace::SoupKitchen -> new($c),
            MoneyTree => Neopets::Neopia::Central::MoneyTree -> new($c),
        };
    }

    if ( $faerie ) {
        require Neopets::Neopia::Shops;
        require Neopets::Neopia::Faerieland::HealingSprings;
        require Neopets::Neopia::Faerieland::WheelOfExcitement;

        $objects = {
            %{ $objects },
            NeopiaShops => Neopets::Neopia::Shops -> new($c),
            HealingSprings => Neopets::Neopia::Faerieland::HealingSprings -> new($c),
            WheelOfExcitement => Neopets::Neopia::Faerieland::WheelOfExcitement -> new($c),
        };
    }

    if ( $desert ) {
        require Neopets::Neopia::Shops;
        require Neopets::Neopia::LostDesert::ColtzansShrine;
        require Neopets::Neopia::LostDesert::FruitMachine;

        $objects = {
            %{ $objects },
            NeopiaShops => Neopets::Neopia::Shops -> new($c),
            ColtzansShrine => Neopets::Neopia::LostDesert::ColtzansShrine -> new($c),
            FruitMachine => Neopets::Neopia::LostDesert::FruitMachine -> new($c),
        };
    }

    if ( $meridell ) {
        require Neopets::Neopia::Shops;
        require Neopets::Neopia::Meridell::IllusensGlade;
        require Neopets::Neopia::Meridell::Turmaculus;

        $objects = {
            %{ $objects },
            NeopiaShops => Neopets::Neopia::Shops -> new($c),
            IllusensGlade => Neopets::Neopia::Meridell::IllusensGlade -> new($c),
            Turmaculus => Neopets::Neopia::Meridell::Turmaculus -> new($c),
        };
    }

    if ( $misland ) {
        require Neopets::Neopia::Shops;
        require Neopets::Neopia::MysteryIsland::IslandMystic;
        require Neopets::Neopia::MysteryIsland::Tombola;
        require Neopets::Neopia::MysteryIsland::TrainingSchool;

        $objects = {
            %{ $objects },
            NeopiaShops => Neopets::Neopia::Shops -> new($c),
            IslandMystic => Neopets::Neopia::MysteryIsland::IslandMystic -> new($c),
            Tombola => Neopets::Neopia::MysteryIsland::Tombola -> new($c),
            TrainingSchool => Neopets::Neopia::MysteryIsland::TrainingSchool -> new($c),
        };
    }
    
    if ( $terror ) {
        require Neopets::Neopia::Shops;
        require Neopets::Neopia::TerrorMountain::IceCaves::Kiosk;
        require Neopets::Neopia::TerrorMountain::IceCaves::Snowager;

        $objects = {
            %{ $objects },
            NeopiaShops => Neopets::Neopia::Shops -> new($c),
            Kiosk => Neopets::Neopia::TerrorMountain::IceCaves::Kiosk -> new($c),
            Snowager => Neopets::Neopia::TerrorMountain::IceCaves::Snowager -> new($c),
        };
    }

    if ( $tyrannia ) {
        require Neopets::Neopia::Shops;
        require Neopets::Neopia::Tyrannia::Plateau::Omelette;
        require Neopets::Neopia::Tyrannia::WheelOfMediocrity;

        $objects = {
            %{ $objects },
            NeopiaShops => Neopets::Neopia::Shops -> new($c),
            Omelette => Neopets::Neopia::Tyrannia::Plateau::Omelette -> new($c),
            WheelOfMediocrity => Neopets::Neopia::Tyrannia::WheelOfMediocrity -> new($c),
        };
    }

    return bless $objects, $this;
}

# depricated
#use Neopets::Shops::Mine::Item;
#use Neopets::Neopia::Central::MagicShop;

# these ones needs work
#use Neopets::Neopia::MysteryIsland::Tombola;
#use Neopets::Neopia::MysteryIsland::TrainingSchool;

1;
