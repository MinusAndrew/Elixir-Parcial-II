# Parcial II — Programación Funcional (Elixir)

Este repositorio contiene las soluciones desarrolladas en **Elixir** para el Segundo Parcial. El proyecto está dividido en dos módulos independientes:

---

## 📁 Estructura del Proyecto

### 1. `srcAndrew/` — Rutas entre Ciudades
Modelado de una red de transporte mediante un grafo no dirigido ponderado.
- **Entradas**: `test.csv` (conexiones entre ciudades) y `consultas.txt` (origen, destino).
- **Funcionalidades**:
  - Limpieza, validación y descarte de conexiones duplicadas o inconsistentes.
  - Verificación de alcanzabilidad mediante secuencias perezosas (`Stream.iterate/2`).
  - Búsqueda de todas las rutas posibles mediante DFS con backtracking.
  - Identificación de rutas con menor distancia y menor número de ciudades visitadas.
- **Salidas**: `rutas_encontradas.txt`, `alcance.txt`, `errores_conexiones.txt`, `depuracion_conexiones.txt`.

### 2. `srcJaco/` — Superisla
Navegación y escape en una cuadrícula 2D con diferentes tipos de terreno.
- **Entradas**: `terrenos.csv` (catálogo de terrenos y costos) e `isla.txt` (matriz del mapa).
- **Funcionalidades**:
  - Validación estructural del mapa (perímetro de agua, símbolos válidos, puntos `P` y `B` únicos).
  - Búsqueda exhaustiva de rutas transitables desde el punto inicial (`P`) hasta el bote (`B`).
  - Cálculo de movimientos y costo total acumulado por ruta.
- **Salidas**: `rutas_isla.csv` y `resumen_isla.txt` (con el mapa y la mejor ruta marcada).

---

## 🚀 Cómo Ejecutar

Cada carpeta incluye su propio script `run.sh` para compilar y ejecutar todo automáticamente:

### Ejecutar Rutas entre Ciudades (`srcAndrew`):
```bash
cd srcAndrew
./run.sh
```

### Ejecutar Superisla (`srcJaco`):
```bash
cd srcJaco
./run.sh
```

---

## 🛠️ Requisitos
- **Elixir** (1.14 o superior).
