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

    attrs = Map.put(attrs, :fecha_nacimiento, fecha_nac)
    hoy = Date.utc_today()
    attrs = Map.merge(attrs, %{fecha_creacion: hoy, fecha_edicion: hoy})
    attrs
  end

  defp insertar_usuario(changeset) do
    case Repo.insert(changeset) do
      {:ok, usuario} ->
        {:ok, usuario}

      {:error, _} ->
        {:error, :user_exists}
    end
  end

  defp obtener_usuario(map) do
    id = Map.get(map, :id)
    Repo.get(Ledger.Usuarios.Usuario, id)
  end

  defp build_editar_changeset(attrs, usuario),
    do: Ledger.Usuarios.Usuario.changeset(usuario, attrs)

  defp actualizar_usuario(changeset) do
    case Repo.update(changeset) do
      {:ok, usuario} -> {:ok, usuario}
      {:error, _} -> {:error, :invalid_update}
    end
  end

  # === Funciones === #

  def crear_usuario({:ok, attrs}) do
    attrs = setear_fechas(attrs)

    %Ledger.Usuarios.Usuario{}
    |> Ledger.Usuarios.Usuario.changeset(attrs)
    |> insertar_usuario()
    |> output()
  end

  def editar_usuario({:ok, attrs}) do
    case obtener_usuario(attrs) do
      nil ->
        {:error, :user_not_found} |> output()

      usuario ->
        attrs
        |> Map.put(:nombre, attrs[:nuevo_nombre])
        |> Map.put(:fecha_edicion, Date.utc_today())
        |> build_editar_changeset(usuario)
        |> actualizar_usuario()
        |> output()
    end
  end

  def output(error = {:error, _}) do
    Ledger.HandleError.handle_usuario(error)
  end

  def output(tupla) do
    IO.inspect(tupla)
  end
end
