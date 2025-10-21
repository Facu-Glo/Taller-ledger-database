defmodule Ledger.Repo.Migrations.CreateMonedas do
  use Ecto.Migration

  def change do
    create table(:monedas) do
      add :nombre, :string, null: false
      add :precio_usd, :float, null: false

      timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion, type: :utc_datetime)
    end

    create unique_index(:monedas, [:nombre])
  end
end
