defmodule Ledger.Transacciones.TransaccionSchema do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transacciones" do
    field :monto, :float
    field :tipo, :string

    belongs_to :moneda_origen, Ledger.Monedas.MonedaSchema
    belongs_to :moneda_destino, Ledger.Monedas.MonedaSchema
    belongs_to :usuario_origen, Ledger.Usuarios.UsuarioSchema
    belongs_to :usuario_destino, Ledger.Usuarios.UsuarioSchema

    timestamps(inserted_at: :timestamp, updated_at: false, type: :utc_datetime)
  end

  def changeset(transaccion, attrs) do
    transaccion
    |> cast(attrs, [
      :monto,
      :tipo,
      :moneda_origen_id,
      :moneda_destino_id,
      :usuario_origen_id,
      :usuario_destino_id
    ])
    |> validate_required([
      :monto,
      :tipo,
      :moneda_destino_id
    ])
    |> validate_number(:monto, greater_than: 0)
    |> foreign_key_constraint(:moneda_origen_id)
    |> foreign_key_constraint(:moneda_destino_id)
    |> foreign_key_constraint(:usuario_origen_id)
    |> foreign_key_constraint(:usuario_destino_id)
  end
end
