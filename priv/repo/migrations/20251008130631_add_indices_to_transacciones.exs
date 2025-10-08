defmodule Ledger.Repo.Migrations.AddIndicesToTransacciones do
  use Ecto.Migration

  def change do
    create index(:transacciones, [:cuenta_origen_id, :timestamp])
    create index(:transacciones, [:cuenta_destino_id, :timestamp])
  end
end
