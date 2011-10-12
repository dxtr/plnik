package IRCClient;
use strict;
use warnings;
use IO::Socket::INET;

sub new
{
	my ($class, $addr, $port, $nick, $username, $realname) = @_;
	my $self = {
		_socket => 0,
		_connected => 0,
		_active_session => 0,
		_nick_lists => undef,
		_recv_buf => '',
		_callbacks => {},
		_lines => '',
		_wait_until => 0,
		_server_address => $addr,
		_server_port => $port,
		_nickname => $nick,
		_username => $username,
		_realname => $realname,
		_event_handlers => {
			'JOIN' => \&_on_join,
			'KICK' => \&_on_kick,
			'NICK' => \&_on_nick,
			'PART' => \&_on_part,
			'QUIT' => \&_on_quit,
			'PING' => \&_on_ping,
			'PRIVMSG' => \&_on_privmsg,
			'NOTICE' => \&_on_notice,
			'ERROR' => \&_on_error,
			#'353' => '',
			#'366' => '',
			#'372' => '',
			'376' => \&_on_connected,
			'001' => \&_on_connected
		}
	};
	bless $self, $class;
	return $self;
}

# Message handlers
## ARGS: event, Source, target, args
sub _on_ping
{
	my ($self, $reply) = @_;
	if (defined($reply))
	{
		$self->log_line("[PING] $reply");
		$self->send("PONG $reply");
	}
}
sub _on_privmsg
{
	my ($self, $event, $src, $target, $text) = @_;
	if (defined($event) && defined($src) && defined($target) && defined($text))
	{
		$self->log_line("[PRIVMSG] $src -> $target: $text");
		if (exists($self->{_callbacks}{'on_privmsg'}))
		{
			foreach ($self->{_callbacks}{'on_privmsg'})
				{ $_->($self, $src, $target, $text); }
		}
	}
}
sub _on_quit
{
	return;
}

sub _on_error
{
	return;
}

sub _on_notice
{
	my ($self, $event, $src, $target, $text) = @_;
	if (defined($event) && defined($src) && defined($target) && defined($text))
	{
		$self->log_line("[NOTICE] $src -> $target: $text");
		if (exists($self->{_callbacks}{'on_notice'}))
		{
			foreach ($self->{_callbacks}{'on_notice'})
				{ $_->($self, $src, $target, $text); }
		}
	}
}
sub _on_connected
{
	my ($self, $event, $server) = @_;
	if (defined($event) && defined($server))
	{
		$self->log_line("[CONNECTED] $server");
		if (exists($self->{_callbacks}{'on_connected'}))
		{
			foreach ($self->{_callbacks}{'on_connected'})
				{ $_->($self, $server); }
		}
	}
}
sub _on_join
{
	my ($self, $event, $who, $channel) = @_;
	if (defined($who) && defined($channel))
	{
		$self->log_line("[JOIN] $who -> $channel");
		if (exists($self->{_callbacks}{'on_join'}))
		{
			foreach ($self->{_callbacks}{'on_join'})
				{ $_->($self, $who, $channel); }
		}
	}
}

sub _on_part
{
	return;
}

sub _on_kick
{
	my ($self, $event, $who, $channel, $args) = @_;
	if (defined($who) && defined($channel) && defined($args))
	{
		$self->log_line("[KICK] $who ($channel) -> $args");
		if (exists($self->{_callbacks}{'on_kick'}))
		{
			foreach ($self->{_callbacks}{'on_kick'})
				{ $_->($self, $who, $channel, $args); }
		}
	}
}

sub _on_nick
{
	my ($self, $event, $who, $newnick) = @_;
	if (defined($who) && defined($newnick))
	{
		if (exists($self->{_callbacks}{'on_nick'}))
		{
		foreach ($self->{_callbacks}{'on_nick'})
			{ $_->($self, $who, $newnick); }
		}
	}
}

sub connect {
	my $self = $_[0];
	my $errmsg = '';
	$self->{_socket} = IO::Socket::INET->new(Proto => 'tcp',
								Timeout => 30,
								Type => SOCK_STREAM, 
								PeerAddr => $self->{_server_address},
								PeerPort => $self->{_server_port},
								Blocking => 1)
								or $errmsg = "[ERROR] $!";
	if ($errmsg)
	{
		$self->log_line("Can't connect to $self->{_server_address}! $errmsg");
		return 0;
	}
	else
	{
		$self->{_connected} = 1;
		return 1;
	}
}

sub send
{
	my ($self, $line) = @_;
	$self->log_line("[" . time() . "] SENT: $line");
	#print $self->{_socket} $line;
	$self->{_socket}->send($line . "\r\n");
}

sub is_connected
{
	my $self = $_[0];
	return $self->{_connected};
}

sub idle {
	my ($self, $time) = @_;
	$self->{_wait_until} = time()+$time;
}

sub log_line {
	my ($self, $line) = @_;
	print "[" . time() . "] ($self->{_nickname}) $line\n";
}

sub tick {
	my $self = $_[0];
	my $retn = 0;
	my $line = '';
	my $errmsg = '';
	if ($self->{_wait_until} && $self->{_wait_until} > time()) { return 0; }
	
	if ($self->{_connected})
	{
		$line = readline($self->{_socket});
		if ($!) {
			print "[ERROR] $!";
			$self->{_connected} = undef;
			$self->{_socket}->close();
			return -1;
		}
		
		chomp($line);
		
		$self->log_line($line);
		
		if ($line =~ /^(:([^  ]+))?[   ]*([^  ]+)[  ]+:?([^  ]*)[   ]*:?(.*)$/)
		{
			#my ($source, $event, $target, $args) = ($2, $3, $4, $5);
			if (exists($self->{_event_handlers}{$3}))
			{
				$self->{_event_handlers}{$3}->($self,$3,$2,$4,$5);
			}
		}
		elsif ($line =~ /^PING (:.+)$/)
		{
			if (exists($self->{_event_handlers}{'on_ping'}))
			{
				$self->{_event_handlers}{'on_ping'}->($self,$1);
			}
		}
	} 
	else
	{
		print "Connecting...";
		if ($self->connect() == 1)
		{
			$self->send("USER $self->{_username} * * :$self->{_realname}");
			$self->send("NICK $self->{_nickname}");
		}
	}
	
	return 1;
}

1;