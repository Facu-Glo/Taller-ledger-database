defmodule Ledger.Repo.Migrations.UpdateMonedasTimestamps do
  use Ecto.Migration

  def change do
    alter table(:monedas) do
      remove :fecha_creacion
      remove :fecha_edicion

      timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion, type: :utc_datetime)
    end
  end
end
