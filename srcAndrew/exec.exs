defmodule Exec do
  @connections_file Path.join(__DIR__, "conexiones.csv")
  @consultations_file Path.join(__DIR__, "consultas.txt")
  @error_report Path.join(__DIR__, "errores_conexiones.txt")
  @debug_report Path.join(__DIR__, "depuracion_conexiones.txt")
  @routes_report Path.join(__DIR__, "rutas_encontradas.txt")
  @reach_report Path.join(__DIR__, "alcance.txt")

  def run do
    IO.puts("=== Rutas entre Ciudades ===\n")

    # Step 1: Load and process connections
    case process_connections() do
      {:error, reason} ->
        IO.puts("Error: #{reason}")

      {:ok, graph} ->
        # Step 2: Load and process consultations
        case process_consultations(graph) do
          {:error, reason} ->
            IO.puts("Error: #{reason}")

          {:ok, results} ->
            # Step 3: Generate route report
            report = Output.route_report(results)
            Connection.write_file(@routes_report, report, "Rutas")
            IO.puts("\nEjecución completada.")
        end
    end
  end

  # ---- Connection Processing ----

  defp process_connections do
    case Connection.read_file(@connections_file) do
      {:error, :file_not_found} ->
        {:error, "Archivo de conexiones no encontrado: #{@connections_file}"}

      raw_data ->
        # Write error report for malformed CSV lines
        errors = Connection.csv_error_catcher(raw_data)
        error_report = Output.csv_error_report(errors)
        Connection.write_file(@error_report, error_report, "Errores Conexiones")

        # Clean data (remove errors and ignored lines)
        clean_data = Connection.csv_cleaner(raw_data)

        # Filter connections (remove duplicates, self-connections, etc.)
        {accepted, discarded} = Connection.filter_connections(clean_data)

        # Write debug report for discarded connections
        debug_report = Validation.connection_error_findings(discarded)
        Connection.write_file(@debug_report, debug_report, "Depuración Conexiones")

        IO.puts("Conexiones aceptadas: #{length(accepted)}")
        IO.puts("Conexiones descartadas: #{length(discarded)}")

        # Build adjacency graph
        graph = Graph.build_graph(accepted)
        {:ok, graph}
    end
  end

  # ---- Consultation Processing ----

  defp process_consultations(graph) do
    if File.exists?(@consultations_file) do
      consultations = read_consultations(@consultations_file)

      # Truncate alcance.txt at the start of every execution
      File.write!(
        @reach_report,
        "Reporte de Alcanzabilidad, Generado el #{Tool.current_date()}\n\n"
      )

      results =
        consultations
        |> Enum.map(fn consultation ->
          process_single_consultation(consultation, graph)
        end)

      {:ok, results}
    else
      {:error, "Archivo de consultas no encontrado: #{@consultations_file}"}
    end
  end

  defp read_consultations(path) do
    File.stream!(path)
    |> Stream.with_index(1)
    |> Enum.reduce([], fn {line, line_number}, acc ->
      case parse_consultation(line, line_number) do
        {:ok, origin, destination} ->
          [{origin, destination} | acc]

        {:ignored, _reason} ->
          acc

        {:error, reason} ->
          IO.puts("  Advertencia consulta línea #{line_number}: #{reason}")
          acc
      end
    end)
    |> Tool.reverse()
  end

  defp parse_consultation(line, _line_number) do
    trimmed = String.trim(line)

    cond do
      trimmed == "" ->
        {:ignored, :blank_line}

      String.starts_with?(trimmed, "#") ->
        {:ignored, :commented_line}

      true ->
        parts = String.split(trimmed, ",", parts: 2)

        case parts do
          [origin, destination] ->
            origin = String.trim(origin)
            destination = String.trim(destination)

            cond do
              origin == "" ->
                {:error, "Origen vacío: #{trimmed}"}

              destination == "" ->
                {:error, "Destino vacío: #{trimmed}"}

              true ->
                {:ok, origin, destination}
            end

          [_single] ->
            {:error, "Formato inválido (falta destino): #{trimmed}"}

          _ ->
            {:error, "Formato inesperado: #{trimmed}"}
        end
    end
  end

  defp process_single_consultation({origin, destination}, graph) do
    IO.puts("\nProcesando consulta: #{origin} -> #{destination}")

    # Step 1: Reachability check
    header = "--- Consulta: #{origin} -> #{destination} ---\n"

    case Reach.check(graph, origin, destination,
           path: @reach_report,
           mode: :append,
           header: header
         ) do
      {:ok, true} ->
        IO.puts("  #{destination} es alcanzable desde #{origin}. Ejecutando DFS...")

        # Step 2: DFS search
        routes = Search.find_routes(graph, origin, destination)

        # Step 3: Analyze routes
        case RoutePath.analyze(routes) do
          {:error, msg} ->
            IO.puts("  #{msg}")
            {origin, destination, {:error, msg}}

          analysis ->
            IO.puts("  Rutas encontradas: #{analysis.total_routes}")
            {origin, destination, {:ok, routes, analysis}}
        end

      {:ok, false} ->
        IO.puts("  #{destination} NO es alcanzable desde #{origin}. Se omite la búsqueda.")
        {origin, destination, :unreachable}

      {:error, reason} ->
        IO.puts("  Error en verificación de alcanzabilidad: #{inspect(reason)}")
        {origin, destination, {:error, "Error de alcanzabilidad: #{inspect(reason)}"}}
    end
  end
end

Exec.run()
