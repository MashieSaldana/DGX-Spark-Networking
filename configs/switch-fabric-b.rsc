# 2026-09-24 13:32:13 by RouterOS 7.24.4
# software id = J87S-AHVQ
#
# model = CRS504-4XQ
/interface bridge
add admin-mac=xx:xx:xx:xx:xx:xx auto-mac=no comment=defconf name=bridge
add name=bridge-roce
/interface ethernet
set [ find default-name=qsfp28-1-1 ] l2mtu=9014 mtu=9000
set [ find default-name=qsfp28-1-3 ] advertise="10M-baseT-half,10M-baseT-full,\
    100M-baseT-half,100M-baseT-full,1G-baseT-half,1G-baseT-full,1G-baseX,2.5G-\
    baseT,2.5G-baseX,5G-baseT,10G-baseT,10G-baseSR-LR,10G-baseCR,40G-baseSR4-L\
    R4,40G-baseCR4,25G-baseSR-LR,25G-baseCR,50G-baseSR2-LR2,50G-baseCR2"
set [ find default-name=qsfp28-2-1 ] l2mtu=9014 mtu=9000
set [ find default-name=qsfp28-2-3 ] advertise="10M-baseT-half,10M-baseT-full,\
    100M-baseT-half,100M-baseT-full,1G-baseT-half,1G-baseT-full,1G-baseX,2.5G-\
    baseT,2.5G-baseX,5G-baseT,10G-baseT,10G-baseSR-LR,10G-baseCR,40G-baseSR4-L\
    R4,40G-baseCR4,25G-baseSR-LR,25G-baseCR,50G-baseSR2-LR2,50G-baseCR2"
set [ find default-name=qsfp28-3-1 ] l2mtu=9014 mtu=9000
set [ find default-name=qsfp28-3-3 ] advertise="10M-baseT-half,10M-baseT-full,\
    100M-baseT-half,100M-baseT-full,1G-baseT-half,1G-baseT-full,1G-baseX,2.5G-\
    baseT,2.5G-baseX,5G-baseT,10G-baseT,10G-baseSR-LR,10G-baseCR,40G-baseSR4-L\
    R4,40G-baseCR4,25G-baseSR-LR,25G-baseCR,50G-baseSR2-LR2,50G-baseCR2"
set [ find default-name=qsfp28-4-1 ] l2mtu=9014 mtu=9000
set [ find default-name=qsfp28-4-3 ] advertise="10M-baseT-half,10M-baseT-full,\
    100M-baseT-half,100M-baseT-full,1G-baseT-half,1G-baseT-full,1G-baseX,2.5G-\
    baseT,2.5G-baseX,5G-baseT,10G-baseT,10G-baseSR-LR,10G-baseCR,40G-baseSR4-L\
    R4,40G-baseCR4,25G-baseSR-LR,25G-baseCR,50G-baseSR2-LR2,50G-baseCR2"
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
add dscp=26 profile=roce-lossless
add dscp=48 profile=cnp
/interface l2tp-server server
set use-ipsec=yes
/interface list member
add interface=ether1 list=WAN
add interface=qsfp28-1-1 list=LAN
add interface=qsfp28-1-2 list=LAN
add interface=qsfp28-1-3 list=LAN
add interface=qsfp28-1-4 list=LAN
add interface=qsfp28-2-1 list=LAN
add interface=qsfp28-2-2 list=LAN
add interface=qsfp28-2-3 list=LAN
add interface=qsfp28-2-4 list=LAN
add interface=qsfp28-3-1 list=LAN
add interface=qsfp28-3-2 list=LAN
add interface=qsfp28-3-3 list=LAN
add interface=qsfp28-3-4 list=LAN
add interface=qsfp28-4-1 list=LAN
add interface=qsfp28-4-2 list=LAN
add interface=qsfp28-4-3 list=LAN
add interface=qsfp28-4-4 list=LAN
/ip address
add address=192.168.1.10/24 comment=defconf interface=bridge network=\
    192.168.1.0
/ip dns
set servers=8.8.8.8,8.8.4.4
/ip hotspot profile
set [ find default=yes ] html-directory=hotspot
/ip ipsec profile
set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip service
set ftp disabled=yes
set telnet disabled=yes
/ppp profile
set *FFFFFFFE local-address=192.168.89.1 remote-address=*1
/system clock
set time-zone-name=Europe/London
/system routerboard settings
set enter-setup-on=delete-key
