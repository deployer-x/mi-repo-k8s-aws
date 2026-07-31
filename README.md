# Análisis de Degradación en el Datapath: Impacto del CPU Throttling (AWS vs. CFS) sobre Redes Overlay IP-in-IP y Enrutamiento Nativo en Kubernetes

Evaluación empírica de la degradación del datapath y latencia de cola (P99) en tráfico UDP bajo estrangulamiento de CPU a nivel de contenedor vs. hipervisor.

## Overview

Desplegar arquitecturas de microservicios en la nube pública requiere equilibrar costos y rendimiento, siendo una práctica común el uso de instancias *burstable* (ej. familia T2 de AWS). El problema técnico fundamental abordado en este proyecto radica en la mecánica interna de procesamiento de paquetes del kernel de Linux. Existen dos mecanismos de estrangulamiento distintos: las cuotas de Kubernetes (CFS) que asfixian el espacio de usuario, y el agotamiento de "créditos de CPU" de AWS, que asfixia a la máquina virtual completa, afectando al hilo `ksoftirqd` (encargado de procesar las interrupciones de red). 

Este proyecto aísla y cuantifica la degradación temporal (Jitter y Latencia P99) que sufren los datagramas UDP al atravesar un túnel encapsulado IP-in-IP (Calico) frente a un enrutamiento nativo, precisamente en el instante en que el hipervisor asfixia el entorno físico.

## Research Question

¿En qué medida el agotamiento de créditos de CPU de una instancia burstable en modo Standard degrada el jitter, la pérdida y el P99 del retardo por datagrama del tráfico UDP entre pods inter-nodo, y cuánto de esa degradación es atribuible específicamente al encapsulamiento Calico IP-in-IP frente a routing nativo?

> **RQ:** What is the empirical penalty of IP-in-IP encapsulation on UDP tail latency (P99) and packet loss when the underlying hypervisor enforces CPU throttling on the host's `ksoftirqd` threads?

## Main Contributions

- Demostración empírica del colapso del anillo de recepción del kernel (RX Ring) provocado por la asfixia del hilo `ksoftirqd`, evidenciado a través de contadores nativos (`ethtool rx_dropped`).
- Cuantificación exacta de la penalización de latencia de cola (P99) y pérdida de paquetes introducida por el encapsulamiento overlay (Calico) frente al enrutamiento nativo bajo estrés físico.
- Validación de que el control de recursos nativo de Kubernetes (CFS) restringe a la aplicación en espacio de usuario, pero no degrada la capacidad del Host para procesar y desencapsular paquetes de red.

## Research Area

- Computing Systems and Infrastructure
- Computer Networks and Distributed Systems

## Repository Structure

```text
.
├── experiments/      Manifiestos YAML (iperf3 client/server)
├── paper/            Documento final del proyecto (PDF/Docx)
├── results/          Reportes JSON de latencia extraídos de iperf3
├── scripts/          Scripts Bash de aprovisionamiento, estrés y toggle de CNI
└── README.md         Documentación principal
```

## Requirements

```text
Operating system: Ubuntu Server 22.04 LTS (Swap deshabilitado)
Programming language: Bash
Main dependencies: Containerd, Kubeadm/Kubelet/Kubectl (v1.29), Calico CNI (v3.27), stress-ng, sysstat (mpstat), iperf3.
Hardware requirements: 3 instancias AWS EC2 t2.medium (Burstable, 2 vCPUs, 4 GiB RAM) en us-east-1.
```

## Installation

```bash
git clone https://github.com/core-lab-ungs/aws-kubernetes-udp-overlay-benchmark.git
cd aws-kubernetes-udp-overlay-benchmark

# Ejecutar en todos los nodos (Master y Workers)
bash scripts/01-prepare-os.sh
bash scripts/02-install-containerd.sh
bash scripts/03-install-k8s-tools.sh

# Inicializar clúster (kubeadm init) y desplegar red
bash scripts/04-install-calico.sh
```

## Reproduction

Para reproducir el experimento de asfixia del hipervisor:

1. Desplegar los inyectores de tráfico en workers distintos:
```bash
kubectl apply -f experiments/iperf3-server.yaml
kubectl apply -f experiments/iperf3-client.yaml
```
2. Inducir el agotamiento de créditos en el Host objetivo:
```bash
bash scripts/05-induce-throttling.sh
```
3. Alternar la arquitectura de red e iniciar medición:
```bash
bash scripts/06-toggle-routing.sh [overlay|nativo]
kubectl exec -it iperf3-client -- iperf3 -c 192.168.1.5 -u -b 100M -t 300 -l 1400 --json > results/report.json
```

**Condiciones de reproducción:**
1. **Required input data:** No aplica. El tráfico es sintético generado on-the-fly.
2. **Configuration used:** MTU fijado a 1400 bytes para evitar fragmentación de IP. Flujo UDP de 100 Mbps constante.
3. **Random seeds:** No aplica.
4. **Expected output files:** Archivos JSON generados por `iperf3` con métricas de transferencia por segundo y salidas de consola de `ethtool`.
5. **Approximate execution time:** 45 minutos para inducir el estado Throttled con `stress-ng`, más 5 minutos (`-t 300`) por cada iteración de inyección de red.

## Dataset

No aplica para este proyecto. Todo el tráfico evaluado es generado de manera sintética en tiempo real a través de inyectores de red (`iperf3`). No existen restricciones de licencia, datos personales ni requisitos de anonimización.

## Results

Los resultados demuestran que bajo asfixia de AWS, el kernel carece de ciclos para procesar el encabezado extra de la red overlay.

| Experiment | Metric | Result |
|---|---:|---:|
| Enrutamiento Nativo (AWS Throttled) | Latencia de Cola (P99) | 15.4 ms |
| Enrutamiento Nativo (AWS Throttled) | Packet Loss | 2.1% |
| Calico IP-in-IP (AWS Throttled) | Latencia de Cola (P99) | **89.2 ms** |
| Calico IP-in-IP (AWS Throttled) | Packet Loss | **16.8%** |

*(Nota: Los promedios fueron calculados a partir de 10 iteraciones de 300 segundos).*

## Limitations

El diseño experimental de esta investigación se limitó exclusivamente a instancias *burstable* con arquitectura x86 (familia T2 de AWS). Queda como trabajo futuro replicar el laboratorio utilizando instancias basadas en arquitecturas ARM (AWS Graviton) o familias *burstable* de otros proveedores (como Azure B-Series) para aislar particularidades propias de la capa de virtualización de Amazon.

## Authors and Contributions

| Contributor | Contribution |
|---|---|
| Franco León Costantini | Software, investigation, experiments, analysis, writing. (Autor Principal) |
| Benjamín Chuquimango | Academic supervision, analysis, reviewing. (Coautor y Director) |

## Academic Provenance

This project originated within the academic activities of **Sistemas Operativos y Redes 2** at Universidad Nacional de General Sarmiento (Primer Semestre, 2026) and was curated as a research or software artifact by **CORE Lab UNGS**.

## Project Status

Current status: **Under academic review**

## Citation

Citation information will be provided through the repository's `CITATION.cff` file.

## License

No se especifica licencia durante el proceso de revisión académica. 

## Contact

For questions about this project, open an issue in this repository or contact the project maintainers identified above.