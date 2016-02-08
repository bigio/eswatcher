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

use Mail::Send;

package Eswatcher::Email;

sub new {
	my ($class_name) = @_;

	my ($self) = {};
	bless ($self, $class_name);
	$self->{'msg'} = new Mail::Send;
	return $self;
}

sub addFrom {
	my ($self, $from) = @_;
	$self->{'msg'}->add( "From", $from);
}

sub addTo {
	my ($self, $to) = @_;
	$self->{'msg'}->add( "To", $to);
}

sub addSubj {
	my ($self, $subj) = @_;
	$subj =~ s/^\"//;
	$subj =~ s/\"$//;
	$self->{'msg'}->add( "Subject", $subj);
}

sub addBody {
	use Data::Dumper;
	my ( $self, $cmfields, @results ) = @_;
	my $mailbody;
	my @mmfields;

	my @mfields = split(/ /, $cmfields);
	for my $i ( 0 .. ( @{$results[0]} - 1 ) ) {
		for my $j ( 0 .. ( @mfields - 1 ) ) {
			if ( ( defined $results[0][$i]->{_source}->{$mfields[$j]} ) or ( $mfields[$j] =~ /[a-z]\.[a-z]/ ) ) {
				# XXX support subfields, only one level atm
				if ( $mfields[$j] =~ /[a-z]\.[a-z]/ ) {
					@mmfields = split(/\./, $mfields[$j]);
					if ( defined $results[0][$i]->{_source}->{$mmfields[0]}->{$mmfields[1]} ) {
						$mailbody .= $mfields[$j] . " -> " . $results[0][$i]->{_source}->{$mmfields[0]}->{$mmfields[1]};
						$mailbody .= "\n";
					}
				} else {
					$mailbody .= $mfields[$j] . " -> " . $results[0][$i]->{_source}->{$mfields[$j]};
					$mailbody .= "\n";
				}
			}
		}
		$mailbody .= "\n";
		$self->{'mailbody'} = $mailbody;
	}
}

sub send {
	my ($self) = @_;
	my $fh = $self->{'msg'}->open;
	print $fh $self->{'mailbody'};
	$fh->close
		or die "couldn't send mail message: $!\n";
}

1;
