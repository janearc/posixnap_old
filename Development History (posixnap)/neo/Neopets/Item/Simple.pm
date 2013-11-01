package Neopets::Item::Simple;

use strict;
use warnings;

=head1 NAME

Neopets::Item::Simple - Simple Neopet item storage

=head1 SYNOPSIS

  use Neopets::Item::Simple;

  my $item = Neopets::Item::Simple -> new();

  $buyer    = $item -> buyer();
  $date     = $item -> date();
  $desc     = $item -> description();
  $id       = $item -> id();
  $loc      = $item -> location();
  $name     = $item -> name();
  $negotiatable = $item -> negotiable();
  $order    = $item -> order();
  $owner    = $item -> owner();
  $price    = $item -> price();
  $quantity = $item -> quantity();
  $referer = $item -> referer();
  $type_id  = $item -> type_id();

  $item -> buyer( $buyer );
  $item -> date( $date );
  $item -> description( $desc );
  $item -> id( $id );
  $item -> location( $loc );
  $item -> name( $name );
  $item -> negotiable( $negotiable );
  $item -> order( $order );
  $item -> owner( $owner );
  $item -> price( $price );
  $item -> quantity( $quantuty );
  $item -> referer( $referer );
  $item -> type_id( $type_id );

=head1 ABSTRACT

This module is simply a storage space for Neopian
item related data.

=head1 METHODS

The following methods are provided:

=over 4

=cut

=item $item = new Neopets::Item->new;

This creates an item object.  Optionaly
it takes a hash representing the data to
be stored.

  new( {
         name => $name,
         price => $price,
     } );

=cut

sub new {
  my $that = shift;
  my $this = ref($that) || $that;
  my ( $args ) = @_;

  my $data = {
      buyer => $args -> {buyer},
      date => $args -> {date},
      name => $args -> {name},
      negotiatable => $args -> {negotiable},
      price => $args -> {price},
      description => $args -> {description},
      location => $args -> {location},
      owner => $args -> {owner},
      referer => $args -> {referer},
      quantity => $args -> {quantity},
      order => $args -> {order},
      type_id => $args -> {type_id},
      id => $args -> {id},
  };

  return bless $data, $this;
}

=item $item -> buyer( $buyer );
Sets or retrieves the item buyer.
$buyer is optional.

=cut

sub buyer {
  my $self = shift;
  @_ and $self -> {buyer} = shift;
  return $self -> {buyer};
}

=item $item -> date( $date );
Sets or retrieves the item date.
$date is optional.

=cut

sub date {
  my $self = shift;
  @_ and $self -> {date} = shift;
  return $self -> {date};
}

=item $item -> name( $name );

Sets or retrieves the item name.
$name is optional.

=cut

sub name {
  my $self = shift;
  @_ and $self -> {name} = shift;
  return $self -> {name};
}

=item $item -> negotiable( $negotiable );

Sets or retrieves the item's need
for negotiation.  Neopian shops request
a negotiation before buying, unlike
other shops.  Items existing within
these shops must have negotiable set
in order to be buyable.

=cut

sub negotiable {
  my $self = shift;
  @_ and $self -> {negotiable} = shift;
  return $self -> {negotiable};
}

=item $item -> price( $price );

Sets or retrieves the item price.
$price is optional.

=cut

sub price {
  my $self = shift;
  @_ and $self -> {price} = shift;
  return $self -> {price};
}

=item $item -> description( $desc );

Sets or retrieves the item description.
$desc is optional.

=cut

sub description {
  my $self = shift;
  @_ and $self -> {description} = shift;
  return $self -> {description};
}

=item $item -> id( $id );

Sets or retrieves the item id.
Every neopian item has a unique
id which no other item of any
type shares.  $id is optional.

=cut

sub id {
  my $self = shift;
  @_ and $self -> {id} = shift;
  return $self -> {id};
}

=item $item -> location( $loc );

Sets or retrieves the item location.
$loc is optional.

=cut

sub location {
  my $self = shift;
  @_ and $self -> {location} = shift;
  return $self -> {location};
}

=item $item -> owner( $loc );

Sets or retrieves the item location.
$loc is optional.

=cut

sub owner {
  my $self = shift;
  @_ and $self -> {owner} = shift;
  return $self -> {owner};
}

=item $item -> order( $order );

Sets or retrieves the item order id
(ie. 3rd in a list of items).  $order
is optional.

=cut

sub order {
  my $self = shift;
  @_ and $self -> {order} = shift;
  return $self -> {order};
}

=item $item -> quantity( $quantity );

Sets or retrieves the item quantity.
$quantity is optional.

=cut

sub quantity {
  my $self = shift;
  @_ and $self -> {quantity} = shift;
  return $self -> {quantity};
}

=item $item -> referer( $refer );

Sets or retrieves the item referer.
$ref is optional.

=cut

sub referer {
  my $self = shift;
  @_ and $self -> {referer} = shift;
  return $self -> {referer};
}

=item $item -> type_id( $type_id );

Sets or retrieves the item type.
Each Neopian item has a number
associated with an item.  For
example, all the 'Healing Potion I'
items have a unique number which
all items of that type share.
$type_id is optional.

=cut

sub type_id {
  my $self = shift;
  @_ and $self -> {type_id} = shift;
  return $self -> {type_id};
}

1;

=back

=head1 SUB CLASSES

See Neopets::Config::

=head1 COPYRIGHT

Copyright 2002

Neopets::* are the combined works of Alex Avriette and
Matt Harrington.

Matt Harrington <narse@underdogma.net>
Alex Avriette <avriettea@speakeasy.net>

The perl5.5 vs perl < 5.5 build process is stolen with
permission from sungo and the POE team (poe.perl.org),
mostly verbatim.

I suppose we should thank the Neopets people too for
making such a thoroughly enjoyable site. Maybe one day
they will make a text interface for their site so we
wouldnt have to code an API around the LWP:: and 
HTTP:: modules, but probably not. Until then...

=head1 LICENSE

Please see the enclosed LICENSE file for licensing information.

=cut
