defmodule Tool do
  def current_date do
    DateTime.utc_now()
    # Our Offset
    |> DateTime.add(-5 * 60 * 60, :second)
    |> Calendar.strftime("%A %d/%m/%Y %H:%M:%S")
  end

  def reverse(list) do
    reverse(list, [])
  end

  def reverse([], acc), do: acc

  def reverse([head | tail], acc) do
    reverse(tail, [head | acc])
  end
end
