#!/usr/bin/env bash
set -u
IFS_LIST=(enp1s0f0np0 enp1s0f1np1 enP2p1s0f0np0 enP2p1s0f1np1)
for IF in "${IFS_LIST[@]}"; do
  [ -e "/sys/class/net/$IF" ] || continue
  mlnx_qos -i "$IF" --trust dscp          2>/dev/null || true
  mlnx_qos -i "$IF" --pfc 0,0,0,1,0,0,0,0 2>/dev/null || true
  mlnx_qos -i "$IF" --dscp2prio set,26,3  2>/dev/null || true
done
exit 0
