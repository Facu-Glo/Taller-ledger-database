defmodule Ledger.Repo.Migrations.ChangeTimestampTransacciones do
  use Ecto.Migration

  def up do
    alter table(:transacciones) do
      modify :timestamp, :utc_datetime, null: false
    end
  end

  def down do
    alter table(:transacciones) do
      modify :timestamp, :naive_datetime, null: false
    end
  end
end
