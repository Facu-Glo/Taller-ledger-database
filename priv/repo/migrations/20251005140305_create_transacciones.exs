defmodule Ledger.Repo.Migrations.CreateTransacciones do
  use Ecto.Migration

  def change do
    create table(:transacciones) do
      add :timestamp, :naive_datetime, null: false 
      add :moneda_origen_id, references(:monedas, on_delete: :restrict), null: false
      add :moneda_destino_id, references(:monedas, on_delete: :restrict), null: false
      add :monto, :float, null: false
      add :cuenta_origen_id, references(:cuentas, on_delete: :restrict), null: false
      add :cuenta_destino_id, references(:cuentas, on_delete: :restrict), null: false
      add :tipo, :string
    end
  end
end
