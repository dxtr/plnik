use lib '..';
package Autojoin;
use IRCBot;

my $bot = undef;

sub _init
{
	$bot = $_[0];
	if ($bot)
	{
		print "Hello from Autojoin!";
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
	foreach (@{$bot->{settings}{channels}})
	{
		$bot->IRCBot::join($_)
	}
}

1;