#!/bin/bash
echo "[*] Instalando herramientas de estrés y monitoreo (stress-ng, sysstat)..."
sudo apt-get update
sudo apt-get install stress-ng sysstat -y

echo "[!] ATENCIÓN: Iniciando estrangulamiento de CPU (CPU Throttling)."
echo "[!] Consumiendo créditos de la instancia t2.medium..."
echo "[*] Para monitorear la asfixia del kernel, abre otra terminal y ejecuta: mpstat -P ALL 2 1"

# Ejecuta stress-ng en los 2 núcleos lógicos al 100% durante 45 minutos
sudo stress-ng --cpu 2 --cpu-load 100 --timeout 45m --metrics