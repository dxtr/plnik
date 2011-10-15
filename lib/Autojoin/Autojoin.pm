package Autojoin;
use strict;
use warnings;
use Data::Dumper;

sub autojoin
{
    my $bot = $_[0];
    foreach (@{$bot->{_settings}->{channels}})
	{
        warn Dumper($_);
        $bot->log_line("Joining channel $_->[0]...\n");
		$bot->join($_->[0], $_->[1])
	}
}


sub _init
{
    my $bot = $_[1];
    my $aj = \&autojoin;
	if ($bot && $aj)
	{
        $bot->add_callback("on_connected", \&autojoin);
		return 1;
	}
    warn Dumper($aj);
	return 0;
}

sub _uninit
{
	return;
}

1;
