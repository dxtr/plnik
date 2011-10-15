package IRCBot;
use strict;
use warnings;
use IRCClient;
use lib::Handler;
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

sub add_callback
{
    my ($self, $event, $cb) = @_;
    die unless $self->SUPER::add_callback($event, $cb);
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
