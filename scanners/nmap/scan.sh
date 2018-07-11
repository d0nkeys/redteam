#!/usr/bin/env bash

for ip in "$@"
do
  echo "Creating $ip directory"

  mkdir -p $ip

  echo "Starting TCP Scan for $ip"

  nmap -A -p- --reason -T4 -sS --script=safe,vuln -oA $ip/$ip.tcp $ip &

  echo "Starting UDP Scan for $ip"

  nmap -sU -sV -T4 --top-ports 100 --script=safe,vuln -oA $ip/$ip.udp $ip &
done

wait

echo "Done!"
