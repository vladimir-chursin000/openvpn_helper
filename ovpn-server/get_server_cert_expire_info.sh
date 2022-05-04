#!/usr/bin/bash

SELF_DIR=`pwd -P`;

EXE_RES=`/usr/bin/openssl x509 -noout -text -in "$SELF_DIR/pki_root/pki/ca.crt" | grep -i "not after"`;
echo "CA: $EXE_RES";

EXE_RES=`grep -i "not after" $SELF_DIR/pki_root/pki/issued/vpn-server.crt`;
echo "Vpn-server-cert: $EXE_RES";

EXE_RES=`/usr/bin/openssl crl -inform PEM -in "$SELF_DIR/pki_root/pki/crl.pem" -text -noout | grep -i "next update"`;
echo "CRL: $EXE_RES";




