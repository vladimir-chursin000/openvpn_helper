#!/usr/bin/bash

SELF_DIR=`pwd -P`;

source $SELF_DIR/vpn.env;
###CFG-VPN-SERVER-only (S)
#VPN_CONF_DIR_S
#VPN_SERVER_NAME_S
#IP_VPN_SERVER_S
#VPN_PORT_S
#VPN_SERV_LOG_DIR_S
#VPN_MAX_CLIENTS_S
#VPN_NETWORK_S
#VPN_DHCP_IP_S
#VPN_INTERNAL_NETWORK_ROUTE_S
#VPN_SERVER_LOG_LEVEL_S
#
#VPN_NETWORK_MASQUERADE_SRC_S
#VPN_INTERNAL_NETWORK_MASQUERADE_DST_S
#
#VPN_LOCAL_IP_DEV_NAME_S
#VPN_TUN_DEV_NAME_S
#VPN_SERVER_INT_FIREWALLD_ZONE_S
###CFG-VPN-SERVER-only

###CFG-VPN-CLIENT-only (CL)
#IP_VPN_SERVER_CL
#VPN_PORT_CL
#VPN_CLI_LOG_DIR_LINUX_CL
#VPN_CLI_LOG_LEVEL_CL
###CFG-VPN-CLIENT-only

###CFG-VPN-common (C)
#EASY_RSA_DIR_C
###CFG-VPN-common

###CFG EXPORT VARS (EV)
#CA_EXPIRE_EV
#KEY_EXPIRE_EV
#KEY_COUNTRY_EV
#KEY_PROVINCE_EV
#KEY_CITY_EV
#KEY_ORG_EV
#KEY_EMAIL_EV
#KEY_CN_EV
#KEY_OU_EV
#KEY_NAME_EV
#KEY_ALTNAMES_EV
###CFG EXPORT VARS

mkdir -p $SELF_DIR/pki_root/pki;
PKI_DIR="$SELF_DIR/pki_root/pki";
PKI_ROOT_THIS_VPN="$SELF_DIR/pki_root";
#
CLI_FILES_DIR_RESULT_CL="$SELF_DIR/cli_certs";
mkdir -p $CLI_FILES_DIR_RESULT_CL;
#
export CA_EXPIRE=$CA_EXPIRE_EV;
export KEY_EXPIRE=$KEY_EXPIRE_EV;
export KEY_COUNTRY=$KEY_COUNTRY_EV;
export KEY_PROVINCE=$KEY_PROVINCE_EV;
export KEY_CITY=$KEY_CITY_EV;
export KEY_ORG=$KEY_ORG_EV;
export KEY_EMAIL=$KEY_EMAIL_EV;
export KEY_CN=$KEY_CN_EV;
export KEY_OU=$KEY_OU_EV;
export KEY_NAME=$KEY_NAME_EV;
export KEY_ALTNAMES=$KEY_ALTNAMES_EV;
#==================================================================

###FUNCTIONS
function func_create_cli_cert_and_conf() {
    echo 'Enter client cert name:';
    read CN;
    CLI_FILES_DIR_RESULT_CL="$CLI_FILES_DIR_RESULT_CL/$CN-files";
    mkdir -p $CLI_FILES_DIR_RESULT_CL/$CN;
    
    echo "Enter client-cert='$CN' password (for saving locally):";
    read CLI_PASS;
    
    cd $PKI_ROOT_THIS_VPN;
    $EASY_RSA_DIR_C/easyrsa gen-req $CN;
    $EASY_RSA_DIR_C/easyrsa sign-req client $CN;
    
    cp $PKI_DIR/ca.crt $CLI_FILES_DIR_RESULT_CL/$CN/ca.crt;
    cp $PKI_DIR/ta.key $CLI_FILES_DIR_RESULT_CL/$CN/ta.key;
    
    cp $PKI_DIR/issued/$CN.crt $CLI_FILES_DIR_RESULT_CL/$CN/$CN.crt;
    cp $PKI_DIR/private/$CN.key $CLI_FILES_DIR_RESULT_CL/$CN/$CN.key;
    
    ###conf-file for linux-client
    echo 'client' > $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'resolv-retry infinite' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'nobind' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo "remote $IP_VPN_SERVER_CL $VPN_PORT_CL" >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'proto udp' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'dev tun' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'comp-lzo no' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo "ca $CN/ca.crt" >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo "cert $CN/$CN.crt" >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo "key $CN/$CN.key" >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'tls-client' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo "tls-auth $CN/ta.key 1" >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'cipher AES-256-GCM' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'float' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'keepalive 10 30' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'explicit-exit-notify 2' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'persist-key' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'persist-tun' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo "verb $VPN_CLI_LOG_LEVEL_CL" >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo "#status $VPN_CLI_LOG_DIR_LINUX_CL/openvpn-$CN-status.log" >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo "#log-append $VPN_CLI_LOG_DIR_LINUX_CL/openvpn-$CN.log" >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo "askpass $CN.askpass" >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'auth-nocache' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'remote-cert-tls server' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'mtu-test' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo 'auth-user-pass' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo "auth-user-pass $CN.auth" >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo '###' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    echo '#For linux-openvpn-client' >> $CLI_FILES_DIR_RESULT_CL/$CN.conf;
    ###conf-file for linux-client
    
    ###conf-file for win-client
    echo 'client' > $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'resolv-retry infinite' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'nobind' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo "remote $IP_VPN_SERVER_CL $VPN_PORT_CL" >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'proto udp' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'dev tun' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'comp-lzo no' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo "ca \"C:\\Program Files\\OpenVPN\\config\\$CN\\ca.crt\"" >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo "cert \"C:\\Program Files\\OpenVPN\\config\\$CN\\$CN.crt\"" >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo "key \"C:\\Program Files\\OpenVPN\\config\\$CN\\$CN.key\"" >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'tls-client' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo "tls-auth \"C:\\Program Files\\OpenVPN\\config\\$CN\\ta.key\" 1" >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'cipher AES-256-GCM' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'float' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'keepalive 10 30' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'explicit-exit-notify 2' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'persist-key' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'persist-tun' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo "verb $VPN_CLI_LOG_LEVEL_CL" >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo "#status \"C:\\Program Files\\OpenVPN\\log\\openvpn-$CN-status.log\"" >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo "#log-append \"C:\\Program Files\\OpenVPN\\log\\openvpn-$CN.log\"" >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo '###' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo '#Uncomment if need for automatic entering client-cert-password' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo "#askpass \"C:\\Program Files\\OpenVPN\\config\\$CN.askpass\"" >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo '###' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'auth-nocache' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'remote-cert-tls server' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'mtu-test' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo 'auth-user-pass' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo "#auth-user-pass \"C:\\Program Files\\OpenVPN\\config\\$CN.auth\"" >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo '###' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo '#For windows-openvpn-client' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo '###=============For autostart via win-scheduler' >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    echo "###\"C:\Program Files\OpenVPN\bin\openvpn.exe\" --config \"C:\Program Files\OpenVPN\config\$CN.ovpn\"" >> $CLI_FILES_DIR_RESULT_CL/$CN.ovpn;
    ###conf-file for win-client

    echo $CLI_PASS > $CLI_FILES_DIR_RESULT_CL/$CN.askpass;
    echo 'ENTER_YOUR_LOGIN_HERE' > $CLI_FILES_DIR_RESULT_CL/$CN.auth;
    echo 'ENTER_YOUR_PASSWORD_HERE' >> $CLI_FILES_DIR_RESULT_CL/$CN.auth;
    
    cd $CLI_FILES_DIR_RESULT_CL;
    zip -r9 $CN.zip $CN $CN.conf $CN.ovpn $CN.auth $CN.askpass;
    echo "ZIP-archive='$CN.zip' with client-files for cert='$CN' created at '$CLI_FILES_DIR_RESULT_CL'";
}

function func_gen_crl_and_restart_ovpn() {
    #If one of client cert was revoked
    cd $PKI_ROOT_THIS_VPN;
    $EASY_RSA_DIR_C/easyrsa gen-crl;
    cp $PKI_DIR/crl.pem $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/crl.pem;
    systemctl restart openvpn-server@$VPN_SERVER_NAME_S;
}

function func_revoke_client_cert() {
    echo 'Enter client cert name:';
    read CN;
    CLI_FILES_DIR_RESULT_CL="$CLI_FILES_DIR_RESULT_CL/$CN-files";
    
    cd PKI_ROOT_THIS_VPN;
    $EASY_RSA_DIR_C/easyrsa revoke $CN;
    
    rm -rf $CLI_FILES_DIR_RESULT_CL;
    
    echo "Client cert='$CN' was revoked. Now run 'gen_crl_and_restart_ovpn.sh'";
}

function func_full_setup_vpn_server {
    echo 'WARNING! After full setup You need to recreate all clients cerificates!';
    echo "Do You want to continue? (Enter 'yes' to continue)";
    read NEXT;
    if [ "$NEXT" != "yes" ]; then
	echo "You do not enter 'yes'. Exit!";
	exit;
    fi;
    
    cd $PKI_ROOT_THIS_VPN;
    $EASY_RSA_DIR_C/easyrsa init-pki;
    
    echo 'Enter CA password (for saving locally):';
    read CA_PASS_LOCAL;
    $EASY_RSA_DIR_C/easyrsa build-ca;
    
    $EASY_RSA_DIR_C/easyrsa gen-dh;
    
    echo 'Enter vpn-server-cert (PEM pass) password (for saving locally):';
    read VPNSERV_PASS_LOCAL;
    $EASY_RSA_DIR_C/easyrsa gen-req vpn-server;
    
    echo "Your CA password is '$CA_PASS_LOCAL'";
    $EASY_RSA_DIR_C/easyrsa sign-req server vpn-server;
    
    echo "Your CA password is '$CA_PASS_LOCAL'";
    $EASY_RSA_DIR_C/easyrsa gen-crl;
    
    /usr/sbin/openvpn --genkey --secret $PKI_DIR/ta.key;
    
    mkdir -p /etc/openvpn/server/keys/$VPN_SERVER_NAME_S;
    echo "Keys-dir='/etc/openvpn/server/keys/$VPN_SERVER_NAME_S' for vpn-server='$VPN_SERVER_NAME_S' was created";
    
    ###From $PKI_DIR copy to $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S this files: ca.crt, dh.pem, ta.key
    \cp $PKI_DIR/ca.crt $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/ca.crt;
    chmod 0600 $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/ca.crt;
    \cp $PKI_DIR/dh.pem $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/dh.pem;
    chmod 0600 $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/dh.pem;
    \cp $PKI_DIR/ta.key $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/ta.key;
    chmod 0600 $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/ta.key;
    ###
    
    ###From $PKI_DIR/issued copy to $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S this file: vpn-server.crt
    \cp $PKI_DIR/issued/vpn-server.crt $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/vpn-server.crt;
    chmod 0600 $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/vpn-server.crt;
    ###
    
    ###From $PKI_DIR/private copy to $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S this file: vpn-server.key
    \cp $PKI_DIR/private/vpn-server.key $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/vpn-server.key;
    chmod 0600 $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/vpn-server.key;
    ###
        
    ###From $PKI_DIR copy to $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S this file: crl.pem
    \cp $PKI_DIR/crl.pem $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/crl.pem;
    chmod 0600 $VPN_CONF_DIR_S/keys/$VPN_SERVER_NAME_S/crl.pem;
    ###

    mkdir -p $VPN_SERV_LOG_DIR_S;
    echo "Dir-for-logs='$VPN_SERV_LOG_DIR_S' was created";
    
    ###Wr CONF-file for server=$VPN_SERVER_NAME_S
    echo "local $IP_VPN_SERVER_S" > $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "port $VPN_PORT_S" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'proto udp' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "dev $VPN_TUN_DEV_NAME_S" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "ca keys/$VPN_SERVER_NAME_S/ca.crt" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "cert keys/$VPN_SERVER_NAME_S/vpn-server.crt"  >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "key keys/$VPN_SERVER_NAME_S/vpn-server.key"  >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "dh keys/$VPN_SERVER_NAME_S/dh.pem" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "tls-auth keys/$VPN_SERVER_NAME_S/ta.key 0" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "crl-verify keys/$VPN_SERVER_NAME_S/crl.pem" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'cipher AES-256-GCM' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "server $VPN_NETWORK_S" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "ifconfig-pool-persist $VPN_SERVER_NAME_S-ipp.txt" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'keepalive 10 30' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'explicit-exit-notify 2' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "max-clients $VPN_MAX_CLIENTS_S" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'persist-key' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'persist-tun' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "status $VPN_SERV_LOG_DIR_S/openvpn-$VPN_SERVER_NAME_S-status.log" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "log-append $VPN_SERV_LOG_DIR_S/openvpn-$VPN_SERVER_NAME_S.log" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "verb $VPN_SERVER_LOG_LEVEL_S" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'mute 20' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'daemon' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'mode server' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'tls-server' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'comp-lzo no' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "askpass $VPN_SERVER_NAME_S-pass" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'auth-nocache' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'user nobody' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'mtu-test' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'username-as-common-name' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "group openvpn_users_$VPN_SERVER_NAME_S" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf; #check
    echo "plugin /usr/lib64/openvpn/plugins/openvpn-plugin-auth-pam.so openvpn_$VPN_SERVER_NAME_S" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf; #check
    echo "#push \"route $VPN_NETWORK_S\"" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "push \"route $VPN_INTERNAL_NETWORK_ROUTE_S\"" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo '###' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo '#Uncomment if dnsmasq is confugired' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo "#push \"dhcp-option DNS $VPN_DHCP_IP_S\"" >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo '###' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    echo 'topology subnet' >> $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf;
    #
    echo "VPN-conf-file='$VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf' was created";
    ###
    
    ###Generate etc-pam.d-openvpn_VPN_SERVER_NAME_S
    echo "auth        [success=1 default=bad]     pam_succeed_if.so quiet user ingroup openvpn_users_$VPN_SERVER_NAME_S" > /etc/pam.d/"openvpn_$VPN_SERVER_NAME_S";
    echo 'auth        [default=die]               pam_unix.so' >> /etc/pam.d/"openvpn_$VPN_SERVER_NAME_S";
    echo 'auth        [success=1 default=bad]     pam_unix.so' >> /etc/pam.d/"openvpn_$VPN_SERVER_NAME_S";
    echo 'auth        [default=die]               pam_faillock.so no_log_info authfail deny=3 fail_interval=900 unlock_time=3600' >> /etc/pam.d/"openvpn_$VPN_SERVER_NAME_S";
    echo 'auth        [default=done]              pam_faillock.so no_log_info authsucc deny=3 fail_interval=900 unlock_time=3600' >> /etc/pam.d/"openvpn_$VPN_SERVER_NAME_S";
    echo 'account     [default=done]              pam_permit.so' >> /etc/pam.d/"openvpn_$VPN_SERVER_NAME_S";
    #
    echo "PAM-file='/etc/pam.d/openvpn_$VPN_SERVER_NAME_S' was created";
    ###
    
    ###Create VPN_SERVER_NAME_S-pass-file
    echo "$VPNSERV_PASS_LOCAL" > $VPN_CONF_DIR_S/"$VPN_SERVER_NAME_S-pass";
    chmod 0400 $VPN_CONF_DIR_S/"$VPN_SERVER_NAME_S-pass";
    echo "File='$VPN_CONF_DIR_S/$VPN_SERVER_NAME_S-pass' with pass for using at VPN-conf-file ('$VPN_CONF_DIR_S/$VPN_SERVER_NAME_S.conf') was created with permission='0400'";
    ###

    ###Create ipp-file if not exists
    touch $VPN_CONF_DIR_S/"$VPN_SERVER_NAME_S-ipp.txt";
    echo "Ifconfig-pool-persist file='$VPN_CONF_DIR_S/$VPN_SERVER_NAME_S-ipp.txt' was created";
    ###
    
    ###Create group for this ovpn-service
    groupadd -f "openvpn_users_$VPN_SERVER_NAME_S";
    #
    echo "User-group='openvpn_users_$VPN_SERVER_NAME_S' for vpn-server='$VPN_SERVER_NAME_S' was created";
    ###
    
    ###Apply selinux rules
    semanage port -a -t openvpn_port_t -p udp $VPN_PORT_S;
    semanage port -a -t openvpn_port_t -p tcp $VPN_PORT_S;
    #
    #Allow rw-context for ipp-file
    semanage fcontext -a -t openvpn_etc_rw_t $VPN_CONF_DIR_S/"$VPN_SERVER_NAME_S-ipp.txt";
    restorecon $VPN_CONF_DIR_S/"$VPN_SERVER_NAME_S-ipp.txt";
    #
    echo "Port (tcp/udp)=$VPN_PORT_S is allowed now via selinux";
    echo "Set selinux-rw-context for '$VPN_CONF_DIR_S/$VPN_SERVER_NAME_S-ipp.txt': OK";
    ###
    
    ###Create readme-selinux-rules
    echo "###GENERATED by 'full_setup_vpn_server.sh'" > $SELF_DIR/readme-selinux-rules.txt;
    echo "######" >> $SELF_DIR/readme-selinux-rules.txt;
    echo "# semanage port -a -t openvpn_port_t -p udp $VPN_PORT_S /// for allow udp-port" >> $SELF_DIR/readme-selinux-rules.txt;
    echo "# semanage port -a -t openvpn_port_t -p tcp $VPN_PORT_S /// for allow tcp-port" >> $SELF_DIR/readme-selinux-rules.txt;
    echo '###' >> $SELF_DIR/readme-selinux-rules.txt;
    echo "# semanage port -d -t openvpn_port_t -p udp $VPN_PORT_S /// for deny udp-port" >> $SELF_DIR/readme-selinux-rules.txt;
    echo "# semanage port -d -t openvpn_port_t -p tcp $VPN_PORT_S /// for deny tcp-port" >> $SELF_DIR/readme-selinux-rules.txt;
    echo '###' >> $SELF_DIR/readme-selinux-rules.txt;
    echo "# semanage fcontext -a -t openvpn_etc_rw_t $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S-ipp.txt /// allow read/write operations with ipp-file (ifconfig-pool-persist)" >> $SELF_DIR/readme-selinux-rules.txt;
    echo "# restorecon $VPN_CONF_DIR_S/$VPN_SERVER_NAME_S-ipp.txt /// Apply changes to file" >> $SELF_DIR/readme-selinux-rules.txt;
    echo '###' >> $SELF_DIR/readme-selinux-rules.txt;
    echo "# semanage port -l | grep openvpn_port_t /// for view list of openvpn ports allowed by selinux" >> $SELF_DIR/readme-selinux-rules.txt;
    #
    echo "File='$SELF_DIR/readme-selinux-rules.txt' was created";
    ###
    
    ###Apply firewalld rules for ports (udp/tcp)
    firewall-cmd --permanent --zone=$VPN_SERVER_INT_FIREWALLD_ZONE_S --add-port=$VPN_PORT_S/udp;
    firewall-cmd --permanent --zone=$VPN_SERVER_INT_FIREWALLD_ZONE_S --add-port=$VPN_PORT_S/tcp;
    #VPN_NETWORK_MASQUERADE_SRC_S
    #VPN_INTERNAL_NETWORK_MASQUERADE_DST_S
    firewall-cmd --permanent --zone=$VPN_SERVER_INT_FIREWALLD_ZONE_S --add-rich-rule="rule family=ipv4 source address=$VPN_NETWORK_MASQUERADE_SRC_S destination address=$VPN_INTERNAL_NETWORK_MASQUERADE_DST_S masquerade"
    ###
    #VPN_LOCAL_IP_DEV_NAME_S
    #VPN_TUN_DEV_NAME_S
    #VPN_SERVER_INT_FIREWALLD_ZONE_S
    firewall-cmd --permanent --zone=$VPN_SERVER_INT_FIREWALLD_ZONE_S --change-interface=$VPN_LOCAL_IP_DEV_NAME_S;
    firewall-cmd --permanent --zone=$VPN_SERVER_INT_FIREWALLD_ZONE_S --change-interface=$VPN_TUN_DEV_NAME_S;
    firewall-cmd --reload;
    #
    echo "Port (tcp/udp)=$VPN_PORT_S is allowed now via firewalld";
    echo "Allow masquerading from '$VPN_NETWORK_MASQUERADE_SRC_S' to '$VPN_INTERNAL_NETWORK_MASQUERADE_DST_S'";
    echo "Interfaces '$VPN_TUN_DEV_NAME_S' and '$VPN_LOCAL_IP_DEV_NAME_S' moved to firewall zone='$VPN_SERVER_INT_FIREWALLD_ZONE_S'";
    echo 'Firewall rules reloaded';
    ###

    ###Create readme-firewalld-rules
    echo "###GENERATED by 'full_setup_vpn_server.sh'" > $SELF_DIR/readme-firewalld-rules.txt;
    echo "######" >> $SELF_DIR/readme-firewalld-rules.txt;
    echo "# firewall-cmd --permanent --zone=$VPN_SERVER_INT_FIREWALLD_ZONE_S --add-port=$VPN_PORT_S/udp /// for allow udp port" >> $SELF_DIR/readme-firewalld-rules.txt;
    echo "# firewall-cmd --permanent --zone=$VPN_SERVER_INT_FIREWALLD_ZONE_S --add-port=$VPN_PORT_S/tcp /// for allow tcp port" >> $SELF_DIR/readme-firewalld-rules.txt;
    echo '###' >> $SELF_DIR/readme-firewalld-rules.txt;
    echo "# firewall-cmd --permanent --zone=$VPN_SERVER_INT_FIREWALLD_ZONE_S --remove-port=$VPN_PORT_S/udp /// for deny udp port" >> $SELF_DIR/readme-firewalld-rules.txt;
    echo "# firewall-cmd --permanent --zone=$VPN_SERVER_INT_FIREWALLD_ZONE_S --remove-port=$VPN_PORT_S/tcp /// for deny tcp port" >> $SELF_DIR/readme-firewalld-rules.txt;
    echo '###' >> $SELF_DIR/readme-firewalld-rules.txt;
    echo "# firewall-cmd --permanent --zone=public --add-rich-rule='rule family=ipv4 source address=$VPN_NETWORK_MASQUERADE_SRC_S destination address=$VPN_INTERNAL_NETWORK_MASQUERADE_DST_S masquerade' /// allow masquerading" >> $SELF_DIR/readme-firewalld-rules.txt;
    echo "# firewall-cmd --permanent --zone=public --remove-rich-rule='rule family=ipv4 source address=$VPN_NETWORK_MASQUERADE_SRC_S destination address=$VPN_INTERNAL_NETWORK_MASQUERADE_DST_S masquerade' /// Deny masquerading" >> $SELF_DIR/readme-firewalld-rules.txt;
    echo '###' >> $SELF_DIR/readme-firewalld-rules.txt;
    echo "# firewall-cmd --list-all --zone=$VPN_SERVER_INT_FIREWALLD_ZONE_S /// view all rules for firewall zone" >> $SELF_DIR/readme-firewalld-rules.txt;
    echo '###' >> $SELF_DIR/readme-firewalld-rules.txt;
    echo '# firewall-cmd --reload /// reload firewall rules' >> $SELF_DIR/readme-firewalld-rules.txt;
    #
    echo "File='$SELF_DIR/readme-firewalld-rules.txt' was created";
    ###
    
    ###Create user management README
    echo "###GENERATED by 'full_setup_vpn_server.sh'" > $SELF_DIR/README-user-management.txt;
    echo "######" >> $SELF_DIR/README-user-management.txt;
    echo "###Before user management you need to generate user cert by script 'create_cli_cert_and_conf.sh'" >> $SELF_DIR/README-user-management.txt;
    echo "# useradd -G openvpn_users_$VPN_SERVER_NAME_S VPNUSERNAME -s /sbin/nologin /// Add new vpn-user for VPN-server='$VPN_SERVER_NAME_S'" >> $SELF_DIR/README-user-management.txt;
    echo '###' >> $SELF_DIR/README-user-management.txt;
    echo '# passwd VPNUSERNAME /// Set/Change password for user' >> $SELF_DIR/README-user-management.txt;
    echo '###' >> $SELF_DIR/README-user-management.txt;
    echo '# usermod -L VPNUSERNAME /// Lock user' >> $SELF_DIR/README-user-management.txt;
    echo '# usermod -U VPNUSERNAME /// Unlock user' >> $SELF_DIR/README-user-management.txt;
    #
    echo "File='$SELF_DIR/README-user-management.txt' was created";
    ###
    
    ###Create file with CA- and vpn-server-passwords
    echo "###GENERATED by 'full_setup_vpn_server.sh'" > $SELF_DIR/SAVED_CERT_PASSWORDS.txt;
    echo "######" >> $SELF_DIR/SAVED_CERT_PASSWORDS.txt;
    echo "CA password for VPN-server-name='$VPN_SERVER_NAME_S': '$CA_PASS_LOCAL'" >> $SELF_DIR/SAVED_CERT_PASSWORDS.txt;
    echo '###' >> $SELF_DIR/SAVED_CERT_PASSWORDS.txt;
    echo "Vpn-server-cert password for VPN-server-name='$VPN_SERVER_NAME_S': '$VPNSERV_PASS_LOCAL'" >> $SELF_DIR/SAVED_CERT_PASSWORDS.txt;
    echo '###' >> $SELF_DIR/SAVED_CERT_PASSWORDS.txt;
    echo 'Please, move this information to secured store' >> $SELF_DIR/SAVED_CERT_PASSWORDS.txt;
    ###
    
    ###Create common instruction file
    echo "###GENERATED by 'full_setup_vpn_server.sh'" > $SELF_DIR/README_MAIN.txt;
    echo "######" >> $SELF_DIR/README_MAIN.txt;
    echo "#Steps after 'full_setup_vpn_server.sh'" >> $SELF_DIR/README_MAIN.txt;
    echo "#1) Create user-cerificate by execute 'create_cli_cert_and_conf.sh'. At this step will be created client-ZIP-acrhive (with certs and conf-files)." >> $SELF_DIR/README_MAIN.txt;
    echo "#2) Create user with help of instruction 'README-user-management.txt'."  >> $SELF_DIR/README_MAIN.txt;
    echo "#3) Install at client side openvpn-client, put client-ZIP-archive to '/etc/openvpn/client'."  >> $SELF_DIR/README_MAIN.txt;
    echo "#4) Unzip client-ZIP-archive" >> $SELF_DIR/README_MAIN.txt;
    echo "#5) Fill file '*.auth' at client side with login (created at step 2) and password." >> $SELF_DIR/README_MAIN.txt;
    echo "#6) Run command 'systemctl start openvpn-client@_CONFIG_' where _CONFIG_=config name without '.conf'." >> $SELF_DIR/README_MAIN.txt;
    echo "#7) Use 'sysctemctl enable openvpn-client@_CONFIG_' if required autorun at start." >> $SELF_DIR/README_MAIN.txt;
    ###
    
    ###Restart (and enable=autorun at start) openvpn-server
    systemctl restart openvpn-server@$VPN_SERVER_NAME_S;
    systemctl enable openvpn-server@$VPN_SERVER_NAME_S;
    #
    echo "VPN-server='$VPN_SERVER_NAME_S' was restarted";
    ###
    
    ###Generate management scripts for this vpn-server
    #Gen restart-script
    echo "###GENERATED by 'full_setup_vpn_server.sh'" > $SELF_DIR/"RESTART_OVPN-$VPN_SERVER_NAME_S.sh";
    echo "######" >> $SELF_DIR/"RESTART_OVPN-$VPN_SERVER_NAME_S.sh";
    echo "systemctl stop openvpn-server@$VPN_SERVER_NAME_S;" >> $SELF_DIR/"RESTART_OVPN-$VPN_SERVER_NAME_S.sh";
    echo "systemctl start openvpn-server@$VPN_SERVER_NAME_S;" >> $SELF_DIR/"RESTART_OVPN-$VPN_SERVER_NAME_S.sh";
    echo "systemctl enable openvpn-server@$VPN_SERVER_NAME_S;" >> $SELF_DIR/"RESTART_OVPN-$VPN_SERVER_NAME_S.sh";
    echo "echo \"Now 'openvpn-$VPN_SERVER_NAME_S' is started/restarted\";" >> $SELF_DIR/"RESTART_OVPN-$VPN_SERVER_NAME_S.sh";
    chmod +x $SELF_DIR/"RESTART_OVPN-$VPN_SERVER_NAME_S.sh";
    #
    #Gen stop-scripts
    echo "###GENERATED by 'full_setup_vpn_server.sh'" > $SELF_DIR/"STOP_OVPN-$VPN_SERVER_NAME_S.sh";
    echo "######" >> $SELF_DIR/"STOP_OVPN-$VPN_SERVER_NAME_S.sh";
    echo "systemctl stop openvpn-server@$VPN_SERVER_NAME_S;" >> $SELF_DIR/"STOP_OVPN-$VPN_SERVER_NAME_S.sh";
    echo "systemctl disable openvpn-server@$VPN_SERVER_NAME_S;" >> $SELF_DIR/"STOP_OVPN-$VPN_SERVER_NAME_S.sh";
    echo "echo \"Now 'openvpn-$VPN_SERVER_NAME_S' is stopped (and set no autostart)'\";" >> $SELF_DIR/"STOP_OVPN-$VPN_SERVER_NAME_S.sh";
    chmod +x $SELF_DIR/"STOP_OVPN-$VPN_SERVER_NAME_S.sh";
    #
    ###
    
    echo 'NOW CREATE (or RECREATE ALL) USER CERTIFICATES!';
}
###FUNCTIONS

if [ "$1" == "gen_crl_and_restart_ovpn" ]; then
    func_gen_crl_and_restart_ovpn;
elif [ "$1" == "revoke_client_cert" ]; then
    func_revoke_client_cert;
elif [ "$1" == "create_cli_cert_and_conf" ]; then
    func_create_cli_cert_and_conf;
elif [ "$1" == "full_setup_vpn_server" ]; then
    func_full_setup_vpn_server;
fi