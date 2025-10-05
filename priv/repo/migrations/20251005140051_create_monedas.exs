defmodule Ledger.Repo.Migrations.CreateMonedas do
  use Ecto.Migration

  def change do
    create table(:monedas) do
      add :nombre, :string, null: false
      add :precio_usd, :float, null: false
      add :fecha_creacion, :date, null: false
      add :fecha_edicion, :date, null: false
    end

    create unique_index(:monedas, [:nombre])
  end
end
