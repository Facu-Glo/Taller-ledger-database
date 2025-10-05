defmodule Ledger.Usuarios.Usuario do
  use Ecto.Schema

  schema "usuarios" do
    field :nombre, :string
    field :fecha_nacimiento, :date
    field :fecha_creacion, :date
    field :fecha_edicion, :date

    has_many :cuentas, Ledger.Cuentas.Cuenta
  end
end
