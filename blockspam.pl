#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use JSON::MaybeXS;
use Net::OpenSSH;

my $mailbody;

# the first argument is the json temporary file
my $jsonfile = $ARGV[0];
my $json_obj;
# Array with json data
my @results;
my $spammer;
my $host = "";
my $ssh;

open(FH, "< $jsonfile") or die "can't open json file: $!\n";
my $res = <FH>;
close(FH);

$json_obj = JSON::MaybeXS->new(utf8 => 1);
@results = $json_obj->decode($res);

# print Dumper @results;

# The first entity in json aggregation is the email sending more spam
$spammer = $results[0]->{aggregations}->{keywords}->{buckets}[0]->{key};

for my $i ( 0 .. ( @{$results[0]->{hits}->{hits}} - 1 ) ) {
	if ( $results[0]->{hits}->{hits}[$i]->{_source}->{sasl_username} eq $spammer ) {
		if ( $host ne $results[0]->{hits}->{hits}[$i]->{_source}->{host} ) {
			print $results[0]->{hits}->{hits}[$i]->{_source}->{sasl_username};
			print " -> ";
			print $results[0]->{hits}->{hits}[$i]->{_source}->{host};
			# XXX OpenSMTPD non logga gli indirizzi ip (ancora)
			if ( defined $results[0]->{hits}->{hits}[$i]->{_source}->{ip} ) {
				print " -> ";
				print $results[0]->{hits}->{hits}[$i]->{_source}->{ip};
				$ssh = Net::OpenSSH->new($results[0]->{hits}->{hits}[$i]->{_source}->{host}, 'batch_mode' => 1);
				$ssh->error and
					die "Couldn't establish SSH connection: ". $ssh->error;
				my @prg = $ssh->capture("/usr/local/scripts/blockspam.pl $results[0]->{hits}->{hits}[$i]->{_source}->{ip} $results[0]->{hits}->{hits}[$i]->{_source}->{sasl_username}");
				$ssh->error and
					die "remote command command failed: " . $ssh->error;
				print $prg[0];
			}
			print "\n";
		}
		$host = $results[0]->{hits}->{hits}[$i]->{_source}->{host};
	}
}
