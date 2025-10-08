defmodule Ledger.Usuarios.UsuarioFunc do
  alias Ledger.Repo

  # === Funciones Helpers === #

  defp setear_fechas(attrs) do
    fecha_nac =
      case Map.get(attrs, :fecha_nacimiento) do
        nil ->
          nil

        str ->
          [d, m, y] = String.split(str, "-")
          Date.new!(String.to_integer(y), String.to_integer(m), String.to_integer(d))
      end

    Map.put(attrs, :fecha_nacimiento, fecha_nac)
  end

  defp insertar_usuario(changeset) do
    case Repo.insert(changeset) do
      {:ok, usuario} ->
        {:usuario, usuario}

      {:error, _} ->
        cond do
          changeset.errors[:fecha_nacimiento] != nil -> {:error, :invalid_age}
          changeset.errors[:nombre] != nil -> {:error, :user_exists}
          true -> {:error, :unknown_error}
        end
    end
  end

  defp obtener_usuario(map) do
    id = Map.get(map, :id)
    Repo.get(Ledger.Usuarios.Usuario, id)
  end

  defp build_editar_changeset(attrs, usuario) do
    Ledger.Usuarios.Usuario.changeset(usuario, attrs)
  end

  defp actualizar_usuario(changeset) do
    case Repo.update(changeset) do
      {:ok, usuario} -> {:usuario, usuario}
      {:error, _} -> {:error, :invalid_update}
    end
  end

  defp output(error = {:error, _}) do
    Ledger.HandleError.handle_usuario(error)
  end

  defp output(tupla) do
    Ledger.HandleOutput.handle(tupla)
  end

  # === Funciones === #

  def crear_usuario({:ok, attrs}) do
    attrs = setear_fechas(attrs)

    %Ledger.Usuarios.Usuario{}
    |> Ledger.Usuarios.Usuario.changeset(attrs)
    |> insertar_usuario
    |> output()
  end

  def editar_usuario({:ok, attrs}) do
    case obtener_usuario(attrs) do
      nil ->
        {:error, :user_not_found} |> output()

      usuario ->
        nuevo_nombre = attrs[:nuevo_nombre]

        if usuario.nombre == nuevo_nombre do
          {:error, :same_name} |> output()
        else
          %{nombre: nuevo_nombre}
          |> build_editar_changeset(usuario)
          |> actualizar_usuario()
          |> output()
        end
    end
  end

  def ver_usuario({:ok, attrs}) do
    case obtener_usuario(attrs) do
      nil ->
        {:error, :user_not_found} |> output()

      usuario ->
        {:usuario, usuario}
        |> output()
    end
  end
end
