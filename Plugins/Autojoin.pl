package Autojoin;
use Data::Dumper;

my $bot = undef;

sub autojoin
{
    print "Hello from on_connected in Autojoin!";
	foreach (@{$bot->{settings}{channels}})
	{
        print "Joining channel $_[0]...";
		IRCBot::join($bot, $_[0], $_[1])
	}
}


sub _init
{
	$bot = $_[1];
    warn Dumper(@_);
	if ($bot)
	{
		print "Hello from Autojoin!";
		warn Dumper($bot);
        my $test = \&autojoin;
        warn Dumper($test);
        $bot->add_callback("on_connected", \&autojoin);
		return 1;
	}
	return 0;
}

sub _uninit
{
	print "Goodbye from Autojoin!";
	return;
}

1;
