#!/usr/bin/perl
use strict;
use warnings;

use Net::Netmask;
use Net::IP;

# apt-get install -y libnet-netmask-perl
#
# Script for converting bgpdump output to prefix/asn list
# Author: pavel.odintsov@gmail.com
#
#
# Input rows format:
# TIME: 12/19/11 08:00:01
# TYPE: TABLE_DUMP_V2/IPV4_UNICAST
# PREFIX: 46.4.0.0/16
# SEQUENCE: 23998
# FROM: 80.91.255.62 AS1299
# ORIGINATED: 12/08/11 05:45:51
# ORIGIN: IGP
# ASPATH: 1299 13237 24940 24940 24940 24940 24940
# NEXT_HOP: 80.91.255.62
# AGGREGATOR: AS24940 213.133.96.18
#
my %prefix = ();
my $prev_prefix = '';
my $prev_as = '';
while(<>) {
    if (/^PREFIX:\s+(.*?)$/)  {
        $prev_prefix = $1;
    } 
    if (/^ASPATH:\s(.*?)$/) {
        my @as_path = split /\s+/, $1;
        # last element is originating AS
        $prev_as = $as_path[-1];
    }
    # blank string at the end of block
    if (/^\s+$/) {
        # use hash for de-duplication
        unless ($prefix{$prev_prefix}) {
            $prefix{$prev_prefix} = 1;
            my $block = new Net::Netmask($prev_prefix);
            # "1.0.0.0","1.0.0.255","16777216","16777471","AU","Australia"
            print '"'. $block->first() . '",';
            print '"'. $block->last() . '",';
            my $first = new Net::IP ($block->first()) or die "Can't first IP";
            my $last = new Net::IP ($block->last()) or die "Can't last IP";
            print '"'. $first->intip() . '",';
            print '"'. $last->intip() . '",';          
            print '"' . $prev_as . '",';
            print '"' . $prev_as . '"';
            print "\n";
        }
    }
}

