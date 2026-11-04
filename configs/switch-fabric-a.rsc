# Asteria Fabric A — CRS504-4XQ — reconstructed 2026-09-30
# via RouterOS API reads (not /export), networking sections only.
# Current state (2026-11-04): minimal RoCE QoS, matching Fabric B —
# trust-l3=keep, pcp=0, PFC thresholds auto, ports mtu=9000 l2mtu=9014.
# Fabric B keeps its original profile names (roce-lossless/cnp); A uses roce/cnp.
# RouterOS 7.25.1 (stable), board fw 7.25.1
/interface bridge
add admin-mac=xx:xx:xx:xx:xx:xx auto-mac=no comment=defconf name=bridge
add name=bridge-roce
/interface ethernet
set [ find default-name=qsfp28-1-1 ] l2mtu=9014 mtu=9000
set [ find default-name=qsfp28-2-1 ] l2mtu=9014 mtu=9000
set [ find default-name=qsfp28-3-1 ] l2mtu=9014 mtu=9000
set [ find default-name=qsfp28-4-1 ] l2mtu=9014 mtu=9000
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
