import json
import sys
import numpy as np

def calculate_p99(json_file):
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    # Extraer el jitter y latencias de los paquetes del reporte UDP
    # iperf3 guarda los intervalos en end -> streams
    intervals = data.get('intervals', [])
    jitters = [interval['sum']['jitter_ms'] for interval in intervals if 'sum' in interval]
    
    if not jitters:
        print("No se encontraron datos de latencia en el JSON.")
        return
        
    p99_latency = np.percentile(jitters, 99)
    print(f"Archivo: {json_file} | Latencia P99: {p99_latency:.3f} ms")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python3 calculate_p99.py <archivo_iperf3.json>")
    else:
        calculate_p99(sys.argv[1])