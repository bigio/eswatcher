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
use Getopt::Std;
use File::Temp qw/ tempfile tempdir /;
use POSIX qw/strftime/;

use Eswatcher::Config;
use Eswatcher::Logstash;
use Eswatcher::Email;

my $config_file = "eswatcher.conf";
my %opts = ();
my $date = strftime "%Y.%m.%d", localtime;
my $type;
my $results;
my $minutes;
my $tmpjsonfile;
my $fh_tj;
my $progparams;

my $conf = new Eswatcher::Config;
my $logst = new Eswatcher::Logstash;
my $email;

getopts('c:h', \%opts);
if ( defined $opts{'c'} ) {
	$config_file = $opts{'c'};	
}
if ( defined $opts{'h'} ) {
        print "Usage: $0 [-ch]\n";
        exit;
}

if ( $conf->load($config_file) ) {
	$conf->parse;
	# print Dumper $conf;
	$logst->load($conf->{'config'}{'QUERY'});
	$logst->parse($conf);
	if ( defined $conf->{'config'}{'DATE'} ) {
		$date = $conf->{'config'}{'DATE'};
	}
	if ( defined $conf->{'config'}{'TYPE'} ) {
		$type = $conf->{'config'}{'TYPE'};
	}
	my $results = $logst->search($date, $conf);
	# print Dumper $results;
	if ( defined $results and ( $results->{hits}->{total} > $conf->{'config'}{MIN_DOC} ) ) {
		if ( $conf->{'config'}{'ACTION'} eq "email" ) {
			$email = new Eswatcher::Email;
			$email->addFrom( $conf->{'config'}{'PARAMS'}{'FROM'} );
			$email->addTo( $conf->{'config'}{'PARAMS'}{'TO'} );
			$email->addSubj( $conf->{'config'}{'PARAMS'}{'SUBJ'} );
			# Add Aggregations to body
			$email->addAggsBody( $results->{aggregations}->{keywords}->{buckets} );
			# Add Fields to body
			$email->addFieldsBody( $conf->{'config'}{'PARAMS'}{'EMAIL_FIELDS'}, $results->{hits}->{hits} );
			$email->send;
		} elsif ( $conf->{'config'}{'ACTION'} eq "program" ) {
			# Create a temp file containing the json result,
			# will be the first argument of the program forked
			# the temp file will be deleted when the main program
			# will exit
			($fh_tj, $tmpjsonfile) = tempfile("eswatcher.XXXXXXXX",
				TMPDIR => 1,
				UNLINK => 1);

                        print $fh_tj $logst->dump_json($results);
                        close($fh_tj);
			$progparams = $tmpjsonfile . " " . $conf->{'config'}{'PARAMS'}{'PARAMETERS'};
			system( $conf->{'config'}{'PARAMS'}{'PROGNAME'} . " " . $progparams );
		} else {
			die("No action specified in configuration file\n");
		}
	}
} else {
	die "Cannot find config file $config_file\n";
}
