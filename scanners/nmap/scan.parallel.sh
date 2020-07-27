#!/usr/bin/env bash

apt install libnotify-bin parallel

mkdir -p scans

if [ $# -eq 0 ]
  then
    echo "usage: bash scan.parallel.sh <ips.txt> [#jobs]"
        exit 1
fi

TARGETS=$1
JOBS=${2:-""}

echo "Starting TCP Scan with $JOBS jobs"

parallel -j$JOBS --ungroup --bar -a $TARGETS --max-args 1 'echo TCP: Job {#} of {= $_=total_jobs() =} - {} && echo "scan.parallel.sh" "beginning TCP - {#} / {= $_=total_jobs() =} - {}" && nmap -A -p- -v --reason -T5 -sS --script "(default or safe or vuln or discovery) and not broadcast" -oA scans/{}.tcp {}' # &

echo "Starting UDP Scan with $JOBS jobs (top 50 ports)"

parallel -j$JOBS --ungroup -a $TARGETS --max-args 1 'echo UDP: Job {#} of {= $_=total_jobs() =} - {} && echo "scan.parallel.sh" "beginning UDP - {#} / {= $_=total_jobs() =} - {}" && nmap -sU -sV -T4 --top-ports 50 -oA scans/{}.udp {}' &

wait

echo "Done!"
