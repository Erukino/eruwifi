#!/bin/bash

trap Ctrl_c 2

function Ctrl_c(){

	banner 

	echo
	echo
	echo "Cerrando procesos gracias"
	rm eruhostapd.conf
	rm erudhcp.conf
	airmon-ng stop $mon > /dev/null
	sleep 2
	exit


}


function banner { 

	clear
	bash banner.sh
	sleep 1
}

function interface_mon {


read -p "Ingrese interface de red: " interface
echo ""
echo ""

echo "$interface"                                                                echo
airmon-ng start $interface > /dev/null
mon= ifconfig -s | grep 'mon' | awk '{print $1}'
                                                                                 echo $mon
}                                                                                
function interfaces {

	clear 

	banner

        ifconfig -s | awk '{print $1}' | while read line; do echo 'interface de red " '$line ' "'; done

}

function ehostapd {

	clear 
	banner

        echo 'Creando configuracion hostapd'
        read -p 'Essid de la red :' ssid
        read -p 'Por cual canal desea montar la red (1-12): ' ch
        echo 'interface='$mon >> eruhostapd.conf
        echo 'ssid='$ssid >> eruhostapd.conf
        echo 'hw_mode=g' >> eruhostapd.conf
        echo 'channel='$ch >> eruhostapd.conf
        echo 'auth_algs=1' >> eruhostapd.conf
        echo 'wmm_enabled=0' >> eruhostapd.conf
}

function erudhcp {



        echo 'Configurando dhcp'
        echo 'interface='$mon >> erudhcp.conf
	echo 'dhcp-range=10.0.0.10,10.0.0.25,255.255.255.0,3h' >> erudhcp.conf
        echo 'dhcp-option=3,10.0.0.1' >> erudhcp.conf
        echo 'dhcp-option=6,10.0.0.1' >> erudhcp.conf
        echo 'server=8.8.8.8' >> erudhcp.conf
        echo 'log-queries' >> erudhcp.conf
        echo 'log-dbhp' >> erudhcp.conf
        echo 'listen-address=127.0.0.1' >> erudhcp.conf


}

function conecction {

        clear
	banner
        read -p "Interface a compartir red" red
        echo 'iniciando configuracion de ap'
	hostapd eruhostapd.conf > /dev/null
	ifconfig $mon 10.0.0.1 netmask 255.255.255.0
	dnsmasq -C erudhcp.conf -d > /dev/null
        route add -net 10.0.0.1 netmask 255.255.255.0 gw 10.0.0.1
	iptables --table nat --append POSTROUTING --out-interface $red -j MASQUERADE
	iptables --append FORWARD --in-interface $mon -j ACCEPT
        echo 1 > /proc/sys/net/ipv4/ip_forward

}

function final {
       
	clear
	banner
	echo
	echo
	read -p "Para finalizar el script presiona Ctrl_c" k
	final 
}

interfaces
interface_mon
ehostapd
erudhcp
conecction
final
