defmodule Validation do
  def connection_error_findings(discarded_connections) do
    discarded_report =
      discarded_connections
      |> Enum.map(fn {{:ok, inside_content}, reason} ->
        case reason do
          :self_connection ->
            "Line #{inside_content.line}: #{inside_content.content} -> it connects itself, will be discarded"

          {:different_distance, matched_line, matched_distance} ->
            "Line #{inside_content.line}: different distance found compared to the one in line #{matched_line} (#{matched_distance}); line #{matched_line} will be conserved"

          {:repeated, matched_line} ->
            "Line #{inside_content.line}: repeated (Line #{matched_line}), discarded"
        end
      end)
      |> Enum.join("\n")

    """
    Lines filtered, Generated as of #{Tool.current_date()}:
    #{discarded_report}
    """
  end
end
