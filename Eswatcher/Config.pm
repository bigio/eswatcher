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

package Eswatcher::Config;

sub new {
        my ($class_name) = @_;

        my ($self) = {};
        bless ($self, $class_name);
        $self->{'config_file'} = '';
	$self->{'fh_cf'} = undef;
        return $self;
}

sub load {
	my ($self, $config_file) = @_;
	if ( -f $config_file ) {
		$self->{'config_file'} = $config_file;
		open $self->{'fh_cf'}, '<', $config_file or return 0;
	} else {
		return 0;
	}
	return 1;
}

sub parse {
	my ($self) = @_;
	my $fh_cf = $self->{'fh_cf'};
	while (<$fh_cf>) {
		chomp;
		next if /^#/;
		# print $_ . "\n";
	}
	close($self->{'fh_cf'});
	$self->{'fh_cf'} = undef;
}

1;