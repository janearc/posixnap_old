#
# retort.pm
# REQUIREMENTS:
#	non-blocking db calls.
# because we have non-blocking db calls, we need to handle our own output.
# sophisticated DB queries to offload code to the database, not perl.
#	adaptability.
#
#	SYNOPSIS:
# when a user says something, it is probably appropriate to say something back.
# here's the description of what happens:
# <alex> what in the hell is wrong with the database?
#
# ... here we see if we can match pieces of the string. we neeed to understand 
#		context. thats the hard part. NOTE: this can probably be done with a simple 
#		synonym table. see if Lingua:: does synonyms.
#
# ... if we find the exact string, we can see if anyone replied to it. if 
# 	somebody replied to it, figure out what the replies were, grab say 10 of 
# 	them, rank them in order by how soon they were spoken to our trigger. 
# 	however, it would be good to also know when something was the *wrong* answer.
# 	for this we need a method of checking whether something was a bad retort.
# 	that also is complicated.
# 
# ... it might be possible to have people "sign" retorts and factoids. I think
# 	ideally, it would be good to have all the retorts and factoids in the same place.
# 	afterall, what is the difference between "AMD?" returning "advanced micro devices"
# 	and it returning "AMD is blah de blah blah." or "advanced micro something mumble".
# 	this way you can have users verify it. HOWEVER (XXX:) it would be important to make
# 	sure that the bot can express some NOVELTY, or we will get the same old repetitive
# 	behaviour. as kids we read "choose your own adventure" books because they could be
# 	different. repetition is not fun on a period of years. so it would be cool to have
# 	"ranking" and "signatures" 
# 	see this note on signing: http://usefulinc.com/foaf/signingFoafFiles
# 	i think that pgp is excessive here.
