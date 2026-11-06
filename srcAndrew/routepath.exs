defmodule RoutePath do
  @enforce_keys [:cities, :distance]
  defstruct cities: [], distance: 0

  def analyze([]) do
    {:error, "No routes found"}
  end

  def analyze(routes) do
    # Total number of routes
    total_routes = length(routes)

    # Find minimum number of cities
    minimum_cities =
      routes
      |> Enum.map(fn route -> length(route.cities) end)
      |> Enum.min()

    # Get every route with the minimum number of cities
    shortest_routes =
      Enum.filter(routes, fn route ->
        length(route.cities) == minimum_cities
      end)

    # Find minimum accumulated distance
    minimum_distance =
      routes
      |> Enum.map(fn route -> route.distance end)
      |> Enum.min()

    # Get every route with the minimum distance
    lowest_distance_routes =
      Enum.filter(routes, fn route ->
        route.distance == minimum_distance
      end)

    %{
      total_routes: total_routes,
      shortest_routes: shortest_routes,
      lowest_distance_routes: lowest_distance_routes
    }
  end
end
