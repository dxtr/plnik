use strict;
use IRCClient;
use Data::Dumper;

my $client = IRCClient->new("irc.freenode.net", 6667, "LongJohnson", "LongJohnson", "Long Johnson");
#warn Dumper($client);
while (1)
{
	my $i = $client->tick();
	last if ($i == -1);
};