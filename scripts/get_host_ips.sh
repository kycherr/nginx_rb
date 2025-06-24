#!/bin/bash
set -e
IPS=$(ip -4 -o addr show | awk '$2 != "lo" {print $4}' | cut -d/ -f1)

arr=()
for ip in $IPS; do
  arr+=("$ip")
done

json="["
for i in "${!arr[@]}"; do
  ip="${arr[$i]}"
  json+="\\\"$ip\\\""
  if [[ $i -lt $((${#arr[@]} - 1)) ]]; then
    json+=","
  fi
done
json+="]"

echo "{\"external_ips\": \"$json\"}"
