# Evaluación del CPU Throttling sobre Redes Overlay (Calico) en Kubernetes

Este repositorio contiene los scripts de aprovisionamiento de infraestructura (Capa de SO) y los manifiestos declarativos utilizados para validar el clúster de Kubernetes, como parte del **Trabajo Final Integrador de Sistemas Operativos y Redes 2**.

A diferencia de los benchmarks tradicionales, este proyecto evalúa empíricamente la degradación de la estabilidad de red para tráfico UDP (Jitter y pérdida de paquetes) cuando los nodos subyacentes agotan sus créditos de CPU.

## Arquitectura Desplegada

El entorno fue implementado en la región `us-east-1` de AWS, utilizando **3 instancias tipo `t2.medium` (Burstable)** (Ubuntu Server 22.04 LTS). La elección de esta familia de instancias es crítica para el experimento, ya que permite aislar el fenómeno de estrangulamiento físico del hipervisor:

* **1 Nodo Master:** Gestiona el Control Plane (API, Scheduler, etcd).
* **2 Nodos Workers:** Ejecutan las cargas de trabajo (Pods) y son sometidos a estrés computacional.

## Estructura del Repositorio

### /scripts (Aprovisionamiento y Estrés)

* **`01-prepare-os.sh` a `04-install-calico.sh`:** Configuración base "The Hard Way". Desactivación de Swap, carga de módulos `overlay` y `br_netfilter`, instalación de Containerd/Kubeadm, y despliegue del túnel IP-in-IP mediante Calico CNI.
* **`05-induce-throttling.sh`:** (NUEVO) Script que instala y ejecuta `stress-ng` para forzar a la instancia anfitriona al 100% de carga, consumiendo artificialmente el *CPUCreditBalance* de AWS hasta provocar el estrangulamiento térmico/lógico.

### /manifests (Laboratorio UDP)

* **`iperf3-server.yaml`:** Despliega un Pod en modo servidor a la escucha en el Nodo Worker 1.
* **`iperf3-client.yaml`:** Instancia un Pod cliente en el Nodo Worker 2. Se utiliza para inyectar datagramas UDP masivos a través de la red Overlay encapsulada.

## Metodología de Ejecución (El Experimento)

Una vez inicializado el clúster con `kubeadm` y desplegado el CNI, el experimento consta de dos fases:

### Fase 1: Línea Base (Red Sana / 100% Créditos de CPU)

Se mide la estabilidad del túnel IP-in-IP bajo condiciones óptimas inyectando 100 Mbps de tráfico UDP.

```bash
kubectl exec -it iperf3-client -- iperf3 -c 192.168.1.5 -u -b 100M -t 10
```

*(El Jitter esperado se mantiene por debajo de 0.05 ms con 0% de pérdida de paquetes).*

### Fase 2: Inducción de Estrés (Gap de Investigación)

Se ejecuta la herramienta de estrés dentro del nodo Worker 1 para agotar los créditos del procesador:

```bash
bash scripts/05-induce-throttling.sh
```

Una vez que el nodo entra en estado *Throttled*, se repite exactamente la misma medición UDP:

```bash
kubectl exec -it iperf3-client -- iperf3 -c 192.168.1.5 -u -b 100M -t 10
```

*(Al quedarse sin ciclos de reloj para que el kernel envuelva los paquetes mediante iptables, se evidencia una degradación catastrófica superando los 6.8 ms de Jitter y el descarte de hasta un 17% del tráfico en tiempo real).*
