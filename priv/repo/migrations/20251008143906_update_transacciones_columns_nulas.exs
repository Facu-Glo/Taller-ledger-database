defmodule Ledger.Repo.Migrations.UpdateTransaccionesColumnsNulas do
  use Ecto.Migration

  def change do
    alter table(:transacciones) do
      modify :moneda_destino_id, :integer, null: true
      modify :usuario_origen_id, :integer, null: true
      modify :usuario_destino_id, :integer, null: true
    end
  end
end
