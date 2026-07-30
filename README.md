# Análisis de Degradación en el Datapath: Impacto del CPU Throttling (AWS vs. CFS) sobre Redes Overlay y Enrutamiento Nativo en Kubernetes

Este repositorio contiene los scripts de aprovisionamiento de infraestructura (Capa de SO) y los manifiestos declarativos utilizados para validar el clúster de Kubernetes, como parte del **Trabajo Final Integrador de Sistemas Operativos y Redes 2**.

A diferencia de los benchmarks tradicionales, este proyecto aísla y evalúa empíricamente *dónde* ocurre el estrangulamiento de CPU (Throttling). Se contrasta la limitación de recursos a nivel de contenedor (K8s CFS) frente al estrangulamiento de hipervisor (AWS CPU Credits), midiendo el impacto destructivo del encapsulamiento IP-in-IP (Calico) sobre el hilo `ksoftirqd` del kernel para tráfico UDP en tiempo real.

## Arquitectura Desplegada

El entorno fue implementado en la región `us-east-1` de AWS, utilizando **3 instancias tipo `t2.medium` (Burstable)** (Ubuntu Server 22.04 LTS). La elección de esta familia de instancias es crítica, ya que permite aislar el fenómeno de estrangulamiento físico del hipervisor (agotamiento del *CPUCreditBalance*):

* **1 Nodo Master:** Gestiona el Control Plane (API, Scheduler, etcd).
* **2 Nodos Workers:** Ejecutan las cargas de trabajo (Pods) y son sometidos a estrés computacional.

## Estructura del Repositorio

### /scripts (Aprovisionamiento, Estrés y Ruteo)

* **`01` a `04`:** Configuración base "The Hard Way". Preparación del kernel, instalación de Containerd/Kubeadm, y despliegue inicial de Calico CNI.
* **`05-induce-throttling.sh`:** Script que instala y ejecuta `stress-ng` (para forzar el consumo de créditos AWS) y `sysstat` (para monitorear el robo de ciclos del hipervisor mediante `mpstat`).
* **`06-toggle-routing.sh`:** (NUEVO) Script para alternar dinámicamente el Datapath de Calico, parcheando el recurso `IPPool` para encender la red Overlay (`ipipMode: Always`) o apagarla para usar el Enrutamiento Nativo de la VPC (`ipipMode: Never`).

### /manifests (Laboratorio UDP)

* **`iperf3-server.yaml` e `iperf3-client.yaml`:** Manifiestos que instancian los contenedores de medición. Utilizan anulaciones de `nodeName` para evadir al Scheduler y asegurar el tráfico inter-nodo.

---

## Metodología de Ejecución (El Experimento)

Una vez inicializado el clúster, el experimento evalúa el Jitter y la pérdida de paquetes UDP bajo tres estados distintos de procesamiento:

### Fase 1: Línea Base (Red Sana / 100% Créditos)

Se inyecta tráfico con la red Overlay apagada y encendida en condiciones óptimas:

```bash
kubectl exec -it iperf3-client -- iperf3 -c 192.168.1.5 -u -b 100M -t 10
```

*(El Jitter se mantiene por debajo de 0.05 ms con 0% de pérdida, el encapsulamiento no presenta sobrecarga notable)*.

### Fase 2: Estrangulamiento en Espacio de Usuario (Kubernetes CFS)

Se limita el Pod cliente mediante cuotas nativas de K8s y se repite la prueba sobre el túnel IP-in-IP:

```bash
kubectl set resources pod iperf3-client --limits=cpu=100m
kubectl exec -it iperf3-client -- iperf3 -c 192.168.1.5 -u -b 100M -t 10
```

*(La red se mantiene estable. Demuestra que CFS asfixia a la aplicación, pero deja libre el procesamiento `softirq` del kernel)*.

### Fase 3: Estrangulamiento de Hipervisor (AWS Credits = 0)

Se retiran los límites de Kubernetes y se agotan los créditos físicos del anfitrión:

```bash
bash scripts/05-induce-throttling.sh
```

Una vez asfixiada la instancia, se comprueba el robo de ciclos (`%steal`) con `mpstat` y se repite la inyección de tráfico UDP alternando los modos de ruteo con el script `06`:

1. **Bajo Enrutamiento Nativo:** El Datapath sufre degradación moderada (~2% de pérdida).
2. **Bajo Calico IP-in-IP:** Colapso catastrófico del anillo de recepción (más del 16% de pérdida y Jitter disparado).

*(Conclusión: El esfuerzo matemático para desencapsular cabeceras IP-in-IP a nivel de kernel se vuelve insostenible cuando el proveedor cloud asfixia las interrupciones de red)*.
