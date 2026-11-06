defmodule Connection do
  @enforce_keys [:origin, :destination, :distance]
  defstruct origin: "", destination: "", distance: 0

  def read_file(path) do
    if File.exists?(path) do
      File.stream!(path)
      |> Stream.with_index(1)
      |> Enum.map(fn {line, line_number} ->
        csv_parser(line, line_number)
      end)
    else
      {:error, :file_not_found}
    end
  end

  def write_file(path, content, custom_str_type) do
    case File.write(path, content) do
      :ok -> IO.puts("#{custom_str_type} File Written at #{path}")
      {:error, cause} -> IO.inspect(cause, label: "Can't Write file, cause: ")
    end
  end

  defp csv_parser(line, line_number) do
    trimmed = String.trim(line)

    cond do
      trimmed == "" ->
        {:ignored, :blank_line}

      String.starts_with?(trimmed, "#") ->
        {:ignored, :commented_line}

      true ->
        case parse_csv_line(line) do
          [origin, destination, distance] ->
            cond do
              origin == "" ->
                {:error, "Empty Origin at line #{line_number}, Content: #{trimmed}"}

              destination == "" ->
                {:error, "Empty Destination at line #{line_number}, Content: #{trimmed}"}

              true ->
                case Float.parse(distance) do
                  {distance, _} when distance >= 0 ->
                    {:ok,
                     %{
                       line: line_number,
                       content: trimmed,
                       connection: %Connection{
                         origin: origin,
                         destination: destination,
                         distance: distance
                       }
                     }}

                  {distance, _} when distance < 0 ->
                    {:error, "Negative distance at line #{line_number}, Content: #{trimmed}"}

                  :error ->
                    {:error, "Not a number at line #{line_number}, Content: #{trimmed}"}

                  _ ->
                    {:error, "Unexpected row format at line #{line_number}, Content: #{trimmed}"}
                end
            end

          _ ->
            {:error, "Unexpected row format at #{line_number}, Content: #{trimmed}"}
        end
    end
  end

  # Kinda interesting algorithm that uses recursion to transverse the line.
  defp parse_csv_line(line) do
    line |> String.trim() |> do_parse([], "")
  end

  # Ends when is empty, we reverse our tokens
  defp do_parse("", fields, current),
    do: Enum.reverse([current | fields])

  # When we find a coma, we break into the next field in the CSV, we have our current text to add
  # into the acc then remove the comma and reset the current with an empty string to the next token
  defp do_parse(<<",", rest::binary>>, fields, current),
    do: do_parse(rest, [current | fields], "")

  # General case, when we find a normal character we just append it and we follow with the next one
  defp do_parse(<<c::utf8, rest::binary>>, fields, current),
    do: do_parse(rest, fields, current <> <<c::utf8>>)

  def csv_error_catcher(map_file) do
    Enum.reduce(map_file, [], fn
      {:error, content}, errors -> [content | errors]
      _, errors -> errors
    end)
    |> Enum.reverse()
  end

  def csv_cleaner(map_file) do
    Enum.reject(map_file, fn
      {:error, _} -> true
      {:ignored, _} -> true
      _ -> false
    end)
  end

  defp search_pair(_connection, []) do
    :none
  end

  defp search_pair(connection, [{:ok, current} | remaining]) do
    same_way =
      connection.origin == current.connection.origin and
        connection.destination == current.connection.destination

    opposite_way =
      connection.origin == current.connection.destination and
        connection.destination == current.connection.origin

    if same_way or opposite_way do
      current
    else
      search_pair(connection, remaining)
    end
  end

  def filter_connections(connections) do
    filter_connections(connections, [], [])
  end

  # base case
  def filter_connections([], accepted, discarded) do
    {Tool.reverse(accepted), Tool.reverse(discarded)}
  end

  def filter_connections([current | remaining], accepted, discarded) do
    {:ok, our_current_map} = current

    connection = our_current_map.connection

    cond do
      connection.origin == connection.destination ->
        reason = :self_connection
        filter_connections(remaining, accepted, [{current, reason} | discarded])

      true ->
        case search_pair(connection, accepted) do
          :none ->
            filter_connections(remaining, [current | accepted], discarded)

          # Filters repeted and different distances, the metadata in this duple is the line in which is matched
          # and the distance is which is different with the matched one
          matched ->
            reason =
              if connection.distance == matched.connection.distance do
                {:repeated, matched.line}
              else
                {:different_distance, matched.line, matched.connection.distance}
              end

            filter_connections(remaining, accepted, [{current, reason} | discarded])
        end
    end
  end
end
