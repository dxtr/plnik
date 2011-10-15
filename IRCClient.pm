package IRCClient;
use strict;
use warnings;
use IO::Socket::INET;
use Data::Dumper;
use utf8;

sub new
{
    my ($class, $settings) = @_;
    my $self = {
        running => 1,
        _socket => 0,
        _connected => 0,
        _active_session => 0,
        _nick_lists => {},
        _callbacks => {},
        _lines => [],
        _send_queue => [],
        _wait_until => time(),
        _settings => $settings,
        _event_handlers => {
            'JOIN' => \&_on_join,
            'KICK' => \&_on_kick,
            'NICK' => \&_on_nick,
            'PART' => \&_on_part,
            'QUIT' => \&_on_quit,
            'PING' => \&_on_ping,
            'PRIVMSG' => \&_on_privmsg,
            'NOTICE' => \&_on_notice,
            'MODE' => sub { return; },
            'ERROR' => sub { return; },
            '353' => sub { return; },
            '366' => sub { return; },
            '372' => sub { return; },
            '376' => sub { return; },
            '001' => \&_on_connected,
            '002' => sub { return; },
            '003' => sub { return; },
            '004' => sub { return; },
            '005' => sub { return; },
            '251' => sub { return; },
            '252' => sub { return; },
            '254' => sub { return; },
            '255' => sub { return; },
            '265' => sub { return; },
            '266' => sub { return; },
            '422' => sub { return; },

        }
    };
    bless $self, $class;
    return $self;
}

sub is_running
{
    my ($self) = @_;
    return $self->{running};
}

sub quit
{
    my ($self, $reason) = ($_[0], $_[1]);
    if (!$reason) { $reason = "I'm outta here"; }

    $self->disconnect($reason);
    $self->{running} = 0;
}

# Stuff to make things work
sub join
{
    my ($self, $channel, $key) = @_;
    if ($channel)
    {
        if ($key)
        {
            $self->queue_msg("JOIN $channel $key");
        }
        else
        {
            $self->queue_msg("JOIN $channel");
        }
    }
}

sub privmsg
{
    my ($self, $target, $message) = @_;
    if ($target && $message)
    {
        $self->queue_msg("PRIVMSG $target :$message");
    }
}

sub _on_ping
{
    my ($self, $args) = @_;
    if (%{$args})
    {
        $self->log_line("[$args->{event}] $args->{response}");
        $self->_send("PONG :$args->{response}");
    }
}
sub _on_privmsg
{
    my ($self, $args) = @_;
    if (%{$args})
    {
        $self->log_line("[$args->{event}] $args->{source} -> $args->{target}: $args->{message}");
        if ($self->{_callbacks}{on_privmsg})
        {
            foreach (@{$self->{_callbacks}->{on_privmsg}})
                { $_->($self, $args); }
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
    my ($self, $args) = @_;
    if (%{$args})
    {
        if (!$args->{source})
        {
            $self->log_line("[$args->{event}] $args->{target}: $args->{message}");
        }
        else
        {
            $self->log_line("[$args->{event}] $args->{source} -> $args->{target}: $args->{message}");
        }

        if ($self->{_callbacks}{on_notice})
        {
            foreach (@{$self->{_callbacks}->{on_notice}})
                { $_->($self, $args); }
        }
    }
}
sub _on_connected
{
    my ($self, $args) = @_;
    if (%{$args})
    {
        $self->log_line("[CONNECTED] $args->{source}");
        if ($self->{_callbacks}->{on_connected})
        {
            $self->log_line("Found an on_connected callback...");
            foreach (@{$self->{_callbacks}->{on_connected}})
            {
                $_->($self, $args);
            }
        }
    }
}
sub _on_join
{
    my ($self, $event, $who, $channel) = @_;
    if (defined($who) && defined($channel))
    {
        $self->log_line("[JOIN] $who -> $channel");
        if ($self->{_callbacks}{'on_join'})
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
        if ($self->{_callbacks}{'on_kick'})
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
        if ($self->{_callbacks}{'on_nick'})
        {
        foreach ($self->{_callbacks}{'on_nick'})
            { $_->($self, $who, $newnick); }
        }
    }
}

sub connect {
    my $self = $_[0];
    $self->{_socket} = IO::Socket::INET->new(Proto => 'tcp',
                                Timeout => 30,
                                Type => SOCK_STREAM, 
                                PeerAddr => $self->{_settings}->{servers}->[0],
                                PeerPort => $self->{_settings}->{port},
                                Blocking => 1);
    if ($!)
    {
        $self->log_line("[ERROR] Can't connect to $self->{_settings}->{servers}->[0]!");
        return 0;
    }
    
    $self->{_connected} = 1;
    return 1;
}

sub disconnect
{
    my ($self, $reason) = @_;
    if (!$reason) { $reason = "I'm outta here"; }

    $self->_send("QUIT :$reason");
    close ($self->{_socket});
}

sub _send
{
    my ($self, $line) = @_;
    return unless $line;
    $self->log_line("[SENT] $line");
    #print $self->{_socket} $line;
    $self->{_socket}->send($line . "\r\n");
}

sub queue_msg
{
    my ($self, $msg) = @_;

    push(@{$self->{_send_queue}}, $msg);
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
    print "[" . time() . "] ($self->{_settings}->{nickname}) $line\n" if $line;
}

sub recv
{
    my $self = $_[0];
    my $buf = readline($self->{_socket});
    if ($!)
    {
        $self->log_line("ERROR! $!");
        $self->{_connected} = undef;
        $self->{_socket}->close();
        return -1;
    }

    push(@{$self->{_lines}}, split(/\r\n/, $buf)) if $buf;
}

sub parse_line
{
    my $self = $_[0];
    if ($self->{_connected})
    {
        my $line = pop(@{$self->{_lines}});
        if ($line =~ /^(:([^  ]+))?[   ]*([^  ]+)[  ]+:?([^  ]*)[   ]*:?(.*)$/)
        {
            if ($3 eq "PING")
            {
                return({'event' => $3, 'response' => $4});
            }
            else
            {
                return({'event' => $3, 'source' => $2, 'target' => $4, 'message' => $5});
            }
        }
    }
    return 0;
}

sub handle_event
{
    my ($self, $ircmsg) = @_;

    if (%{$ircmsg})
    {
        if ($self->{_event_handlers}{$ircmsg->{event}})
        {
            $self->{_event_handlers}{$ircmsg->{event}}->($self, $ircmsg);
        }
        else
        {
            $self->log_line("Unhandled event: $ircmsg->{event}");
        }
    }
}

sub tick {
    my $self = $_[0];
    my $retn = 0;
    my $tmp_buf = undef;
    my @tmp_lines = undef;
    my $line = undef;
    my $irc_message = undef;

    return 0 unless $self->is_running();

    if ($self->{_connected})
    {
        # Recieve some data
        $self->recv();

        # Parse the entire queue while we're at it
        while (@{$self->{_lines}})
        {
            $irc_message = $self->parse_line();
            if (!%{$irc_message})
            {
                print "Couldn't parse a message from the server\n";
            }

            $self->handle_event($irc_message);
        }

        # Send away a message
        if (@{$self->{_send_queue}})
        {
            if ($self->{_wait_until} <= time() && @{$self->{_send_queue}})
            {
                my $sendmsg = pop(@{$self->{_send_queue}});
                $self->_send($sendmsg);
                $self->{_wait_until} = time()+2;
            }
        }
    } 
    else
    {
        if ($self->connect() == 1)
        {
            $self->_send("USER $self->{_settings}->{username} * * :$self->{_settings}->{realname}");
            $self->_send("NICK $self->{_settings}->{nickname}");
        }
    }

    return 1;
}

sub add_callback
{
    my ($self, $event, $callback) = @_;
    return 0 unless $event && $callback;
    
    if (!$self->{_callbacks}->{$event} || ref($self->{_callbacks}->{$event}) ne "ARRAY")
    {
        $self->{_callbacks}->{$event} = []
    }
    
    push(@{$self->{_callbacks}->{$event}}, $callback);
    print "Added callback!";
    return 1;
}

1;
