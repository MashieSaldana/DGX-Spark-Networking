# Asteria Fabric B — minimal RoCE QoS convergence (RouterOS 7.23+).
# Targeted delta, not a full export. Import only while the model is stopped.
#
# Brings Fabric B down to the same load-bearing settings Fabric A already
# runs, leaving the optional tuning at RouterOS defaults:
#   - profiles keep dscp/traffic-class; PCP marking returns to default 0
#     (irrelevant on these untagged ports)
#   - PFC pause/resume thresholds return to auto
#   - ports trust L3 DSCP but preserve the original DSCP on egress
#
# The six things that must stay explicit are untouched: bridge membership,
# l2mtu=9014, qos-hw-offloading=yes on switch1, both DSCP/traffic-class
# profiles, pfc-tc3, and pfc/egress-rate-queue3 on the four active ports.

/interface ethernet switch qos profile
set [find where name="roce-lossless"] pcp=0
set [find where name="cnp"] pcp=0

/interface ethernet switch qos priority-flow-control
set [find where name="pfc-tc3"] pause-threshold=auto resume-threshold=auto

/interface ethernet switch qos port
set qsfp28-1-1 trust-l3=keep
set qsfp28-2-1 trust-l3=keep
set qsfp28-3-1 trust-l3=keep
set qsfp28-4-1 trust-l3=keep