defmodule Search do
  # Using DFS

  def find_routes(graph, origin, destination) do
    search_routes(
      origin,
      destination,
      graph,
      [origin],
      [origin],
      0
    )
  end

  # Base case: destination reached
  defp search_routes(
         current,
         destination,
         _graph,
         _visited,
         cities,
         distance
       )
       when current == destination do
    [
      %RoutePath{
        cities: Tool.reverse(cities),
        distance: distance
      }
    ]
  end

  # Recursive case
  defp search_routes(
         current,
         destination,
         graph,
         visited,
         cities,
         distance
       ) do
    neighbors = Map.get(graph, current, [])

    explore_neighbors(
      neighbors,
      destination,
      graph,
      visited,
      cities,
      distance
    )
  end

  # Base case: no more neighbors
  defp explore_neighbors(
         [],
         _destination,
         _graph,
         _visited,
         _cities,
         _distance
       ),
       do: []

  # Recursive case: explore each neighbor
  defp explore_neighbors(
         [{neighbor, road_distance} | rest],
         destination,
         graph,
         visited,
         cities,
         distance
       ) do
    if neighbor in visited do
      explore_neighbors(
        rest,
        destination,
        graph,
        visited,
        cities,
        distance
      )
    else
      routes_from_neighbor =
        search_routes(
          neighbor,
          destination,
          graph,
          [neighbor | visited],
          [neighbor | cities],
          distance + road_distance
        )

      routes_from_rest =
        explore_neighbors(
          rest,
          destination,
          graph,
          visited,
          cities,
          distance
        )

      routes_from_neighbor ++ routes_from_rest
    end
  end
end
