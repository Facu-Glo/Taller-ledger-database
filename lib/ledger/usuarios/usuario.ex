defmodule Ledger.Usuarios.Usuario do
  use Ecto.Schema
  import Ecto.Changeset

  schema "usuarios" do
    field :nombre, :string
    field :fecha_nacimiento, :date

    timestamps(inserted_at: :fecha_creacion, updated_at: :fecha_edicion, type: :utc_datetime)
  end

  def changeset(usuario, attrs) do
    usuario
    |> cast(attrs, [:nombre, :fecha_nacimiento])
    |> validate_required([:nombre, :fecha_nacimiento])
    |> unsafe_validate_unique(:nombre, Ledger.Repo)
    |> unique_constraint(:nombre)
    |> validate_age()
  end

  defp validate_age(changeset) do
    if get_field(changeset, :fecha_nacimiento) &&
         Date.diff(Date.utc_today(), get_field(changeset, :fecha_nacimiento)) / 365 < 18 do
      add_error(changeset, :fecha_nacimiento, "El usuario debe ser mayor de 18 años")
    else
      changeset
    end
  end
end
