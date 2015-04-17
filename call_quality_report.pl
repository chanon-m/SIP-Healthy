#!/usr/bin/perl -w
#call_quality_report.pl

use strict;
use Net::RTP;
use Net::Address::IP::Local;
use Time::HiRes qw(usleep);

my ($ipaddr, $port) = ("Server_IP","Server_Port");
my $count = 50; #Send x RTP packets

client();

sub client {

        my $rtp = new Net::RTP(
                               PeerPort=>$port,
                               PeerAddr=>$ipaddr,
                      ) || die "Failed to create RTP socket: $!";

        #Create RTP packet
        my $packet = new Net::RTP::Packet();
        $packet->payload_type(0); #payload type is u-law

        #G711 codec and 20ms sample period
        my @data = 0 x 160; #G711 payload is 160 byte, dummy payload

        $packet->payload(@data);
        $packet->seq_num(0); #start seq number

        while($count) {
                $packet->seq_num_increment();
                #G711 sample rate 8KHz, sec = timestamp % rate = 177
                $packet->timestamp_increment(177);
                my $sent = $rtp->send($packet); #Send RTP packet

                #send RTP packet every 20ms
                usleep(20000);
                $count--;
        }

        $packet->marker(1);
        $rtp->send($packet);

        my $local_ip = Net::Address::IP::Local->public;
        Received_report($local_ip,$port);
}

sub Received_report {
        my ($r_ipaddr,$r_port) = ($_[0], $_[1]+1);
        my $rtp = new Net::RTP(
                               LocalPort=>$r_port,
                               LocalAddr=>$r_ipaddr
                      ) || die "Failed to create RTP socket: $!";

        my $rtp_packet = $rtp->recv();
        my $data = $rtp_packet->payload();
        my $host = $rtp_packet->source_ip();
        my $datetime = `date +"%m-%d-%Y %T"`;

        my @report = split / /, $data;
        print "0 Call_Quality_$host MOS=$report[0] Server is $host $datetime";
        print "0 Call_Quality_$host Latency=$report[1] Server is $host $datetime";
        print "0 Call_Quality_$host Packet_Loss=$report[2] Server is $host $datetime";
        print "0 Call_Quality_$host Jitter=$report[3] Server is $host $datetime";

}
