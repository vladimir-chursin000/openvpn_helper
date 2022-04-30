#!/usr/bin/bash

#run as root

SELF_DIR=`pwd -P`;

$SELF_DIR/main.sh "gen_crl_and_restart_ovpn";
