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

use JSON::MaybeXS;
use Search::Elasticsearch;

package Eswatcher::Logstash;

sub new {
	my ($class_name) = @_;

	my ($self) = {};
	bless ($self, $class_name);
	$self->{'json_text'} = '';
	$self->{'parsed_json_text'} = '';
	return $self;
}

sub load {
    my ($self, $json_file) = @_;
    my $json_text;

    open(my $fh, $json_file) or die "Can't open $json_file: $!";

    while ( ! eof($fh) ) {
        defined( $_ = <$fh> )
            or die "readline failed for $json_file: $!";
        $json_text .= $_;
    }
    close($fh);
    $self->{'json_text'} = $json_text;
}

sub parse {
    my ($self, $conf) = @_;
    my $parsed;

    # Replace every variable in the json template file
    for my $i ( 0 .. ( $conf->{'config'}{'VARCOUNT'} - 1 ) ) {
	$parsed = sprintf($self->{'json_text'}, $conf->{'config'}{"VAR$i"});
    }
    $parsed =~ s/\:/\=\>/g;
    $parsed =~ s/\@/\\@/g;
    $self->{'parsed_json_text'} = $parsed;
}

sub search {
    my ($self, $date, $conf) = @_;

    my $e = Search::Elasticsearch->new();

    my $results = $e->search(
	index  => "$conf->{'config'}{'INDEX'}$date",
	type   => "$conf->{'config'}{'TYPE'}",
	scroll => '60s',
	size   => 100,
	ignore => 404,
	body   => eval($self->{'parsed_json_text'})
	);
    return $results
}

sub dump_json {
    my ($self, $res) = @_;

    my $json_obj = JSON::MaybeXS->new(utf8 => 1);
    return $json_obj->encode($res);
}

1;
