# 🚀 Despliegue Manual de Kubernetes en AWS ("The Hard Way")

Este repositorio contiene los scripts de aprovisionamiento de infraestructura (Capa de SO) y los manifiestos declarativos utilizados para validar el clúster de Kubernetes, como parte del **Trabajo Final Integrador de Sistemas Operativos y Redes 2**.

## 🏗️ Arquitectura Desplegada

El entorno fue implementado en la región `us-east-1` de AWS, utilizando **3 instancias tipo `t2.medium`** (Ubuntu Server 22.04 LTS) para soportar adecuadamente el Control Plane y evitar excepciones por *OOMKill*:

* **1 Nodo Master:** Gestiona la API, el Scheduler y etcd.
* **2 Nodos Workers:** Encargados de ejecutar las cargas de trabajo (Pods).

## 📂 Estructura del Repositorio

* `/scripts`: Scripts bash automatizados para la preparación de los nodos. Incluye la desactivación de *Swap*, carga de módulos de red del Kernel (`br_netfilter`), e instalación de **containerd** (CRI) y herramientas base.
* `/manifests`: Archivos YAML que contienen la prueba de humo (*Smoke Test*) desplegada para validar la funcionalidad del CNI (Calico) y el balanceo mediante NodePort.

## ⚙️ Inicialización del Control Plane y Red Overlay

La inicialización se realizó vinculando explícitamente el socket de Containerd y reservando el bloque de IPs lógicas para el posterior despliegue del plugin de red **Calico**::

```bash
sudo kubeadm init --cri-socket /run/containerd/containerd.sock --pod-network-cidr=192.168.0.0/16
```

## 🎥 Demostración Práctica

El proceso completo interactivo, desde la configuración pura en Linux hasta la unión de los Workers y la validación en estado Ready, está documentado en video:
[👉 https://youtu.be/3GyBn6LX6y8?si=dmh467TfGyIsdlcX](https://youtu.be/3GyBn6LX6y8?si=dmh467TfGyIsdlcX)
