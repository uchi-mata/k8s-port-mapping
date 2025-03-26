#!/bin/bash

tmpports=$(mktemp)
gsed="sed"


for pid in /proc/*; do
  if [[ -d "$pid" && "$(basename "$pid")" =~ ^[0-9]+ && -r "$pid"/ns/net ]]; then
    nsenter --net="$pid/ns/net" ss -H -tulpn >> $tmpports
  fi
done


listening_ports=$(cat $tmpports |sort|uniq| awk '{print $1","$5","$7}')
rm $tmpports

pods=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace},{.metadata.name},{.status.containerStatuses[0].containerID}{"\n"}{end}' | sed 's/docker:\/\///' | sed 's/containerd:\/\///')

declare -A containerid_mapping


while read -r line
do
  namespace=$(echo "$line"|cut -d ',' -f 1)
  pod=$(echo "$line"|cut -d ',' -f 2)
  containers=$(kubectl get pod -n "$namespace" "$pod" -o jsonpath='{range .status.containerStatuses[*]}{.name},{.image},{.containerID}{"\n"}{end}' | sed 's/docker:\/\///' | sed 's/containerd:\/\///')
  hostnetwork=$(kubectl get pod -n "$namespace" "$pod" -o jsonpath='{.spec.hostNetwork}')
  if [[ -z "$hostnetwork" ]]; then
    hostnetwork="false"
  fi
  while read -r line2
  do
    container=$(echo "$line2"|cut -d ',' -f 1)
    containerimage=$(echo "$line2"|cut -d ',' -f 2)
    containerid=$(echo "$line2"|cut -d ',' -f 3)
    containerid_mapping["$containerid"]="$namespace,$pod,$container,$containerimage,$hostnetwork"
  done <<< "$containers"
done <<< "$pods"

while read -r line
do
  echo "$line" | grep '127.' > /dev/null && continue

  protocol=$(echo "$line"|cut -d ',' -f 1)
  port=$(echo "$line" | $gsed -n 's/.*:\([0-9]\+\),.*/\1/p')
  column=$(echo "$line" | cut -d '(' -f 3)
  pname=$(echo "$column" | cut -d '"' -f 2)
  pid=$(echo "$column" | cut -d '=' -f 2 | cut -d ',' -f 1)
  containerid=$(sed -n 's/.*cri-containerd-\([^.]*\)\.scope.*/\1/p' "/proc/$pid/cgroup" | head -n 1)
  if [[ -n "$containerid" ]]; then
    echo -ne "$protocol, $port, $pname, $pid, $containerid, ${containerid_mapping[$containerid]}\n"
  fi
done <<< "$listening_ports"
