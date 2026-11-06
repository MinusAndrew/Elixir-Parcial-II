defmodule Terreno do
  @terrenos Path.join(__DIR__, "terrenos.csv")
  defstruct [:simbolo, :nombre, :transitable, :costo]

  def main do
    analizar(@terrenos)
  end

  defp analizar(terrenos) do
    if File.exists?(terrenos) do
      terrenos
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(fn linea -> linea == "" or String.starts_with?(linea, "#") end)
      |> Enum.map(&parsear_linea/1)
      |> Map.new(fn terreno -> {terreno.simbolo, terreno} end)
    else
      IO.puts("Error: No se encontró el archivo #{terrenos}")
      %{}
    end
  end

  defp parsear_linea(linea) do
    parametros =
      linea
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    nuevo_struct(parametros)
  end

  defp nuevo_struct([simbolo, nombre, transitable, costo]) do
    %Terreno{
      simbolo: simbolo,
      nombre: nombre,
      transitable: transitable == "si",
      costo: String.to_integer(costo)
    }
  end
end
