#!/bin/bash

ADAPTERS=""
INTERFACE=""
NETCTL_DIR="/etc/netctl"

install_pkgs() {
    printf "WARNING: $3 package will be installed. Continue (y/N): "
    read answer
    
    if [ "$answer" == "y" ] ; then 
        echo "Installing Packages...."
        # $1 = Package Manager
        # $2 = Install Cmd
        # $3 = Package
        $@
    else
	    ./lsct
    fi
}

get_net_adapters() {
    echo "Enter the name of the adapter you would like to configure:"
    
    ADAPTERS=$(ls /sys/class/net)

    local i=1
    for nic in $ADAPTERS
    do
	if [ $nic != "lo" ] ; then
	    echo $i")" $nic
	    ((i++))
	fi 
    done

    read INTERFACE

    get_net_config
}

get_net_config() {
    local ip

    echo "The following prompts will guide you through configuring network adapters"
    printf "Configure $INTERFACE with static or dhcp IP (static/dhcp)? "
    read IP
    
    if [ "$IP" == "static" ] ; then
	printf "Please enter the connection type (ethernet/wireless): "
        read CONNECTION

	printf "Enter IP Address for interface $INTERFACE: "
	read ADDRESS

	printf "Enter Gateway Address for interface $INTERFACE: "
	read GATEWAY

	printf "Enter DNS Address for interface $INTERFACE: "
	read DNS

        if [ "$CONNECTION" == "wireless" ] ; then
            get_wireless_config
        fi

	set_net_config
	start_interface
	
	printf "Would you like to configure another interface? (y/N): "
        read answer

	if [ "$answer" == "y" ] ; then
	    get_net_adapters
	fi	
    
    elif [ "$IP" == "dhcp"  ] ; then
	printf "Please enter the connection type (ethernet/wireless): "
	read CONNECTION

        if [ "$CONNECTION" == "wireless" ] ; then
	    get_wireless_config
	fi

	set_net_config
	start_interface

	printf "Would you like to configure another interface? (y/N): "
        read answer

	if [ "$answer" == "y" ] ; then
	    get_net_adapters
	fi
    fi
}

get_wireless_config() {
    printf "Wireless security type (wpa/wep): "
    read SECURITY

    printf "Please enter the SSID: "
    read SSID

    printf "Please enter wireless key: "
    read KEY
}

set_net_config() {
    echo "Writing out network configuration"

    if [ ! -f $NETCTL_DIR ] ; then
        mkdir -p $NETCTL_DIR
    fi

    # Need vlan-static, vlan-dhcp

    if [[ "$IP" == "static" && "$CONNECTION" == "ethernet"  ]] ; then
        cp examples/ethernet-static $NETCTL_DIR/$INTERFACE
    elif [[ "$IP" == "static" && "$CONNECTION" == "wireless" ]] ; then
        cp examples/wireless-wpa-static $NETCTL_DIR/$INTERFACE
    elif [[ "$IP" == "dhcp" && "$CONNECTION" == "ethernet" ]] ; then
        cp examples/ethernet-dhcp $NETCTL_DIR/$INTERFACE
    elif [[ "$IP" == "dhcp" && "$CONNECTION" == "wireless" ]] ; then	
        cp examples/wireless-wpa $NETCTL_DIR/$INTERFACE
    fi
    
    sed -i "s/Connection=/Connection=$CONNECTION/" $NETCTL_DIR/$INTERFACE
    sed -i "s/IP=/IP=$IP/" $NETCTL_DIR/$INTERFACE
    sed -i "s/Interface=/Interface=$INTERFACE/" $NETCTL_DIR/$INTERFACE
    sed -i "s/Security=/Security=$SECURITY/" $NETCTL_DIR/$INTERFACE
    sed -i "s/ESSID=/ESSID='$SSID'/" $NETCTL_DIR/$INTERFACE
    sed -i "s/Key=/Key='$KEY'/" $NETCTL_DIR/$INTERFACE
    sed -i "s/Address=/Address=('$ADDRESS')/" $NETCTL_DIR/$INTERFACE
    sed -i "s/Gateway=/Gateway='$GATEWAY'/" $NETCTL_DIR/$INTERFACE
    sed -i "s/DNS=/DNS=('$DNS')/" $NETCTL_DIR/$INTERFACE

    # Default permissions allow unprivleged users access to read the file
    # changing permissions to prevent that from happening 
    chmod 640 $NETCTL_DIR/$INTERFACE
}

start_interface() {
   printf "Start $INTERFACE interface at boot? (y/N) "
   read choice

   if [ "$choice" == "y" ] ; then
      echo "Starting interface $INTERFACE"
      netctl enable $INTERFACE
      netctl start $INTERFACE
   fi
}

title() {
    echo "--------------------------------------------"
    echo "             Network Setup"
    echo "--------------------------------------------"
    echo ""
}

main() {
    title
    install_pkgs $@
    get_net_adapters
}

main $@

