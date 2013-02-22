package IRCBot;
use strict;
use warnings;
use IRCClient;
use lib::Handler;
use utf8;
use Data::Dumper;

our @ISA = ("IRCClient");

sub new
{
	my ($class, $settings) = @_;
	my $self = $class->SUPER::new($settings);
	bless($self, $class);

	if ($self->{_settings}->{modules})
	{
		foreach (@{$self->{_settings}->{modules}})
		{
			my $mod = $_;
			if (Handler::load_module($self, $mod))
			{
				print "Loaded module $mod!";
			}
			else
			{
				print "Couldn't load module $mod!";
			}
		}
	}

	return $self;
}

sub quit
{
	my ($self, $reason) = ($_[0], $_[1]);

	# First kill all the plugins gracefully
	Handler::unload_all_modules($self);

	$self->SUPER::quit($reason);
}

sub add_callback
{
	my ($self, $event, $cb) = @_;
	$self->SUPER::add_callback($event, $cb);
}

# wrappers around ircclient
sub join
{
	my ($self, $channel, $key) = @_;
	print "joining channel $channel...\n";
	$self->SUPER::join($channel, $key);
}

sub privmsg
{
	my ($self, $target, $message) = @_;
	$self->SUPER::privmsg($target, $message);
}

1;
