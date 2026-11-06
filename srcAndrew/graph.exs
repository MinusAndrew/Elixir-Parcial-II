defmodule Graph do
  def build_graph(connections) do
    do_build_graph(connections, %{})
  end

  # Base case: no more connections
  defp do_build_graph([], graph), do: graph

  # Recursive case
  defp do_build_graph(
         [{:ok, %{connection: connection}} | rest],
         graph
       ) do
    %Connection{
      origin: origin,
      destination: destination,
      distance: distance
    } = connection

    # Insert origin -> destination
    graph =
      Map.update(
        graph,
        origin,
        [{destination, distance}],
        fn neighbors ->
          [{destination, distance} | neighbors]
        end
      )

    # Insert destination -> origin
    graph =
      Map.update(
        graph,
        destination,
        [{origin, distance}],
        fn neighbors ->
          [{origin, distance} | neighbors]
        end
      )

    # Continue recursively
    do_build_graph(rest, graph)
  end
end
