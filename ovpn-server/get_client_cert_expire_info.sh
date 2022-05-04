#!/usr/bin/bash

SELF_DIR=`pwd -P`;

for cert in $SELF_DIR/pki_root/pki/issued/*.crt
do
    echo "Certificate: ${cert}";
    EXE_RES=`grep -i "not after" ${cert}`;
    echo "$EXE_RES";
done


