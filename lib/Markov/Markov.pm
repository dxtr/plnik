package Markov;
use Data::Dumper;
use JSON;
use List::Util qw(sum);

my $global_itable = undef; # Index table
my $itable_file = "markov_itable.json";
my $next_save = 0;

sub load_itable
{
    my $fh;
    my $buffer = '';
    my $itable = undef;

    if (!open($fh, "<", $itable_file))
    {
        print "Couldn't load $itable_file: $!\n";
        return 0;
    }
    
    while (<$fh>)
    {
        $buffer .= $_;
    }

    close $fh;
    $itable = JSON->new->utf8->decode($buffer);

    return $itable;
}

sub save_itable
{
    my $itable = $_[0];
    return 0 unless $itable;
    my $fh;
    my $buffer = JSON->new->utf8->pretty([1])->encode($itable);
    return 0 unless $buffer;
    if (!open($fh, ">", $itable_file))
    {
        print "Couldn't open $itable_file for saving: $!\n";
        return 0;
    }

    print $fh $buffer;
    close $fh;
    return 1;
}

sub generate_index_table
{
    my ($text, $itable) = @_;
    return unless $text && $itable;

    my @split_text = split(/ /, $text);
    for ($i = 0; $i < @split_text; $i++)
    {
        if (!$itable->{$split_text[$i]}->{$split_text[$i+1]})
        {
            $itable->{$split_text[$i]}->{$split_text[$i+1]} = 1;
        }
        else
        {
            $itable->{$split_text[$i]}->{$split_text[$i+1]}++;
        }
    }
    return $itable;
}

sub return_weighted_char
{
    my $char = $_[0];
    return 0 unless $char;

    my $sum = 0;
    foreach (keys $char) { $sum += $char->{$_}; }
    my $rand = rand($sum);

    foreach $item (keys $char)
    {
        my $weight = $char->{$item};
        if ($rand <= $weight) { return $item; }
        else { $rand -= $weight; }
    }
    
    return 0;
}

sub generate_markov_text
{
    my $itable = $_[0];
    return 0 unless $itable;
    my @itable_elements = keys %$itable;
    return 0 unless @itable_elements;

    my $char = $itable_elements[rand @itable_elements];
    my $text = "$char ";

    for ($i = 0; length($text) < 450; $i++)
    {
        warn Dumper($text);
        # Give it a 50% chance to stop after ten words
        last if ($i > 10 && rand(10) > 5);

        $new_char = return_weighted_char($itable->{$char});
        
        if ($new_char)
        {
            $char = $new_char;
            $text .= "$char ";
        }
        else
        {
            $char = $itable_elements[int(rand(@itable_elements))];
        }
    }

    return $text;
}

sub worker
{
    my ($bot, $args) = @_;
    return unless $bot && $args && $args->{target} =~ m/^#/;
    my $itable = generate_index_table($args->{message}, $global_itable);
    if ($itable) { $global_itable = $itable; }

    my $msg = generate_markov_text($global_itable);
    warn Dumper($msg);
    $bot->privmsg($args->{target}, $msg) if $msg;

    if ($next_save < time())
    {
        save_itable();
        $next_save = time()+1800;
    }
}

sub _init
{
    my $bot = $_[1];

    $global_itable = load_itable();
    $next_save = time()+1800; # Don't save for 30 minutes... at least

    my $worker_reference = \&worker;
    $bot->add_callback("on_privmsg", $worker_reference);
}

sub _uninit
{
    save_itable();
}

1;
