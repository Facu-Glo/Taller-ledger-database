defmodule Ledger.Parser.Transacciones do
  alias Ledger.Parser.Helpers

  def parse_alta_cuenta(flags) do
    required = [:usuario_destino_id, :moneda_destino_id, :monto]

    mapping = %{
      "-u" => :usuario_destino_id,
      "-m" => :moneda_destino_id,
      "-a" => :monto
    }

    with {:ok, map} <-
           Helpers.parse_flags(flags, mapping),
         {:ok, map} <- Helpers.parse_verificacion(required, map),
         {:ok, num} <- Helpers.parse_float(map[:monto]) do
      {:ok, Map.put(map, :monto, num)}
    end
  end

  def parse_transferencia(flags) do
    required = [:usuario_origen_id, :usuario_destino_id, :moneda_destino_id, :monto]

    mapping = %{
      "-o" => :usuario_origen_id,
      "-d" => :usuario_destino_id,
      "-m" => :moneda_destino_id,
      "-a" => :monto
    }

    with {:ok, map} <-
           Helpers.parse_flags(flags, mapping),
         {:ok, map} <- Helpers.parse_verificacion(required, map),
         {:ok, origen_id} <- Helpers.parse_integer(map[:usuario_origen_id]),
         {:ok, destino_id} <- Helpers.parse_integer(map[:usuario_destino_id]),
         {:ok, m_destino_id} <- Helpers.parse_integer(map[:moneda_destino_id]),
         {:ok, monto} <- Helpers.parse_float(map[:monto]) do
      map =
        map
        |> Map.put(:monto, monto)
        |> Map.put(:usuario_origen_id, origen_id)
        |> Map.put(:usuario_destino_id, destino_id)
        |> Map.put(:moneda_destino_id, m_destino_id)
        |> Map.put(:moneda_origen_id, m_destino_id)

      {:ok, map}
    end
  end

  def parse_swap(flags) do
    required = [:usuario_origen_id, :moneda_origen_id, :moneda_destino_id, :monto]

    mapping = %{
      "-u" => :usuario_origen_id,
      "-mo" => :moneda_origen_id,
      "-md" => :moneda_destino_id,
      "-a" => :monto
    }

    with {:ok, map} <-
           Helpers.parse_flags(flags, mapping),
         {:ok, map} <- Helpers.parse_verificacion(required, map),
         {:ok, origen_id} <- Helpers.parse_integer(map[:usuario_origen_id]),
         {:ok, m_origen_id} <- Helpers.parse_integer(map[:moneda_origen_id]),
         {:ok, m_destino_id} <- Helpers.parse_integer(map[:moneda_destino_id]),
         {:ok, monto} <- Helpers.parse_float(map[:monto]) do
      map =
        map
        |> Map.put(:monto, monto)
        |> Map.put(:usuario_origen_id, origen_id)
        |> Map.put(:moneda_origen_id, m_origen_id)
        |> Map.put(:moneda_destino_id, m_destino_id)

      {:ok, map}
    end
  end

  def parse_id(flags) do
    required = [:id]
    mapping = %{"-id" => :id}

    with {:ok, map} <- Helpers.parse_flags(flags, mapping),
         {:ok, map} <- Helpers.parse_verificacion(required, map),
         {:ok, num_id} <- Helpers.parse_integer(map[:id]) do
      map = Map.put(map, :id, num_id)
      {:ok, map}
    end
  end

  def parse_id_tp1(flags) do
    mapping = %{"-c1" => :id}

    with {:ok, map} <- Helpers.parse_flags(flags, mapping) do
      case Map.get(map, :id) do
        nil ->
          {:ok, Map.put(map, :id, nil)}

        id_str ->
          case Helpers.parse_integer(id_str) do
            {:ok, num_id} -> {:ok, Map.put(map, :id, num_id)}
            error -> error
          end
      end
    end
  end

  def parse_balance(flags) do
    required = [:usuario_id]
    mapping = %{"-c1" => :usuario_id, "-m" => :moneda_id}

    with {:ok, map} <- Helpers.parse_flags(flags, mapping),
         {:ok, map} <- Helpers.parse_verificacion(required, map),
         {:ok, num} <- Helpers.parse_integer(map[:usuario_id]) do
      {:ok, Map.put(map, :usuario_id, num)}
    end
  end
end
