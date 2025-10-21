defmodule Ledger.Parser.Monedas do
  alias Ledger.Parser.Helpers

  def parse_crear(flags) do
    required = [:nombre, :precio_usd]

    with {:ok, map} <-
           Helpers.parse_flags(flags, %{"-n" => :nombre, "-p" => :precio_usd}),
         {:ok, map} <- Helpers.parse_verificacion(required, map),
         {:ok, num} <- Helpers.parse_precio(map[:precio_usd]) do
      {:ok, Map.put(map, :precio_usd, num)}
    end
  end

  def parse_editar(flags) do
    required = [:id, :precio_usd]

    with {:ok, map} <-
           Helpers.parse_flags(flags, %{"-id" => :id, "-p" => :precio_usd}),
         {:ok, map} <- Helpers.parse_verificacion(required, map),
         {:ok, num} <- Helpers.parse_precio(map[:precio_usd]) do
      {:ok, Map.put(map, :precio_usd, num)}
    end
  end

  def parse_id(flags) do
    required = [:id]

    with {:ok, map} <- Helpers.parse_flags(flags, %{"-id" => :id}),
         {:ok, map} <- Helpers.parse_verificacion(required, map) do
      {:ok, map}
    end
  end
end
