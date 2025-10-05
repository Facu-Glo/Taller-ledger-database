defmodule Ledger.Monedas.Moneda do
  use Ecto.Schema

  schema "monedas" do
    field :nombre, :string
    field :precio_usd, :float
    field :fecha_creacion, :date
    field :fecha_edicion, :date

    has_many :cuentas, Ledger.Cuentas.Cuenta
  end
end
