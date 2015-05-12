#!/usr/bin/perl
use strict;
use warnings;
use Net::SIP;
use Time::HiRes qw( time );

my $current = `date +"%m-%d-%Y %T"`;
my $registrar = "Your SIP Server IP Address";
my $username = "User Name";
my $password = "Passsword";
my $status;
my $message;
my $value;

my $nmap = `/usr/bin/nmap -T5 -P0 -sU -p5060 $registrar`;
chomp($nmap);
if(index($nmap,"open|filtered") == -1) {
  $value = 0;
  $status = 1;
  $message = "Closed";
} else {
  $value = 1;
  $status = 0;
  $message = "Open";
}

print "$status SIP_Service status=$value; Server is $registrar, SIP Service is $message, $current";

my $ua = Net::SIP::Simple->new(
registrar => $registrar,
domain => $registrar,
from => $username,
auth => [ $username,$password ],

);

my $start = time();

# Register agent
if($ua->register( expires => 1800 )) {
  my $end = time();
  $value = sprintf("%.2f",$end - $start);
  $status = 0;
  $message = "UP";
}else {
  $value = 0;
  $status = 2;
  $message = "DOWN";
}

print "$status SIP_Register response=$value; Server is $registrar, $value s, $current\n";
