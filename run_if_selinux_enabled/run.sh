#!/usr/bin/bash

SELF_DIR=`pwd -P`;

dnf -y install selinux-policy;

/usr/bin/checkmodule -M -m -o $SELF_DIR/ovpn_mod0.mod $SELF_DIR/ovpn_mod0.te;

/usr/bin/semodule_package -o $SELF_DIR/ovpn_mod0.pp -m $SELF_DIR/ovpn_mod0.mod;

/usr/sbin/semodule -i $SELF_DIR/ovpn_mod0.pp;

rm $SELF_DIR/ovpn_mod0.pp;
rm $SELF_DIR/ovpn_mod0.mod;
