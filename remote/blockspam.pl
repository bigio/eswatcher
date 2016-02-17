#!/usr/bin/perl

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

die "Script should not run as root, use sudo instead\n" if ( $< == 0 );

if ( $^O eq "openbsd" ) {
	system("/usr/local/bin/sudo /sbin/pfctl -k $ip");
}

$conn = DBI->connect("DBI:mysql:database=$db;host=$host",$user,$pass,{RaiseError => 1});

$query = $conn->prepare("UPDATE mail_user SET password=CONCAT('XXX ', password) WHERE email = \"$email\"");
$query->execute();
$query->finish();
$conn->disconnect();
