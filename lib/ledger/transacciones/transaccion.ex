defmodule Ledger.Transacciones.Transaccion do
  use Ecto.Schema

  schema "transacciones" do
    field :timestamp, :naive_datetime
    field :monto, :float
    field :tipo, :string

    belongs_to :moneda_origen, Ledger.Monedas.Moneda
    belongs_to :moneda_destino, Ledger.Monedas.Moneda
    belongs_to :cuenta_origen, Ledger.Cuentas.Cuenta
    belongs_to :cuenta_destino, Ledger.Cuentas.Cuenta
  end
end
