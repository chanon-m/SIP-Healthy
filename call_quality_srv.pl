#!/usr/bin/perl -w
#call_quality_srv.pl

use strict;
use Net::RTP;
use Net::Address::IP::Local;
use Time::HiRes qw(usleep);

my ($ipaddr, $port);

usage();
server();

sub server {

        my $rtp = new Net::RTP(
                               LocalPort=>$port,
                               LocalAddr=>$ipaddr
                      ) || die "Failed to create RTP socket: $!";
        my %jitter = (
            R    => [ 0, 0 ],
            S    => [ 0, 0 ],
            J    => [ 0, 0 ],
            SEQ  => [ 0, 0 ],
            D    =>   0,
        );
        my ($latency,$pkt_loss,$avejitter,$count) = (0,0,0,0);

        #Listen RTP packets
        while(my $rtp_packet = $rtp->recv()) {

            if(!$rtp_packet->marker()) {
                #The RTP timestamp from packet i
                ($jitter{S}[0],$jitter{S}[1]) = ($jitter{S}[1],$rtp_packet->timestamp());
                $jitter{S}[0] = $rtp_packet->timestamp() if($jitter{S}[0] == 0);

                #The time of arrival in RTP timestamp units from packet i
                ($jitter{R}[0],$jitter{R}[1]) = ($jitter{R}[1],time());
                $jitter{R}[0] = $jitter{R}[1] if($jitter{R}[0] == 0);

                ($jitter{SEQ}[0],$jitter{SEQ}[1]) = ($jitter{SEQ}[1],$rtp_packet->seq_num());
                if($jitter{SEQ}[1] == 1) { #initial variable at first rtp packet
                    ($jitter{SEQ}[0],$jitter{J}[0],$jitter{D}) = (0,0,0);
                } else {
                    #Calculate the difference of relative transit times for the two packets
                    $jitter{D} = abs($jitter{R}[1] - ($jitter{R}[0] + ($jitter{S}[1] - $jitter{S}[0])))/1000;
                }

                my $diff_SEQ = $jitter{SEQ}[1] - $jitter{SEQ}[0];
                if($diff_SEQ == 1) {
                    #Calculate jitter with timestamp
                    $jitter{J}[1] = $jitter{J}[0] + (($jitter{D} - $jitter{J}[0])/16);
                } else {
                    $jitter{J}[1] = 0;
                    $diff_SEQ = abs($diff_SEQ) - 1 if(abs($diff_SEQ) > 0);
                    $pkt_loss += $diff_SEQ if($jitter{SEQ}[0] != 0);
                }

                $jitter{J}[0] =  $jitter{J}[1];

                $avejitter += $jitter{J}[1];
                $latency += ($jitter{R}[1] - $jitter{R}[0]);
                $count++;
            } else {
                $latency = ($latency/$count) - 0.02;
                $latency = 0 if($latency < 0);
                $avejitter /= $count;

                #Calculate R-value
                my $R = Rvalue($latency,$pkt_loss,$avejitter,$count);

                #Convert R-value to MOS
                my $MOS = R2MOS($R);

                Call_Quality_report($MOS,$R,$latency,$pkt_loss,$avejitter,$rtp_packet->source_ip());

                ($latency,$pkt_loss,$avejitter,$count) = (0,0,0,0);
                ($jitter{R}[0],$jitter{R}[1]) = (0,0);

            }
      }

}

sub Rvalue {
        my ($latency,$pkt_loss,$avejitter,$count) = ($_[0],$_[1],$_[2],$_[3]);

        my $R = 93; #R-value of G711

        # Latency effect. deduct 5 for a delay of 150 ms, 20 for a delay of 240 ms, 30 for a delay of 360 ms.
        if($latency < 150) {
            $R = $R - ($latency / 30);
        } else {
            $R = $R - ($latency / 12);
        }

        # Deduct 7.5 R-value per Packet Loss.
        $R -= 7.5 * $pkt_loss;
        # Deduct R-value with Jitter
        $R -= $avejitter;

        return $R;
}

sub R2MOS {
         my $R = $_[0];
         my ($Rmax,$Rmin,$MOSmax,$MOSmin) = (100,90,5,4.2);

        ($Rmax,$Rmin,$MOSmax,$MOSmin) = (90,80,4.3,3.9) if($R > 80 && $R <= 90);
        ($Rmax,$Rmin,$MOSmax,$MOSmin) = (80,70,4.0,3.5) if($R > 70 && $R <= 80);
        ($Rmax,$Rmin,$MOSmax,$MOSmin) = (70,60,3.6,3.0) if($R > 60 && $R <= 70);
        ($Rmax,$Rmin,$MOSmax,$MOSmin) = (60,50,3.1,2.5) if($R > 50 && $R <= 60);
        ($Rmax,$Rmin,$MOSmax,$MOSmin) = (50,0,2.6,0.9) if($R <= 50);

        my $MOS = ((($R - $Rmin) * ($MOSmax - $MOSmin)) / ($Rmax - $Rmin)) + $MOSmin;

        return $MOS;
}

sub Call_Quality_report {
        my @report = @_;

        my $port2 = $port + 1;

        my $rtp = new Net::RTP(
                               PeerPort=>$port2,
                               PeerAddr=>$report[5]
                      ) || die "Failed to create RTP socket: $!";

        usleep(200000);

        #data format is MOS Latency Packet_Loss Jitter
        my $data = sprintf("%.1f ", $report[0]);
          $data .= sprintf("%.2fms ", $report[2]);
          $data .= sprintf("%u ", $report[3]);
          $data .= sprintf("%.4f", $report[4]);

        #Create RTP packet
        my $packet = new Net::RTP::Packet();
        $packet->payload($data);
        my $sent = $rtp->send($packet); #Send report

}

sub usage {

        if((scalar (@ARGV) == 2)) {
            ($ipaddr, $port) = @ARGV;
        } else {
            print "usage:   call_quality_srv.pl [IP Address] [port]\n";
            print "example: call_quality_srv.pl 192.168.1.100 7880\n";
            exit;
        }

}
