#!/usr/bin/env bash

# apt install libnotify-bin parallel

if [ ! $# -eq 1 ]
  then
    echo "usage: bash scan.parallel.sh <ips.txt>"
	exit 1
fi

echo "Starting TCP Scan"

parallel --ungroup -a $@ --max-args 1 'echo TCP: Job {#} of {= $_=total_jobs() =} - {} && mkdir -v -p scans/{} && notify-send "scan.parallel.sh" "beginning TCP - {#} / {= $_=total_jobs() =} - {}" && nmap -A -p- --reason -T4 -sT --script "(default or safe or vuln or discovery) and not broadcast" -oA scans/{}.tcp {}' &

echo "Starting UDP Scan (top 50 ports)"

parallel --ungroup -a $@ --max-args 1 'echo UDP: Job {#} of {= $_=total_jobs() =} - {} && notify-send "scan.parallel.sh" "beginning UDP - {#} / {= $_=total_jobs() =} - {}" && nmap -sU -sV -T4 --top-ports 50 -oA scans/{}.udp {}' &

wait

echo "Done!"
