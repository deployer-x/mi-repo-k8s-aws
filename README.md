# Despliegue Manual de Kubernetes en AWS ("The Hard Way")

Este repositorio contiene los scripts de aprovisionamiento de infraestructura (Capa de SO) y los manifiestos declarativos utilizados para validar el clúster de Kubernetes, como parte del **Trabajo Final Integrador de Sistemas Operativos y Redes 2**.

## Arquitectura Desplegada

El entorno fue implementado en la región `us-east-1` de AWS, utilizando **3 instancias tipo `t2.medium`** (Ubuntu Server 22.04 LTS) para soportar adecuadamente el Control Plane y evitar excepciones por *OOMKill*:

* **1 Nodo Master:** Gestiona la API, el Scheduler y etcd.
* **2 Nodos Workers:** Encargados de ejecutar las cargas de trabajo (Pods).

## Estructura del Repositorio y Descripción de Archivos

El proyecto se divide lógicamente en la preparación del sistema operativo base (scripts) y la declaración de recursos en el clúster (manifests).

### /scripts (Aprovisionamiento y Configuración Base)

* **`01-prepare-os.sh`:** Configura el Kernel de Linux. Desactiva la memoria Swap, carga los módulos necesarios (`overlay`, `br_netfilter`) y activa el reenvío de paquetes IPv4 (`net.ipv4.ip_forward=1`) para permitir el ruteo interno.
* **`02-install-containerd.sh`:** Instala el runtime de contenedores (*Containerd*) y lo configura para delegar la gestión de recursos (CPU/RAM) a *systemd* mediante la directiva `SystemdCgroup = true`.
* **`03-install-k8s-tools.sh`:** Descarga las llaves GPG oficiales de Kubernetes e instala los componentes base del sistema: `kubeadm` (bootstrap), `kubelet` (agente del nodo) y `kubectl` (CLI).
* **`04-install-calico.sh`:** Ejecuta el manifiesto oficial para desplegar la red Overlay (Calico CNI), permitiendo el enrutamiento BGP y el encapsulamiento IP-in-IP entre los nodos.

### /manifests

Los manifiestos de este directorio están estructurados para replicar las dos fases de la metodología de investigación detallada en el informe:

**Fase 1: Validación de Conectividad (Smoke Test)**

* **`nginx-deployment.yaml`:** Manifiesto declarativo que despliega 2 réplicas del servidor web Nginx. Su objetivo es forzar la distribución de Pods en distintos Nodos Workers para validar que Calico asigne correctamente el bloque de IPs lógicas (192.168.x.x) ignorando la red física de AWS.
* **`nginx-service-nodeport.yaml`:** Expone el despliegue de Nginx abriendo el puerto 32000, permitiendo comprobar el ruteo HTTP básico y el balanceo de carga.

**Fase 2: Medición de Rendimiento y Overhead (Gap Experimental)**

* **`iperf3-server.yaml`:** Despliega un Pod en modo servidor ejecutando la herramienta de pruebas de red `iperf3` a la escucha en un Nodo Worker.
* **`iperf3-client.yaml`:** Instancia un Pod cliente utilizado para inyectar tráfico TCP masivo hacia el servidor a través de la red Overlay (túnel IP-in-IP). Esto permite cuantificar la caída de ancho de banda y la latencia generada por el encapsulamiento respecto a la red nativa de AWS.

## Inicialización del Control Plane y Red Overlay

La inicialización se realizó vinculando explícitamente el socket de Containerd y reservando el bloque de IPs lógicas para el posterior despliegue del plugin de red **Calico**:

```bash
sudo kubeadm init --cri-socket /run/containerd/containerd.sock --pod-network-cidr=192.168.0.0/16
```

# Configurar kubeconfig para el usuario actual

Una vez inicializado el clúster, se debe configurar el entorno del usuario y desplegar el plugin de red (CNI) ejecutando el cuarto script:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

# Desplegar Calico

Finalmente, desplegar el plugin de red (CNI) ejecutando el cuarto script:

```bash
bash scripts/04-install-calico.sh
```

## Demostración Práctica

El proceso completo interactivo, desde la configuración pura en Linux hasta la unión de los Workers y la validación en estado Ready, está documentado en video:
[👉 https://youtu.be/3GyBn6LX6y8?si=dmh467TfGyIsdlcX](https://youtu.be/3GyBn6LX6y8?si=dmh467TfGyIsdlcX)
