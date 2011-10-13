package Autojoin;
use Data::Dumper;

sub autojoin
{
    my $bot = $_[0];
    print "Hello from on_connected in Autojoin!\n";
    foreach (@{$bot->{_settings}->{channels}})
	{
        warn Dumper($_);
        print "Joining channel $_->[0]...\n";
		$bot->join($_->[0], $_->[1])
	}
}


sub _init
{
    my $bot = $_[1];
    my $aj = \&autojoin;
	if ($bot && $aj)
	{
		print "Hello from Autojoin!";
        $bot->add_callback("on_connected", $aj);
		return 1;
	}
    warn Dumper($aj);
	return 0;
}

sub _uninit
{
	print "Goodbye from Autojoin!";
	return;
}

1;
