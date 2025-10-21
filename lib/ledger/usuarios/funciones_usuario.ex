defmodule Ledger.Usuarios.FuncionesUsuario do
  alias Ledger.Repo
  alias Ledger.Usuarios.UsuarioSchema
  alias Ledger.Output.{Errors, Output}
  alias Ledger.Transacciones.TransaccionSchema
  import Ecto.Query

  ################################
  # === Funciones Auxiliares === #
  ################################

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
    Repo.get(UsuarioSchema, id)
  end

  defp build_editar_changeset(attrs, usuario) do
    UsuarioSchema.changeset(usuario, attrs)
  end

  defp actualizar_usuario(changeset) do
    case Repo.update(changeset) do
      {:ok, usuario} -> {:usuario, usuario}
      {:error, _} -> {:error, :invalid_update}
    end
  end

  defp output(error = {:error, _}) do
    Errors.error_usuario(error)
  end

  defp output(tupla) do
    Output.handle(tupla)
  end

  #####################
  # === Funciones === #
  #####################

  def crear_usuario({:ok, attrs}) do
    attrs = setear_fechas(attrs)

    %UsuarioSchema{}
    |> UsuarioSchema.changeset(attrs)
    |> insertar_usuario
    |> output()
  end

  def editar_usuario({:ok, attrs}) do
    case obtener_usuario(attrs) do
      nil ->
        {:error, :user_not_found}
        |> output()

      usuario ->
        nuevo_nombre = attrs[:nuevo_nombre]

        if usuario.nombre == nuevo_nombre do
          {:error, :same_name}
          |> output()
        else
          %{nombre: nuevo_nombre}
          |> build_editar_changeset(usuario)
          |> actualizar_usuario()
          |> output()
        end
    end
  end

  def borrar_usuario({:ok, attrs}) do
    case obtener_usuario(attrs) do
      nil ->
        {:error, :user_not_found}
        |> output()

      usuario ->
        tiene_transacciones =
          from(t in TransaccionSchema,
            where: t.usuario_origen_id == ^usuario.id or t.usuario_destino_id == ^usuario.id,
            limit: 1
          )
          |> Repo.exists?()

        if tiene_transacciones do
          {:error, :user_has_transactions} |> output()
        else
          case Repo.delete(usuario) do
            {:ok, _struct} ->
              {:usuario, usuario}
              |> output()

            {:error, _changeset} ->
              {:error, :delete_failed}
              |> output()
          end
        end
    end
  end

  def ver_usuario({:ok, attrs}) do
    case obtener_usuario(attrs) do
      nil ->
        {:error, :ver_user_not_found}
        |> output()

      usuario ->
        {:usuario, usuario}
        |> output()
    end
  end
end
