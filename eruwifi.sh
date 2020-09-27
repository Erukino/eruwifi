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
	service network-manager restart
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
airmon-ng start $interface > /dev/null
sleep 4
mon=$(airmon-ng | grep 'mon' | awk '{print $2}')
sleep 2
killall network-manager hostapd dnsmasq wpa_supplicant dhcpd > /dev/null 2>&1
sleep 5
echo $mon 
sleep 3
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
	echo 'driver=nl80211' >> eruhostapd.conf
        echo 'ssid='$ssid >> eruhostapd.conf
        echo 'hw_mode=g' >> eruhostapd.conf
        echo 'channel='$ch >> eruhostapd.conf
        echo 'auth_algs=1' >> eruhostapd.conf
        echo 'wmm_enabled=0' >> eruhostapd.conf
}

function erudhcp {



        echo 'Configurando dhcp'
        echo 'interface='$mon >> erudhcp.conf
	echo 'dhcp-range=10.0.0.10,10.0.0.25,255.255.255.0,12h' >> erudhcp.conf
        echo 'dhcp-option=3,10.0.0.1' >> erudhcp.conf
        echo 'dhcp-option=6,10.0.0.1' >> erudhcp.conf
        echo 'server=8.8.8.8' >> erudhcp.conf
        echo 'log-queries' >> erudhcp.conf
        echo 'log-dhcp' >> erudhcp.conf
        echo 'listen-address=127.0.0.1' >> erudhcp.conf


}

function conecction {

        clear
	banner
        read -p "Interface a compartir red: " red
        clear 
	banner
	echo 'iniciando configuracion de ap'
	hostapd eruhostapd.conf > /dev/null 2>&1 &
	sleep 7
	echo 'Configurado Hostapd'
	ifconfig $mon up 10.0.0.1 netmask 255.255.255.0
	sleep 2
        route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1
	sleep 2
	dnsmasq -C erudhcp.conf -d > /dev/null 2>&1 &
	sleep 7
	echo 'Configurando DHCP'
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
