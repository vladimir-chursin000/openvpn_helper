#!/usr/bin/bash

SYSCTL_CONF_GREP=`grep net.ipv4.ip_forward /etc/sysctl.conf | wc -l`;

if [ "$SYSCTL_CONF_GREP" -eq "1" ]; then
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf;
    echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf;
elif [ "$SYSCTL_CONF_GREP" -ne "1" ]; then
    echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf;
fi;

sysctl -p;