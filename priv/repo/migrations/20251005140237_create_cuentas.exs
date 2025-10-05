defmodule Ledger.Repo.Migrations.CreateCuentas do
  use Ecto.Migration

  def change do
    create table(:cuentas) do
      add :usuario_id, references(:usuarios, on_delete: :restrict), null: false
      add :moneda_id, references(:monedas, on_delete: :restrict), null: false
      add :saldo, :float, default: 0.0, null: false
    end

    # Solo puede existir 1 usuario por cada moneda
    # No puede existir:
    # user: 1 -> moneda: 1
    # user: 1 -> moneda: 2
    # user: 1 -> moneda: 1    (NO es VALIDO)
    create unique_index(:cuentas, [:usuario_id, :moneda_id])
  end
end
