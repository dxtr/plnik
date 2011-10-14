package Markov;
use threads;
use Algorithm::MarkovChain;
use Data::Dumper;

my $words = [];
my $next_save = 0;
my $next_reload = 0;
my $mchain = undef;

sub reseed
{
    if ($next_reload <= time())
    {
        $mchain = Algorithm::MarkovChain::->new();
        $mchain->seed(symbols => $words, longest => 15);
        $next_reload = time()+1800;
    }
}

sub resave
{
    if ($next_save <= time())
    {
        my $fh;
        open $fh, ">markov.json";
        if ($fh)
        {
            foreach (@{$words})
            {
                print $fh "$_";
            }
        }
        close $fh;
        $next_save = time()+1800;
    }
}

sub genmessage
{
    if ($mchain)
    {
        my @line = $mchain->spew();
        my $message = join(' ', @line);
        return $message;
    }
    return undef;
}

sub load
{
    my $fh;
    open $fh, "<markov.json";
    while (<$fh>)
    {
        my $word = $_;
        chomp($word);
        push (@{$words}, $word);
    }
    close $fh;
}

sub worker
{
    warn "Markov worker!\n";
    my ($bot, $args) = @_;
    if ($bot && $args)
    {
        warn Dumper($args);
        if (@words)
        {
            warn "Words is working!\n";
            reseed();
            resave();
            my $msg = genmessage();
            $bot->privmsg($args->{source}, $message) if $msg;
        }
    }
}

sub _init
{
    my $bot = $_[1];
	print "Hello form Markov!";

    load();
    reseed();

    my $worker_reference = \&worker;
    $bot->add_callback("on_privmsg", $worker_reference);
}

sub _uninit
{
	print "Goodbye from Markov :(";
    my $fh;
    open $fh, ">markov.json";
    if ($fh)
    {
        foreach (@words)
        {
            print $fh "$_\n";
        }
        close $fh;
    }
}

1;
