defmodule Ledger.Parser.Usuarios do
  alias Ledger.Parser.Helpers

  def parse_crear(flags) do
    required = [:nombre, :fecha_nacimiento]

    case Helpers.parse_flags(flags, %{"-n" => :nombre, "-b" => :fecha_nacimiento}) do
      {:ok, map} ->
        Helpers.parse_verificacion(required, map)

      error ->
        error
    end
  end

  def parse_editar(flags) do
    required = [:id, :nuevo_nombre]

    case Helpers.parse_flags(flags, %{"-id" => :id, "-n" => :nuevo_nombre}) do
      {:ok, map} ->
        Helpers.parse_verificacion(required, map)

      error ->
        error
    end
  end

  def parse_id(flags) do
    required = [:id]

    case Helpers.parse_flags(flags, %{"-id" => :id}) do
      {:ok, map} ->
        Helpers.parse_verificacion(required, map)

      error ->
        error
    end
  end
end
