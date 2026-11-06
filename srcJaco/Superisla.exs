Code.require_file("Terreno.exs", __DIR__)

defmodule Ruta do
  defstruct [:posiciones, :costo]
end

defmodule Isla do
  @isla Path.join(__DIR__, "isla.txt")
  @validacion Path.join(__DIR__, "validacion_isla.txt")
  @rutas_csv Path.join(__DIR__, "rutas_isla.csv")
  @resumen Path.join(__DIR__, "resumen_isla.txt")
  def main do
    catalogo_terrenos = Terreno.main()

    case analizar_isla(@isla) do
      {:ok, filas} ->
        errores = validar_isla(filas, catalogo_terrenos)

        if errores != [] do
          mensaje = Enum.join(errores, "\n")
          File.write(@validacion, mensaje)
          IO.puts("Hay errores en el mapa de la isla. Ver #{@validacion}")
        else
          {mapa_coordenadas, dimensiones} = crear_mapa_coordenadas(filas)
          pos_inicio = encontrar_posicion(mapa_coordenadas, "P")
          pos_bote = encontrar_posicion(mapa_coordenadas, "B")

          rutas =
            buscar_rutas(
              pos_inicio,
              pos_bote,
              mapa_coordenadas,
              catalogo_terrenos,
              [pos_inicio],
              [],
              0
            )

          procesar_resultados(rutas, mapa_coordenadas, dimensiones)
        end

      {:error, razon} ->
        IO.puts("Error al leer el archivo de la isla: #{razon}")
    end
  end

  defp analizar_isla(isla) do
    if File.exists?(isla) do
      filas =
        isla
        |> File.stream!()
        |> Stream.map(&String.trim/1)
        |> Stream.reject(&(&1 == ""))
        |> Enum.map(fn linea -> String.split(linea, ~r/\s+/, trim: true) end)

      {:ok, filas}
    else
      {:error, "No existe el archivo"}
    end
  end

  defp crear_mapa_coordenadas(filas) do
    mapa =
      filas
      |> Enum.with_index()
      |> Enum.flat_map(fn {fila, y} ->
        fila
        |> Enum.with_index()
        |> Enum.map(fn {simbolo, x} -> {{y, x}, simbolo} end)
      end)
      |> Enum.into(%{})

    num_filas = length(filas)
    num_columnas = length(hd(filas))
    {mapa, {num_filas, num_columnas}}
  end

  defp encontrar_posicion(mapa, simbolo_objetivo) do
    Enum.find_value(mapa, fn {coord, simbolo} ->
      if simbolo == simbolo_objetivo, do: coord
    end)
  end

  defp validar_isla(filas, catalogo) do
    {mapa, {total_filas, total_cols}} = crear_mapa_coordenadas(filas)

    errores_filas = validar_filas_uniformes(filas)
    errores_simbolos = validar_simbolos_existentes(mapa, catalogo)
    errores_puntos = validar_puntos_clave(mapa)
    errores_borde = validar_borde_agua(mapa, total_filas, total_cols)

    errores_filas ++ errores_simbolos ++ errores_puntos ++ errores_borde
  end

  # VALIDAR FILAS UNIFORMES
  defp validar_filas_uniformes([primera | resto]) do
    longitud_esperada = length(primera)
    verificar_longitud_filas(resto, longitud_esperada, 1)
  end

  defp verificar_longitud_filas([], _esperada, _numero_fila), do: []

  defp verificar_longitud_filas([fila | resto], esperada, numero_fila) do
    longitud = length(fila)

    if longitud == esperada do
      verificar_longitud_filas(resto, esperada, numero_fila + 1)
    else
      error = "Fila #{numero_fila}: tiene #{longitud} posiciones; se esperaban #{esperada}"
      [error | verificar_longitud_filas(resto, esperada, numero_fila + 1)]
    end
  end

  # VALIDAR TODOS LOS SIMBOLOS APARECEN
  defp validar_simbolos_existentes(mapa, catalogo) do
    Enum.flat_map(mapa, fn {{y, x}, simbolo} ->
      if Map.has_key?(catalogo, simbolo) do
        []
      else
        ["Posición {#{y},#{x}}: el símbolo #{simbolo} no aparece en terrenos.csv"]
      end
    end)
  end

  # SOLO 1 PUNTO INICIAL Y 1 BOTE
  defp validar_puntos_clave(mapa) do
    posiciones_p =
      Enum.filter(mapa, fn {_, s} -> s == "P" end)
      |> Enum.map(&elem(&1, 0))

    posiciones_b =
      Enum.filter(mapa, fn {_, s} -> s == "B" end)
      |> Enum.map(&elem(&1, 0))

    errores_p =
      case length(posiciones_p) do
        1 -> []
        n -> ["Hay #{n} posiciones iniciales P: #{formatear_coordenadas(posiciones_p)}"]
      end

    errores_b =
      case length(posiciones_b) do
        1 -> []
        n -> ["Hay #{n} posiciones de bote B: #{formatear_coordenadas(posiciones_b)}"]
      end

    errores_p ++ errores_b
  end

  defp formatear_coordenadas(coordenadas) do
    coordenadas
    |> Enum.map(fn {y, x} -> "{#{y},#{x}}" end)
    |> Enum.join(" y ")
  end

  # TODO EL BORDE ES AGUA
  defp validar_borde_agua(mapa, total_filas, total_columnas) do
    Enum.flat_map(mapa, fn {{y, x}, simbolo} ->
      es_borde = y == 0 or y == total_filas - 1 or x == 0 or x == total_columnas - 1

      if es_borde and simbolo != "~" do
        ["Posición {#{y},#{x}}: el borde debe ser agua y contiene #{simbolo}"]
      else
        []
      end
    end)
  end

  # odio con toda mi alma estas funciones
  defp buscar_rutas(
         pos_actual,
         pos_bote,
         _mapa,
         _catalogo,
         _visitados,
         camino_invertido,
         costo_total
       )
       when pos_actual == pos_bote do
    ruta_completa = Enum.reverse([pos_actual | camino_invertido])
    [%Ruta{posiciones: ruta_completa, costo: costo_total}]
  end

  defp buscar_rutas(
         pos_actual,
         pos_bote,
         mapa,
         catalogo,
         visitados,
         camino_invertido,
         costo_acumulado
       ) do
    {y, x} = pos_actual

    vecinos = [
      # arriba
      {y - 1, x},
      # abajo
      {y + 1, x},
      # izquierda
      {y, x - 1},
      # derecha
      {y, x + 1}
    ]

    Enum.flat_map(vecinos, fn vecino ->
      if vecino not in visitados and Map.has_key?(mapa, vecino) do
        simbolo = Map.get(mapa, vecino)
        terreno = Map.get(catalogo, simbolo)

        case terreno do
          %Terreno{transitable: true, costo: costo_paso} ->
            buscar_rutas(
              vecino,
              pos_bote,
              mapa,
              catalogo,
              [vecino | visitados],
              [pos_actual | camino_invertido],
              costo_acumulado + costo_paso
            )

          %Terreno{transitable: false, costo: _} ->
            []
        end
      else
        []
      end
    end)
  end

  defp procesar_resultados(rutas, mapa, dimensiones) do
    # reporte
    total_rutas = length(rutas)
    ruta_mas_corta = Enum.min_by(rutas, fn r -> length(r.posiciones) end)
    minimo_movimientos = length(ruta_mas_corta.posiciones) - 1
    ruta_menor_costo = Enum.min_by(rutas, fn r -> r.costo end)
    movs_menor_costo = length(ruta_menor_costo.posiciones) - 1
    # cosos de la terminal
    IO.puts("Número total de rutas: #{total_rutas}")
    IO.puts("Ruta más corta: #{minimo_movimientos} movimientos")

    IO.puts(
      "Ruta de menor costo: costo #{ruta_menor_costo.costo} (#{movs_menor_costo} movimientos)"
    )

    # archivo csv
    generar_csv(rutas, @rutas_csv)
    # resumen del reporte
    generar_resumen(
      total_rutas,
      minimo_movimientos,
      ruta_menor_costo,
      movs_menor_costo,
      mapa,
      dimensiones,
      @resumen
    )
  end

  defp formato_recorrido(posiciones) do
    posiciones
    |> Enum.map(fn {y, x} -> "{#{y},#{x}}" end)
    |> Enum.join(" -> ")
  end

  defp generar_csv(rutas, ruta_archivo) do
    encabezado = "ruta ;movimientos ;costo ;recorrido\n"

    lineas =
      rutas
      |> Enum.with_index(1)
      |> Enum.map(fn {ruta, i} ->
        movs = length(ruta.posiciones) - 1
        recorrido = formato_recorrido(ruta.posiciones)
        "#{i} ;#{movs} ;#{ruta.costo} ;#{recorrido}"
      end)
      |> Enum.join("\n")

    File.write(ruta_archivo, encabezado <> lineas)
  end

  defp generar_resumen(
         total,
         min_movs,
         menor_costo_ruta,
         movs_mejor,
         mapa,
         {filas, cols},
         ruta_archivo
       ) do
    mapa_con_asteriscos =
      Enum.reduce(menor_costo_ruta.posiciones, mapa, fn coord, acc ->
        Map.put(acc, coord, "*")
      end)

    dibujo_mapa =
      0..(filas - 1)
      |> Enum.map(fn y ->
        0..(cols - 1)
        |> Enum.map(fn x -> Map.get(mapa_con_asteriscos, {y, x}) end)
        |> Enum.join(" ")
      end)
      |> Enum.join("\n")

    contenido = """
    Número total de rutas: #{total}
    Ruta más corta: #{min_movs} movimientos
    Ruta de menor costo: costo #{menor_costo_ruta.costo} (#{movs_mejor} movimientos)
    Mapa con la ruta de menor costo marcada:
    #{dibujo_mapa}
    """

    File.write!(ruta_archivo, contenido)
  end
end

Isla.main()
