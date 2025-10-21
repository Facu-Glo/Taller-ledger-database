defmodule Ledger.Repo.Migrations.CreateUsuarios do
  use Ecto.Migration

  def change do
    create table(:usuarios) do
      add :nombre, :string, null: false
      add :fecha_nacimiento, :date, null: false

      timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion, type: :utc_datetime)
    end

    create unique_index(:usuarios, [:nombre])
  end
end
