#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use JSON::MaybeXS;

my $mailbody;

# the first argument is the json temporary file
my $jsonfile = $ARGV[0];
my $json_obj;
# Array with json data
my @results;
my $spammer;

open(FH, "< $jsonfile") or die "can't open json file: $!\n";
my $res = <FH>;
close(FH);

$json_obj = JSON::MaybeXS->new(utf8 => 1);
@results = $json_obj->decode($res);

 print Dumper @results;

# The first entity in json aggregation is the email sending more spam
$spammer = $results[0]->{aggregations}->{keywords}->{buckets}[0]->{key};

print $spammer;
