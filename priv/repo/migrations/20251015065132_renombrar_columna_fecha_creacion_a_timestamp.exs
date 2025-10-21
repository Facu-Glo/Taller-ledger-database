defmodule Ledger.Repo.Migrations.RenombrarColumnaFechaCreacionATimestamp do
  use Ecto.Migration

  def change do
    rename table(:transacciones), :fecha_creacion, to: :timestamp
  end
end
