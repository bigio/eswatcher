#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use JSON::MaybeXS;

my $mailbody;

my $jsonfile = $ARGV[0];
open(FH, "< $jsonfile") or die "I can't open counttext: $!\n";
my $res = <FH>;
close(FH);

my $json_obj = JSON::MaybeXS->new(utf8 => 1);
my @results = $json_obj->decode($res);

# print Dumper @results;

for my $i ( 0 .. ( @{$results[0]->{aggregations}->{keywords}->{buckets}} - 1 ) ) {
	$mailbody .= $results[0]->{aggregations}->{keywords}->{buckets}[$i]->{key} . " -> " . $results[0]->{aggregations}->{keywords}->{buckets}[$i]->{doc_count};
	$mailbody .= "\n";
}

print $mailbody;
