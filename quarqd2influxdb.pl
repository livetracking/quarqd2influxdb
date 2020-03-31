#!/usr/bin/perl

# quarqd2influxdb.pl
# Author: Nils Knieling - https://github.com/livetracking/quarqd2influxdb
#
# Store real-time quarqd data into InfluxDB
#
# quarqd source and doku: https://github.com/Cyclenerd/quarqd
# HTTP API doku:          https://livetracking.nkn-it.de/
# 

use strict;
use LWP::UserAgent;
use URI;
use Getopt::Std;
use Time::HiRes qw( time );


################################################################################
#### Configuration Section
################################################################################

# InfluxDB Hostname
my $host = 'your-domain.local'

# ANT+ device IDs:
my $heartrate  = "62061";
my $powermeter = "30429";
my $cadence    = "24186";

################################################################################
#### END Configuration Section
################################################################################


# Get options (username and password)
my %options=();
getopts("u:p:", \%options);
my $username = $options{u};
my $password = $options{p};

# Check username
unless ( $username =~ /^[A-Z\d_]{4,20}$/i ) {
	die "Username (-u) missing!\n";
}
# Check password
unless ( $password =~ /^[^\'\;\"]{8,100}$/ ) {
	die "Password (-p) missing!\n";
}

# Build HTTP client
my $lwp = LWP::UserAgent->new();
$lwp-> agent("quarqd-2-influxdb/1"); # User agent
$lwp->timeout(1); # 1s timeout
$lwp->credentials( $host.':443', 'Protected', $username, $password); # HTTP basic auth

# Build URI
# https://livetracking.nkn-it.de/Writing-Data.html
my $uri = URI->new();
$uri->scheme('https');
$uri->host($host);
$uri->path('write');
$uri->query_form(db => $username, precision => 'u');

# Print info
print "Waiting for data from quarqd...\n";
print "Quit with [Crtl] + [C]\n";
print "-"x70 . "\n";

# Temp stores
my %hr  = ();
my %pwr = ();
my %cad = ();
my $last_time = 0;

# Get quarqd data
while (<>) {
	my ($time) = time; # time in usec
	$time = sprintf "%16d", $time*1000000;
	unless ($last_time > 1) {
		$last_time = $time;
	}
	# Heart rate
	if ( $_ =~ /HeartRate\sid='(.*h').*BPM='(\d{1,3})'/ ) {
		if ($heartrate = $1) {
			$hr{$time} = $2;		
		}		
		
	}
	# Power
	if ( $_ =~ /Power\sid='(.*p').*watts='(\d{1,4}\.\d{1,2})'/ ) {
		if ($powermeter = $1) {
			$pwr{$time} = $2;		
		}		
	}
	# Cadence
	if ( $_ =~ /Cadence\sid='(.*c').*RPM='(\d{1,4})'/ || $_ =~ /Cadence\sid='(.*c').*RPM='(\d{1,4}\.\d{1,2})'/ ) {
		if ($cadence = $1) {
			$cad{$time} = $2;	
		}
	}
	# Send every 3sec data to InfluxDB
	if (($time - $last_time) > 3000000) {
		# Create InfluxDB line protocol
		# samples hr_bpm=123 time
		my @measurements = ();
		foreach my $usec (keys %hr) {
			my $bpm = $hr{$usec};
			push(@measurements, "samples hr_bpm=$bpm $usec");
		}
		foreach my $usec (keys %pwr) {
			my $watt = $pwr{$usec};
			push(@measurements, "samples pwr_w=$watt $usec");
		}
		foreach my $usec (keys %cad) {
			my $rpm = $cad{$usec};
			push(@measurements, "samples cad_rpm=$rpm $usec");
		}
		my $measurement = join("\n", @measurements); # Join measurements
		# Write to InfluxDB
		my $response = $lwp->post($uri, Content => $measurement);
		# Check response
		if ($response->code() >= 500) {
			warn "Server error!\n";
		} elsif ($response->code() > 400) {
			die "Unauthorized! Check username and password.\n";
		} elsif ($response->code() == 204) {
			print "\n$measurement\n";
		} else {
			my $error = $response->message();
			my $content = $response->content();
			warn "$error\n";
			print "$content\n";
		}
		# Save last time
		$last_time = $time;
		# Reset temp stores
		%hr  = ();
		%pwr = ();
		%cad = ();	
	}
}
