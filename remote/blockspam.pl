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

use DBI;

my $db="dbispconfig";
my $host="localhost";
my $user="ispconfig";
my $pass="";

my $conn;
my $query;

if ($#ARGV != 1) {
 print "usage: blockspam.pl ip email\n";
 exit;
}

my $ip=shift;
my $email=shift;

die "Script should not run as root, use sudo/doas instead\n" if ( $< == 0 );

if ( $^O eq "openbsd" ) {
	system("/usr/bin/doas /sbin/pfctl -k $ip");
} else {
	# kill spammer ip address with iptables
	# system("/usr/bin/sudo iptables .....")
}

$conn = DBI->connect("DBI:mysql:database=$db;host=$host",$user,$pass,{RaiseError => 1});

$query = $conn->prepare("UPDATE mail_user SET password=CONCAT('XXX ', password) WHERE email = \"$email\"");
$query->execute();
$query->finish();
$conn->disconnect();
