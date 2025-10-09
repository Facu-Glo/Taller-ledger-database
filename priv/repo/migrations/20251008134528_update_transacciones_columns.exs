defmodule Ledger.Repo.Migrations.UpdateTransaccionesColumns do
  use Ecto.Migration
  
  def up do
    drop constraint(:transacciones, "transacciones_cuenta_origen_id_fkey")
    drop constraint(:transacciones, "transacciones_cuenta_destino_id_fkey")
    
    drop index(:transacciones, [:cuenta_origen_id, :timestamp])
    drop index(:transacciones, [:cuenta_destino_id, :timestamp])
    
    rename table(:transacciones), :cuenta_origen_id, to: :usuario_origen_id
    rename table(:transacciones), :cuenta_destino_id, to: :usuario_destino_id
    
    alter table(:transacciones) do
      modify :tipo, :string, null: false
    end
    
    alter table(:transacciones) do
      modify :usuario_origen_id, references(:usuarios, on_delete: :restrict), null: false
      modify :usuario_destino_id, references(:usuarios, on_delete: :restrict), null: false
    end
    
    create index(:transacciones, [:usuario_origen_id, :timestamp])
    create index(:transacciones, [:usuario_destino_id, :timestamp])
  end
  
  def down do
    drop index(:transacciones, [:usuario_origen_id, :timestamp])
    drop index(:transacciones, [:usuario_destino_id, :timestamp])
    
    drop constraint(:transacciones, "transacciones_usuario_origen_id_fkey")
    drop constraint(:transacciones, "transacciones_usuario_destino_id_fkey")
    
    rename table(:transacciones), :usuario_origen_id, to: :cuenta_origen_id
    rename table(:transacciones), :usuario_destino_id, to: :cuenta_destino_id
    
    alter table(:transacciones) do
      modify :tipo, :string, null: true
    end
    
    alter table(:transacciones) do
      modify :cuenta_origen_id, references(:cuentas, on_delete: :restrict), null: false
      modify :cuenta_destino_id, references(:cuentas, on_delete: :restrict), null: false
    end
    
    create index(:transacciones, [:cuenta_origen_id, :timestamp])
    create index(:transacciones, [:cuenta_destino_id, :timestamp])
  end
end
