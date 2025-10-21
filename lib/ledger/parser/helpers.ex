defmodule Ledger.Parser.Helpers do
  def parse_flags(flags, mapping) do
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

  def parse_verificacion(list, map) do
    missing = Enum.filter(list, fn key -> !Map.has_key?(map, key) end)
    if missing == [], do: {:ok, map}, else: {:error, {:missing_flags, missing}}
  end

  def parse_float(nil), do: {:error, :invalid_float}

  def parse_float(str) do
    case Float.parse(str) do
      {num, ""} -> {:ok, num}
      _ -> {:error, :invalid_float}
    end
  end

  def parse_precio(nil), do: {:error, :precio_invalid}

  def parse_precio(str) do
    case Float.parse(str) do
      {num, ""} -> {:ok, num}
      _ -> {:error, :precio_invalid}
    end
  end

  def parse_integer(nil), do: {:error, :invalid_integer}

  def parse_integer(str) do
    case Integer.parse(str) do
      {num, ""} -> {:ok, num}
      _ -> {:error, :invalid_integer}
    end
  end
end
