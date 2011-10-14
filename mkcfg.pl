use strict;
use warnings;
use JSON;

my %settings = ('server' => {'FreeNode' => ['irc.undernet.org']}, 'port' => 6667,
	'password' => '', 'ssl' => 0, 'nickname' => 'plnik', 'username' => 'plnik',
	'realname' => 'plnik', 'bind' => '0.0.0.0', 'owner' => 'dxtr!*@unaffiliated/dxtr',
	'modules' => ['Autojoin', 'Markov']);
my $sref = \%settings;
my $json = JSON->new->pretty([1]);

open(THEFILE, ">settings.json");
print THEFILE $json->encode($sref);
close(THEFILE);
