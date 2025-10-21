defmodule Ledger.Repo.Migrations.CreateTransacciones do
  use Ecto.Migration

  def change do
    create table(:transacciones) do
      add :monto, :float, null: false
      add :tipo, :string, null: false

      add :moneda_origen_id, references(:monedas, on_delete: :restrict) 
      add :moneda_destino_id, references(:monedas, on_delete: :restrict)
      add :usuario_origen_id, references(:usuarios, on_delete: :restrict)
      add :usuario_destino_id, references(:usuarios, on_delete: :restrict)

      timestamps(inserted_at: :fecha_creacion, updated_at: false, type: :utc_datetime)
    end

    create index(:transacciones, [:usuario_origen_id, :fecha_creacion])
    create index(:transacciones, [:usuario_destino_id, :fecha_creacion])
  end
end
