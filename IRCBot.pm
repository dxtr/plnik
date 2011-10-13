package IRCBot;
use strict;
use warnings;
use IRCClient;
use Plugins::Handler;
use utf8;
use Data::Dumper;

our @ISA = ("IRCClient");

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
    my $self = $class->SUPER::new($settings);
    bless($self, $class);

    #$self->add_callback('on_connected', \&_on_connected);
    #warn Dumper($self->{_callbacks});
        # IRCClient::add_callback($self->{_client},'on_join', \&_on_join);
#$self->{_client}->add_callback('on_nick_change', \&_on_nick_change);
#    $self->{_client}->add_callback('on_notice', \&_on_notice);
#    $self->{_client}->add_callback('on_part', \&_on_part);
#    $self->{_client}->add_callback('on_privmsg', \&_on_privmsg);
#    $self->{_client}->add_callback('on_quit', \&_on_quit);
        # bless $self, $class;
    
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

sub add_callback
{
    my ($self, $args) = @_;
    warn Dumper($args);
    die unless $self->SUPER::add_callback($args);
}

sub _init
{
    #my ($self, $settings) = @_;
    #$self->SUPER::_init($settings
}

# wrappers around ircclient
sub join
{
    my ($self, $channel, $key) = @_;
    $self->join($channel, $key);
}

1;
