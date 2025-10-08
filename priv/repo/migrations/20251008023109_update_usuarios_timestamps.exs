defmodule Ledger.Repo.Migrations.UpdateUsuariosTimestamps do
  use Ecto.Migration

  def change do
    alter table(:usuarios) do
      remove :fecha_creacion
      remove :fecha_edicion

      timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion, type: :utc_datetime)
    end
  end
end
