code
# insults/argues with the user.
sub bad_bot {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "bad_bot" if @_ == 0;
  my @bitches = (
    "$mynick is (a|my) bitch",
    "$mynick sucks",
    "$mynick blows",
    "$mynick (is a|you) lam(0|e|o)r",
    "$mynick stinks",
    "$mynick,? you stink",
    "$mynick,? is a piece of shit",
    "$mynick,? you are a piece of shit",
    "ba+d bot",
    "$mynick is ugly",
    "$mynick,? you are ugly",
    "$mynick,? you're ugly",
    "you suck,? $mynick",
    "$mynick,? fuck you",
    "fuck you,? $mynick",
    "$mynick,? fuck off",
    "fuck off,? $mynick",
    "$mynick,? stupid bot",
    "$mynick,? you are a stupid bot",
    "$mynick!+",
  );
  my $partial = join "|", @bitches;
  $partial = qr{$partial};
  return unless $thismsg =~ /^(?:$mynick)?,?\s*$partial!*/i;
  my @quips = (
    "bite me, $thisuser",
		"i dont like the bugs but the bugs like me",
    "somebody's looking for you in #visualbasic, $thisuser",
    "$thisuser--",
    "well at least i dont look like $thisuser",
    "didnt get your daily dose of solitaire, $thisuser?",
    "dont blame me for bugs in your code, $thisuser.",
    "you only think youre superior because you cannot comprehend my genius.",
    "sometimes, $thisuser, i get down on myself, but then i realize im not you. :p",
    "$thisuser: i 0wn you",
    "try fiber.",
    "pms is a bitch, aint it $thisuser?",
    "its too bad you suck so much... i might actually pay attention to you!",
    "have you considered euthanising yourself, $thisuser?",
    "youre not fit to lick the fungus off a troll's nuts, like i care what you think.",
    "pubic hair in the back of your throat causing irritation?",
    "<-- root\@your_box",
    "as if, $thisuser",
    "pshaw, when monkeys fly out of my ass, $thisuser",
    "4... would that be your iq or your grade?",
    "so's your mom, $thisuser",
    "may the anus of wisdom grant you a squirt or two, $thisuser...",
  );
  my $retort;
  $retort = $quips[ rand @quips + 1 ] while $retort !~ /\w/;
  $nap -> public_message( $retort );
  return 1;
}

(1 row)
