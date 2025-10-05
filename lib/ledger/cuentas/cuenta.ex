defmodule Ledger.Cuentas.Cuenta do
  use Ecto.Schema

  schema "cuentas" do
    field :saldo, :float, default: 0.0

    belongs_to :usuario, Ledger.Usuarios.Usuario
    belongs_to :moneda, Ledger.Monedas.Moneda
  end
end
