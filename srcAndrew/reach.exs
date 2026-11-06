defmodule Reach do
  # Public function: checks whether destination is reachable from origin.
  # opts: [path: "alcance.txt", mode: :write, header: ""]
  def check(graph, origin, destination, opts \\ []) do
    output_path = Keyword.get(opts, :path, Path.join(".", "alcance.txt"))
    mode = Keyword.get(opts, :mode, :write)
    header = Keyword.get(opts, :header, "")

    case File.open(output_path, [mode], fn file ->
           if header != "", do: IO.write(file, header)

           reachable_stream(graph, origin)
           |> Stream.with_index()
           |> Enum.reduce_while(nil, fn {current_set, iteration}, previous_set ->
             IO.write(file, format_iteration(iteration, current_set))

             if previous_set != nil and MapSet.equal?(previous_set, current_set) do
               IO.write(file, "Conjunto estable alcanzado en iteración #{iteration}.\n\n")
               {:halt, current_set}
             else
               {:cont, current_set}
             end
           end)
         end) do
      {:ok, final_set} ->
        {:ok, MapSet.member?(final_set, destination)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Expands the current set with all direct neighbors.
  defp expand_reachable(graph, current_set) do
    Enum.reduce(current_set, current_set, fn city, reachable ->
      neighbors = Map.get(graph, city, [])

      Enum.reduce(neighbors, reachable, fn {neighbor, _distance}, acc ->
        MapSet.put(acc, neighbor)
      end)
    end)
  end

  # Generates an infinite lazy sequence of reachable sets.
  defp reachable_stream(graph, origin) do
    Stream.iterate(MapSet.new([origin]), fn current_set ->
      expand_reachable(graph, current_set)
    end)
  end

  # Formats one iteration for the output file.
  defp format_iteration(iteration, reachable_set) do
    cities =
      reachable_set
      |> Enum.sort()
      |> Enum.join(", ")

    "Iteración #{iteration}: #{cities}\n"
  end
end
