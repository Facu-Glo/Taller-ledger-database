defmodule Ledger.Monedas.MonedaSchema do
  use Ecto.Schema
  import Ecto.Changeset

  schema "monedas" do
    field :nombre, :string
    field :precio_usd, :float

    timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion, type: :utc_datetime)
  end

  def changeset(moneda, attrs) do
    moneda
    |> cast(attrs, [:nombre, :precio_usd])
    |> validate_required([:nombre, :precio_usd])
    |> validate_length(:nombre, min: 3, max: 4)
    |> validate_format(:nombre, ~r/^[A-Z]+$/, message: "El nombre debe estar en mayúsculas")
    |> unsafe_validate_unique(:nombre, Ledger.Repo)
    |> unique_constraint(:nombre)
    |> validate_number(:precio_usd, greater_than_or_equal_to: 0)
  end
end
