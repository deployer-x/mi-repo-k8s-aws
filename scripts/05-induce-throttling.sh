#!/bin/bash
echo "[*] Instalando herramienta de estrés (stress-ng)..."
sudo apt-get update
sudo apt-get install stress-ng -y

echo "[!] ATENCIÓN: Iniciando estrangulamiento de CPU (CPU Throttling)."
echo "[!] Consumiendo créditos de la instancia t2.medium..."
# Ejecuta stress-ng en los 2 núcleos lógicos al 100% durante 30 minutos
sudo stress-ng --cpu 2 --cpu-load 100 --timeout 30m --metrics