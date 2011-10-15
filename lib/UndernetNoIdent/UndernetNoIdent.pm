package UndernetNoIdent;
use strict;
use warnings; 

sub _init
{
    my $bot = $_[1];
    my $ref = \&notice_trigger;

    $bot->add_callback("on_notice", \&notice_trigger);
}

sub _uninit
{
    return;
}

sub notice_trigger
{
    my ($bot, $args) = @_;

    if ($args->{target} eq "AUTH" && $args->{message} =~ m/No response to ident check, to continue to connect you must type \/QUOTE PASS ([0-9]+)/)
    {
       $bot->queue_msg("PASS $1"); 
    }

    return;
}

1;
