# Asteria — 4× DGX Spark 100G RoCE Fabric (as-built)

Complete, verified configuration of the "Asteria" cluster: four NVIDIA DGX
Spark hosts (GB10) connected through MikroTik CRS504-4XQ switches for
lossless 100G RoCEv2 RDMA.

Scope: switch settings + host settings + validation. Everything below was
taken from the live devices on 2026-09-30, not from memory.

---

## 1. Topology

```
                  Ubiquiti LAN 192.168.1.0/24 (mgmt)
                           │ ether1 (bridge, mgmt IP .10)
                    ┌──────┴──────┐
                    │ CRS504-4XQ  │  "Asteria Fabric B" (serial HGZ0AEFTV0M)
                    │ RouterOS 7  │  bridge-roce = qsfp28-1-1 .. qsfp28-4-1
                    │ 98DX4310    │  L2MTU 9014, QoS hw-offload, lossless
                    └───┬───┬───┬───┘
              qsfp28-1   │   │   │   qsfp28-4
                   ┌─────┘   │   └─────┐
                metis     pallas   vesta   ceres
              192.168.10.5  .4      .3      .2
              enP2p1s0f1np1 enP2p1s0f1np1 enP2p1s0f1np1 enP2p1s0f1np1   (10.0.1.x)
              + each node's enp1s0f0np0 (10.0.0.x) on a second fabric
```

Each DGX Spark has TWO ConnectX-7 100G ports wired (one per PCIe root
complex), giving 2×100G per node of dual-fabric capacity. The Primary
fabric (this document's focus) is the CRS504 switch "Asteria Fabric B".

Note: our nodes' second CX7 link (enp1s0f0np0, 10.0.0.x) is also up at
100G — on this site it connects to a second CRS504 ("Fabric A", mgmt
192.168.1.9) over which we no longer hold credentials. For a single-switch
build (the common case), skip the second link or leave it unconfigured;
the config below is complete for one switch.

## 2. Addressing plan

| host  | mgmt (default route) | fabric A link | fabric B link | CX7 netdev f0 (RC#1)  | CX7 netdev f1 (RC#2)    |
|-------|----------------------|---------------|---------------|-----------------------|-------------------------|
| ceres | 192.168.10.2/24      | 10.0.0.1/24   | 10.0.1.1/24   | enp1s0f0np0  (10.0.0.1)| enP2p1s0f1np1 (10.0.1.1)|
| vesta | 192.168.10.3/24      | 10.0.0.2/24   | 10.0.1.2/24   | enp1s0f0np0  (10.0.0.2)| enP2p1s0f1np1 (10.0.1.2)|
| pallas| 192.168.10.4/24      | 10.0.0.3/24   | 10.0.1.3/24   | enp1s0f0np0  (10.0.0.3)| enP2p1s0f1np1 (10.0.1.3)|
| metis | 192.168.10.5/24      | 10.0.0.4/24   | 10.0.1.4/24   | enp1s0f0np0  (10.0.0.4)| enP2p1s0f1np1 (10.0.1.4)|

Switch-side mapping on Fabric B (learned MACs → port):

| switch port | host  | node MAC on that port (f1)      |
|-------------|-------|---------------------------------|
| qsfp28-1-1  | metis | 4C:BB:47:7E:8C:54               |
| qsfp28-2-1  | pallas| 4C:BB:47:29:A9:0E               |
| qsfp28-3-1  | vesta | 4C:BB:47:81:75:38               |
| qsfp28-4-1  | ceres | 4C:BB:47:81:A8:05               |

All ports link at 100 Gbps, IB rate 100 Gb/s (4X EDR), state ACTIVE.
RoCE subnet via the CX7 ports only — no dedicated SM needed for this size
(switch is not IB-managed; hosts run opensm-free, default IB routing works
on a flat /24-sized mesh).

## 3. Switch configuration (MikroTik CRS504-4XQ, RouterOS 7.24.4)

Preamble: CRS504-4XQ is a 4×100G QSFP28 L2 switch with a Marvell Prestera
98DX4310 chip. Factory RouterOS defconf puts the mgmt IP on a DATA port
(qsfp28-1-1) — you WILL lose management when you move that port. Re-bind
mgmt IP to ether1/bridge (or a dedicated mgmt interface) FIRST.

The full export is in `configs/switch-fabric-b.rsc`; the essential parts:

### 3.1 Management bridge
```
/interface bridge
add admin-mac=F4:1E:57:2E:FC:61 auto-mac=no comment=defconf name=bridge
add name=bridge-roce
/interface bridge port            # ether1 in 'bridge'
add bridge=bridge comment=defconf interface=ether1
/ip address
add address=192.168.1.10/24 comment=defconf interface=bridge network=192.168.1.0
```
Mgmt IP lives on the bridge that contains ether1 — never on a QSFP28 data
port (see pitfalls).

### 3.2 RoCE bridge — all 4 data ports, L2MTU 9014
```
/interface ethernet
set [ find default-name=qsfp28-1-1 ] l2mtu=9014 mtu=9000
set [ find default-name=qsfp28-2-1 ] l2mtu=9014 mtu=9000
set [ find default-name=qsfp28-3-1 ] l2mtu=9014 mtu=9000
set [ find default-name=qsfp28-4-1 ] l2mtu=9014 mtu=9000
/interface bridge port
add bridge=bridge-roce comment=roce interface=qsfp28-1-1
add bridge=bridge-roce comment=roce interface=qsfp28-2-1
add bridge=bridge-roce comment=roce interface=qsfp28-3-1
add bridge=bridge-roce comment=roce interface=qsfp28-4-1
/interface ethernet switch
set switch1 qos-hw-offloading=yes
```
The CRS504-4XQ is single-chip; `switch1` covers all 4 data ports.
9000 MTU / 9014 L2MTU matches the hosts (Jumbo frames for IB/RoCE).

### 3.3 Lossless RoCEv2 QoS (PFC + DSCP maps)
```
/interface ethernet switch qos priority-flow-control
add name=pfc-tc3 pause-threshold=90% resume-threshold=70% rx=yes \
    traffic-class=3 tx=yes
/interface ethernet switch qos port
set qsfp28-1-1 egress-rate-queue3=100.0Gbps pfc=pfc-tc3 trust-l3=trust
set qsfp28-2-1 egress-rate-queue3=100.0Gbps pfc=pfc-tc3 trust-l3=trust
set qsfp28-3-1 egress-rate-queue3=100.0Gbps pfc=pfc-tc3 trust-l3=trust
set qsfp28-4-1 egress-rate-queue3=100.0Gbps pfc=pfc-tc3 trust-l3=trust
/interface ethernet switch qos profile
add dscp=26 name=roce-lossless pcp=3 traffic-class=3
add dscp=48 name=cnp pcp=6 traffic-class=6
/interface ethernet switch qos map ip
add dscp=26 profile=roce-lossless
add dscp=48 profile=cnp
```
i.e.:
- DSCP 26 (RoCEv2) → priority 3, traffic class 3, lossless (PFC enabled)
- DSCP 48 (CNP / congestion notification packets) → priority 6, TC 6
- PFC threshold 90%/70% so backpressure triggers before buffers overflow

### 3.4 Misc
```
/interface l2tp-server server set use-ipsec=yes   # (factory default, unused)
/ip service set ftp disabled=yes
/ip service set telnet disabled=yes
/system clock set time-zone-name=Europe/London
/system routerboard settings set enter-setup-on=delete-key
/system identity set name="Asteria Fabric B"      # ours; pick your own
```

### 3.5 Applying to a fresh unit
1. Reset to RouterOS (not SwOS), set admin password, enable SSH.
2. Copy `configs/switch-fabric-b.rsc`, edit the mgmt IP block to your LAN.
3. `ssh admin@<ip> "/import file-name=switch-fabric-b.rsc"` (scp the file
   to the unit first) — or paste via terminal. Avoid Winbox: MAC-based
   access is fine, but the file import is one shot.
4. Verify: `/interface ethernet monitor [find where name~"qsfp28-[1-4]-1"] once`
   → all link-ok at 100Gbps; `/interface bridge host print` → each port
   learned the right host MAC; `/interface ethernet switch qos port print`.

## 4. Host configuration (each of the 4 nodes, Ubuntu 24.04)

Files in `configs/`:
- netplan `40-cx7.yaml` (RoCE IPs + 9000 MTU, NetworkManager renderer)
- `/etc/NetworkManager/conf.d/99-roce-unused.conf` (unmanage the two CX7
  ports we don't use: enp1s0f1np1 + enP2p1s0f0np0)
- systemd unit `/etc/systemd/system/roce-qos.service`
- `/usr/local/sbin/roce-qos.sh` — mlnx_qos per-port: trust dscp, PFC
  prio3, DSCP26→prio3

### 4.1 netplan (per node, adapt IP)
```yaml
network:
  version: 2
  ethernets:
    enp1s0f0np0:
      dhcp4: no
      dhcp6: no
      link-local: []
      mtu: 9000
      addresses: [10.0.0.1/24]      # ceres; .2 vesta, .3 pallas, .4 metis
    enP2p1s0f1np1:
      dhcp4: no
      dhcp6: no
      link-local: []
      mtu: 9000
      addresses: [10.0.1.1/24]      # ceres; .2 vesta, .3 pallas, .4 metis
```

### 4.2 NetworkManager unmanaged devices
```ini
[keyfile]
unmanaged-devices=interface-name:enp1s0f1np1;interface-name:enP2p1s0f0np0
```
Both CX7 ports on the same PCI RC are enumerated twice: f0+f1 async.
We keep exactly one IP per physical cable: enp1s0f0np0 (cable A) and
enP2p1s0f1np1 (cable B). The other two per-cable ports (enp1s0f1np1 and
enP2p1s0f0np0) are removed from netplan AND marked unmanaged so
NetworkManager can't grab them or add link-local routes that fight the
fixed /24s.

### 4.3 roce-qos.service + mlnx_qos script
Make sure the CX7 ports come up lossless after every boot:
```ini
[Unit]
Description=Apply lossless RoCE QoS (PFC+DSCP) on DGX Spark RoCE interfaces
After=network.target
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/roce-qos.sh
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
```
script:
```bash
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
```
(systemd: `systemctl daemon-reload && systemctl enable --now roce-qos`)

This mirrors the switch: DSCP26→priority 3, PFC priority 3, trust DSCP.

## 5. Validation (numbers measured on this rig)

- All 4 switch ports link-ok, 100 Gbps; SFP vendors read back (Broadcom).
- Hosts: `ibstat` → both CX7 ports Active, `rate 100 Gb/sec (4X EDR)`.
- `ib_write_bw` single stream (64K msg, 15s): 98.01 Gb/s average across
  ceres↔vesta on the 10.0.1.x fabric (re-verified 2026-09-30).
- `netstat -s`-style / `ethtool -S` PFC counters increment on lossless
  class only when genuinely paused — watch these for drops: on switch
  `/interface ethernet switch qos port print` shows pfc rx/tx frames.

Commands:
```bash
# host side
ethtool enp1s0f0np0 | grep -E "Speed|Link detected"
ibstat   # hca_id mapping via /sys/class/net/<if>/device/infiniband
# one-liner pair test (server then client, e.g. ceres->vesta on 10.0.1.x):
ssh ceres 'setsid nohup ib_write_bw -d roceP2p1s0f1 --duration=25 --report_gbits \
  > /tmp/ib_server.log 2>&1 < /dev/null &' && \
ssh vesta 'ib_write_bw -d roceP2p1s0f1 --duration=15 --report_gbits 10.0.1.1'

# switch side
/interface ethernet monitor [find where name~"qsfp28-[1-4]-1"] once
/interface bridge host print
/interface ethernet switch qos port print
/interface ethernet switch qos priority-flow-control print
```

## 6. Pitfalls learned the hard way

1. **Mgmt IP on a data port = lockout.** Factory defconf binds the CRS504
   mgmt address to qsfp28-1-1. Detaching that port from its bridge drops
   mgmt entirely (recovery = power cycle + re-bind). Keep mgmt on
   ether1/bridge.
2. **L2MTU/switch-chip changes cause transient API timeouts** — config
   usually still lands. Change one port per connection and verify after.
3. **Plan for the two logical ifaces per cable.** Each 100G cable shows up
   as two CX7 netdevs (it's a dual-port NIC, not breakout): pick ONE per
   cable, unmanage the other, and note which is which (f0/f1 per RC).
4. **Re-seed SSH known_hosts after re-IP** or sparkrun's delegated
   model-dist fails "Host key verification failed".
5. Pallas driver drift (580.173.02 vs 580.178.04) — cosmetic; no impact
   on networking.

## 7. Files

- `configs/switch-fabric-b.rsc` — full RouterOS export, verbatim
- `configs/netplan-40-cx7.yaml` — netplan snippet (ceres addresses)
- `configs/99-roce-unused.conf` — NetworkManager unmanaged list
- `configs/roce-qos.service` / `configs/roce-qos.sh` — QoS systemd unit+script

All host configs are byte-identical across the 4 nodes except the /24
address octet.
