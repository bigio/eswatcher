#!/usr/bin/perl

#------------------------------------------------------------------------------
# Copyright (c) 2016, Giovanni Bechis
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#------------------------------------------------------------------------------

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
