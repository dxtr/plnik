use lib '..';
package Autojoin;
use IRCBot;
use Data::Dumper;

my $bot = undef;

sub _init
{
	$bot = $_[1];
    warn Dumper(@_);
	if ($bot)
	{
		print "Hello from Autojoin!";
		warn Dumper($bot);
        IRCBot::add_callback($bot, "on_connected", \&on_connected);
		return 1;
	}
	return 0;
}

sub _uninit
{
	print "Goodbye from Autojoin!";
	return;
}

sub on_connected
{
    print "Hello from on_connected in Autojoin!";
	foreach (@{$bot->{settings}{channels}})
	{
        print "Joining channel $_[0]...";
		IRCBot::join($bot, $_[0], $_[1])
	}
}

1;
