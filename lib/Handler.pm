package Handler;
use utf8;

sub load_module
{
	my ($bot, $module) = @_;
	my $retval = 0;
	my $file = $module;
	
	return $retval unless defined $module;
	
	$file =~ s{::}{}g;
	$file =~ s{/}{}g;
	eval { require "lib/$file/$file.pm"; };
	if ($@) { print $@; return 0; }
	
	push(@{$bot->{_plugins}}, $file);
	$file->_init($bot);
	return $file;
}

sub unload_module
{
	my ($bot, $module) = @_;
	return 0 unless defined $module;
	my $file = (grep /\/$module/, keys %INC)[0];
	my $index = grep { $array[$_] =~ /$module/} 0..$#{$bot->{_plugins}};
	return 0 unless $file && $index;
	
	if ($mod =~ /::/ or $mod !~ /pl$/)
	{
		return 0;
	}
	
	if (!-f $file)
	{
		return 0;
	}
	
	$module->_uninit($bot);
	delete ${$bot->{_plugins}}[0];
	delete $INC{$file};
	
	return 1;
}
1;
