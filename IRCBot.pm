package IRCBot;
use strict;
use warnings;
use IRCClient;
use Plugins::Handler;
use utf8;
use Data::Dumper;

sub _on_connected
{
    my ($self) = $_[0];
    warn Dumper($self->{_callbacks});
    warn Dumper($self->{_client}{_callbacks});
    return 0 unless $self->{_callbacks}{on_connected} && ref($self->{_callbacks}{on_connected}) eq "ARRAY";
    foreach (@{$self->{_callbacks}{on_connected}})
    {
        $_->($self);
    }
}
sub _on_join
{
    return;
}

sub _on_nick_change
{
    return;
}

sub _on_notice
{
    return;
}

sub _on_part
{
    return;
}

sub _on_privmsg
{
    return;
}

sub _on_quit
{
    return;
}

sub new
{
    my ($class, $settings) = @_;
    my $self = {
        _client => IRCClient->new($settings->{servers}[0], $settings->{port}, $settings->{nickname}, $settings->{username} || $settings->{nickname}, $settings->{realname} || $settings->{nickname}),
        _plugins => [],
        _callbacks => {},
        _settings => $settings
    };
    
    IRCClient::add_callback($self->{_client},'on_connected', \&_on_connected);
    IRCClient::add_callback($self->{_client},'on_join', \&_on_join);
#$self->{_client}->add_callback('on_nick_change', \&_on_nick_change);
#    $self->{_client}->add_callback('on_notice', \&_on_notice);
#    $self->{_client}->add_callback('on_part', \&_on_part);
#    $self->{_client}->add_callback('on_privmsg', \&_on_privmsg);
#    $self->{_client}->add_callback('on_quit', \&_on_quit);
    bless $self, $class;
    
    if ($self->{_settings}->{modules})
    {
        foreach (@{$self->{_settings}->{modules}})
        {
            if (Handler::load_module($self, $_))
            {
                print "Loaded module $_!";
            }
            else
            {
                print "Couldn't load module $_!";
            }
        }
    }
    
    return $self;
}

# wrappers around ircclient
sub join
{
    my ($self, $channel, $key) = @_;
    $self->{_client}->join($channel, $key);
}

sub add_callback
{
    my ($self, $event, $cb) = @_;
    print "Adding callback $event...";
    if ($self->{_callbacks}{$event} && ref($self->{_callbacks}{$event}) ne "ARRAY")
    {
        $self->{_callbacks}{$event} = [$cb];
    }
    else
    {
        push(@{$self->{_callbacks}{$event}}, $cb);
    }
}

sub is_connected
{
    my $self = $_[0];
    return $self->{_client}->is_connected();
}

sub connect
{
    my $self = $_[0];
    return $self->{_client}->connect();
}

sub tick
{
    my $self = $_[0];
    return $self->{_client}->tick();
}

1;
