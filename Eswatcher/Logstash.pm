#!/usr/bin/perl

use strict;
use warnings;

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

# XXX use an array instead of a variable to handle more variables ?
sub parse {
    my ($self, $var) = @_;

    my $parsed;
    $parsed = sprintf($self->{'json_text'}, $var);
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
	body   => eval($self->{'parsed_json_text'})
	);
    return $results
}

1;
