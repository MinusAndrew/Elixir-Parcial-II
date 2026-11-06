defmodule Output do
  def csv_error_report(list_of_errors) do
    errors_found = Enum.join(list_of_errors, "\n")

    """
    Errors Found in CSV File, Generated as of #{Tool.current_date()}:
    #{errors_found}
    """
  end

  def route_report(consultation_results) do
    separator = String.duplicate("=", 60)
    header = "Reporte de Rutas Encontradas, Generado el #{Tool.current_date()}\n"

    body =
      consultation_results
      |> Enum.map(fn result -> format_consultation(result, separator) end)
      |> Enum.join("")

    header <> separator <> "\n" <> body
  end

  defp format_consultation({origin, destination, :unreachable}, separator) do
    """

    Consulta: #{origin} -> #{destination}

      #{destination} no es alcanzable desde #{origin}.
      No se ejecuta búsqueda de rutas.

    #{separator}
    """
  end

  defp format_consultation({origin, destination, {:ok, routes, analysis}}, separator) do
    routes_text =
      routes
      |> Enum.with_index(1)
      |> Enum.map(fn {route, index} ->
        cities_str = Enum.join(route.cities, " -> ")
        num_cities = length(route.cities)

        "  Ruta #{index}: #{cities_str}\n" <>
          "    Ciudades visitadas: #{num_cities}\n" <>
          "    Distancia total: #{route.distance} km\n"
      end)
      |> Enum.join("\n")

    shortest_text = format_route_list("Ruta(s) con menos ciudades", analysis.shortest_routes)
    lowest_text = format_route_list("Ruta(s) con menor distancia", analysis.lowest_distance_routes)

    """

    Consulta: #{origin} -> #{destination}

    #{routes_text}
      Total de rutas encontradas: #{analysis.total_routes}
      #{shortest_text}
      #{lowest_text}

    #{separator}
    """
  end

  defp format_consultation({origin, destination, {:error, msg}}, separator) do
    """

    Consulta: #{origin} -> #{destination}

      #{msg}

    #{separator}
    """
  end

  defp format_route_list(label, routes) do
    routes_str =
      routes
      |> Enum.map(fn route ->
        cities_str = Enum.join(route.cities, " -> ")
        "(#{cities_str}, #{route.distance} km, #{length(route.cities)} ciudades)"
      end)
      |> Enum.join(", ")

    "#{label}: #{routes_str}"
  end
end
