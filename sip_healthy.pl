#!/usr/bin/perl
use strict;
use warnings;
use Net::SIP;

my $current = `date +"%m-%d-%Y %T"`;
my $registrar = "Your SIP Server IP Address";
my $username = "User Name";
my $password = "Passsword";
my $status;
my $message;

my $nmap = `/usr/bin/nmap -T5 -P0 -sU -p5060 $registrar`;
chomp($nmap);
if(index($nmap,"open|filtered") == -1) {
  $status = 1;
  $message = "Closed";
} else {
  $status = 0;
  $message = "Open";
}

print "$status SIP_Service status=$status; Server is $registrar, SIP Service is $message, $current";

my $ua = Net::SIP::Simple->new(
registrar => $registrar,
domain => $registrar,
from => $username,
auth => [ $username,$password ],

);

# Register agent
if($ua->register( expires => 1800 )) {
  $status = 0;
  $message = "UP";
}else {
  $status = 2;
  $message = "DOWN";
}

print "$status SIP_Register status=$status; Server is $registrar, $current\n";
