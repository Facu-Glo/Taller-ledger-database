defmodule Ledger.Transacciones.Transaccion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transacciones" do
    field :timestamp, :utc_datetime
    field :monto, :float
    field :tipo, :string

    belongs_to :moneda_origen, Ledger.Monedas.Moneda
    belongs_to :moneda_destino, Ledger.Monedas.Moneda
    belongs_to :usuario_origen, Ledger.Usuarios.Usuario
    belongs_to :usuario_destino, Ledger.Usuarios.Usuario
  end

  def changeset(transaccion, attrs) do
    transaccion
    |> cast(attrs, [
      :timestamp,
      :monto,
      :tipo,
      :moneda_origen_id,
      :moneda_destino_id,
      :usuario_origen_id,
      :usuario_destino_id
    ])
    |> validate_required([
      :timestamp,
      :monto,
      :tipo,
      :moneda_origen_id
    ])
    |> validate_number(:monto, greater_than: 0)
    |> foreign_key_constraint(:moneda_origen_id)
    |> foreign_key_constraint(:moneda_destino_id)
    |> foreign_key_constraint(:usuario_origen_id)
    |> foreign_key_constraint(:usuario_destino_id)
  end
end
