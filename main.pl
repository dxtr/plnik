use strict;
use IRCBot;
use Data::Dumper;
use JSON;
use utf8;

# Load settings
my $json = '';
my $settings = undef;
open SETTINGSFILE, "<settings.json" or die "Can't read settings!";
while (<SETTINGSFILE>)
{
	$json .= $_;
}
close SETTINGSFILE;
$settings = JSON::decode_json($json);

# Create the bot
my $client = IRCBot->new($settings);

while (1)
{
	my $i = $client->tick();
	last if ($i == -1);
};
