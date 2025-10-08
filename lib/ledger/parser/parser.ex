defmodule Ledger.Parser.Parser do
  def parser_args([]), do: {:error, :invalid_subcommand}

  # === USUARIOS ===
  def parser_args(["crear_usuario" | flags]),
    do: wrap_command(:crear_usuario, parse_usuario_flags(flags))

  def parser_args(["editar_usuario" | flags]),
    do: wrap_command(:editar_usuario, parse_editar_usuario_flags(flags))

  def parser_args(["borrar_usuario" | flags]),
    do: wrap_command(:borrar_usuario, parse_id_flag(flags))

  def parser_args(["ver_usuario" | flags]),
    do: wrap_command(:ver_usuario, parse_id_flag(flags))

  # === MONEDAS ===
  def parser_args(["crear_moneda" | flags]),
    do: wrap_command(:crear_moneda, parse_moneda_flags(flags))

  def parser_args(["editar_moneda" | flags]),
    do: wrap_command(:editar_moneda, parse_editar_moneda_flags(flags))

  def parser_args(["borrar_moneda" | flags]),
    do: wrap_command(:borrar_moneda, parse_id_flag(flags))

  def parser_args(["ver_moneda" | flags]),
    do: wrap_command(:ver_moneda, parse_id_flag(flags))

  # === CUENTAS / TRANSACCIONES ===
  def parser_args(["alta_cuenta" | flags]),
    do: wrap_command(:alta_cuenta, parse_alta_cuenta_flags(flags))

  def parser_args(["realizar_transferencia" | flags]),
    do: wrap_command(:realizar_transferencia, parse_transferencia_flags(flags))

  def parser_args(["realizar_swap" | flags]),
    do: wrap_command(:realizar_swap, parse_swap_flags(flags))

  def parser_args(["deshacer_transaccion" | flags]),
    do: wrap_command(:deshacer_transaccion, parse_id_flag(flags))

  def parser_args(["ver_transaccion" | flags]),
    do: wrap_command(:ver_transaccion, parse_id_flag(flags))

  def parser_args(_), do: {:error, :invalid_subcommand}

  # === HELPERS ===

  defp wrap_command(command, {:ok, map}), do: {command, {:ok, map}}
  defp wrap_command(_command, {:error, reason}), do: {:error, reason}

  # === PARSEOS ===

  defp parse_usuario_flags(flags) do
    required = [:nombre, :fecha_nacimiento]

    case parse_flags(flags, %{"-n" => :nombre, "-b" => :fecha_nacimiento}) do
      {:ok, map} ->
        missing = Enum.filter(required, fn key -> !Map.has_key?(map, key) end)
        if missing == [], do: {:ok, map}, else: {:error, {:missing_flags, missing}}

      error ->
        error
    end
  end

  defp parse_editar_usuario_flags(flags) do
    required = [:id, :nuevo_nombre]

    case parse_flags(flags, %{"-id" => :id, "-n" => :nuevo_nombre}) do
      {:ok, map} ->
        missing = Enum.filter(required, fn key -> !Map.has_key?(map, key) end)
        if missing == [], do: {:ok, map}, else: {:error, {:missing_flags, missing}}

      error ->
        error
    end
  end

  defp parse_moneda_flags(flags) do
    with {:ok, map} <- parse_flags(flags, %{"-n" => :nombre, "-p" => :precio}),
         {:ok, num} <- parse_precio(map) do
      {:ok, Map.put(map, :precio_usd, num)}
    else
      error -> error
    end
  end

  defp parse_precio(map) do
    case Map.fetch(map, :precio) do
      {:ok, valor} ->
        case Float.parse(valor) do
          {num, ""} -> {:ok, num}
          _ -> {:error, :precio_invalid}
        end

      :error ->
        {:ok, nil}
    end
  end

  defp parse_editar_moneda_flags(flags) do
    parse_flags(flags, %{
      "-id" => :id,
      "-p" => :nuevo_precio
    })
  end

  defp parse_alta_cuenta_flags(flags) do
    parse_flags(flags, %{
      "-u" => :id_usuario,
      "-m" => :id_moneda
    })
  end

  defp parse_transferencia_flags(flags) do
    parse_flags(flags, %{
      "-o" => :usuario_origen,
      "-d" => :usuario_destino,
      "-m" => :id_moneda,
      "-c" => :monto
    })
  end

  defp parse_swap_flags(flags) do
    parse_flags(flags, %{
      "-u" => :id_usuario,
      "-mo" => :moneda_origen,
      "-md" => :moneda_destino,
      "-c" => :monto
    })
  end

  defp parse_id_flag(flags) do
    parse_flags(flags, %{"-id" => :id})
  end

  # === PARSEO GENERAL ===
  defp parse_flags(flags, mapping) do
    Enum.reduce_while(flags, {:ok, %{}}, fn flag, {:ok, acc} ->
      case String.split(flag, "=", parts: 2) do
        [key, value] ->
          if Map.has_key?(mapping, key) do
            {:cont, {:ok, Map.put(acc, mapping[key], value)}}
          else
            {:halt, {:error, {:unknown_flag, flag}}}
          end

        _ ->
          {:halt, {:error, {:unknown_flag, flag}}}
      end
    end)
  end
end
