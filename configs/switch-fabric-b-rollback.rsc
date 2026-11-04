# Asteria Fabric B — rollback of the minimal QoS convergence.
# Restores the pre-minify explicit settings. Import only with the model stopped.

/interface ethernet switch qos profile
set [find where name="roce-lossless"] pcp=3
set [find where name="cnp"] pcp=6

/interface ethernet switch qos priority-flow-control
set [find where name="pfc-tc3"] pause-threshold=90% resume-threshold=70%

/interface ethernet switch qos port
set qsfp28-1-1 trust-l3=trust
set qsfp28-2-1 trust-l3=trust
set qsfp28-3-1 trust-l3=trust
set qsfp28-4-1 trust-l3=trust