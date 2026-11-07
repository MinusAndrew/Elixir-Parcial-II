#!/bin/sh

# Limpiar archivos .beam compilados previamente para evitar conflictos
rm -f *.beam

# Compilar dependencias y ejecutar el script principal
elixirc Terreno.exs
elixir Superisla.exs
