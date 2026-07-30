#!/bin/bash
echo "[*] Cambiando modo de enrutamiento en Calico CNI..."

if [ "$1" == "nativo" ]; then
    kubectl patch ippool default-ipv4-ippool --type='merge' -p '{"spec": {"ipipMode": "Never"}}'
    echo "[+] Enrutamiento Nativo activado. (IP-in-IP Apagado)."
elif [ "$1" == "overlay" ]; then
    kubectl patch ippool default-ipv4-ippool --type='merge' -p '{"spec": {"ipipMode": "Always"}}'
    echo "[+] Red superpuesta activada. (IP-in-IP Encendido)."
else
    echo "[!] Error. Uso: bash 06-toggle-routing.sh [nativo|overlay]"
fi