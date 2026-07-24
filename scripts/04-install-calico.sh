#!/bin/bash
echo "[*] Desplegando la red Overlay (Calico CNI)..."

# Aplicar el manifiesto oficial de Calico
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

echo "[+] Calico CNI desplegado correctamente."
echo "[+] Ejecuta 'kubectl get pods -n kube-system' para verificar el estado de la red."