#!/bin/bash
echo "[*] Instalando Container Runtime (Containerd)..."

sudo apt-get update
sudo apt-get install -y containerd

# Generar configuración por defecto de containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null

# Configurar SystemdCgroup = true (Requerido por kubelet)
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

echo "[+] Containerd instalado y configurado."