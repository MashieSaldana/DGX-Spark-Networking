# Asteria Fabric A — CRS504-4XQ (serial HK80AWF1R39) — reconstructed 2026-09-30
# via RouterOS API reads (not /export), networking sections only.
# Differences vs Fabric B: data-port L3 mtu 1584 (l2mtu 9014; L3 mtu is
# irrelevant on this pure-L2 bridge), trust-l3=keep, pcp=0, PFC thresholds
# auto (defaults). B is the recommended canonical config (explicit DSCP/
# PCP classes + 9000 mtu + 90/70 thresholds); A is functionally equivalent.
# RouterOS 7.24.4 (stable), board fw 7.24.4
/interface bridge
add admin-mac=04:F4:1C:9F:C1:B2 auto-mac=no comment=defconf name=bridge
add name=bridge-roce
/interface ethernet
set [ find default-name=qsfp28-1-1 ] l2mtu=9014
set [ find default-name=qsfp28-2-1 ] l2mtu=9014
set [ find default-name=qsfp28-3-1 ] l2mtu=9014
set [ find default-name=qsfp28-4-1 ] l2mtu=9014
/interface ethernet switch qos priority-flow-control
add name=pfc-tc3 traffic-class=3 rx=yes tx=yes
/interface ethernet switch qos port
set qsfp28-1-1 egress-rate-queue3=100.0Gbps pfc=pfc-tc3 trust-l3=keep
set qsfp28-2-1 egress-rate-queue3=100.0Gbps pfc=pfc-tc3 trust-l3=keep
set qsfp28-3-1 egress-rate-queue3=100.0Gbps pfc=pfc-tc3 trust-l3=keep
set qsfp28-4-1 egress-rate-queue3=100.0Gbps pfc=pfc-tc3 trust-l3=keep
/interface ethernet switch qos profile
add dscp=26 name=roce pcp=0 traffic-class=3
add dscp=48 name=cnp pcp=0 traffic-class=6
/interface list
add name=WAN
add name=LAN
/interface bridge port
add bridge=bridge comment=defconf interface=ether1
add bridge=bridge-roce comment=roce interface=qsfp28-1-1
add bridge=bridge-roce comment=roce interface=qsfp28-2-1
add bridge=bridge-roce comment=roce interface=qsfp28-3-1
add bridge=bridge-roce comment=roce interface=qsfp28-4-1
/interface ethernet switch
set switch1 qos-hw-offloading=yes
/interface ethernet switch qos map ip
add dscp=26 profile=roce
add dscp=48 profile=cnp
/ip address
add address=192.168.1.9/24 comment=defconf interface=bridge network=192.168.1.0
/ip service
set ftp disabled=yes
set telnet disabled=yes
