defmodule Ledger.Monedas.FuncionesMoneda do
  alias Ledger.Transacciones.TransaccionSchema
  alias Ledger.Repo
  alias Ledger.Monedas.MonedaSchema
  alias Ledger.Output.{Errors, Output}
  import Ecto.Query

  #############################
  # === Funciones Helpers === #
  #############################

  defp insertar_moneda(changeset) do
    case Repo.insert(changeset) do
      {:ok, moneda} ->
        {:moneda, moneda}

      {:error, _} ->
        manejar_error(changeset)
    end
  end

  defp manejar_error(changeset) do
    changeset
    |> buscar_error_nombre()
    |> case do
      nil -> buscar_error_precio(changeset) || {:error, :unknown_error}
      error -> error
    end
  end

  defp buscar_error_nombre(changeset) do
    List.wrap(changeset.errors[:nombre])
    |> Enum.find_value(fn {_msg, opts} -> error_por_opts_nombre(opts) end)
  end

  defp error_por_opts_nombre(opts) do
    case Keyword.get(opts, :validation) do
      :unsafe_unique ->
        {:error, :divisa_existe}

      :length ->
        case Keyword.get(opts, :kind) do
          :min -> {:error, :nombre_corto}
          :max -> {:error, :nombre_largo}
          _ -> nil
        end

      :format ->
        {:error, :nombre_formato_invalido}

      _ ->
        nil
    end
  end

  defp buscar_error_precio(changeset) do
    List.wrap(changeset.errors[:precio_usd])
    |> Enum.find_value(fn {_msg, opts} ->
      if Keyword.get(opts, :validation) == :number and
           Keyword.get(opts, :kind) == :greater_than_or_equal_to,
         do: {:error, :precio_invalido}
    end)
  end

  defp obtener_moneda(map) do
    id = Map.get(map, :id)
    Repo.get(MonedaSchema, id)
  end

  defp actualizar_moneda(changeset) do
    case Repo.update(changeset) do
      {:ok, moneda} -> {:moneda, moneda}
      {:error, _} -> {:error, :invalid_update}
    end
  end

  defp output(error = {:error, _}) do
    Errors.error_monedas(error)
  end

  defp output(tupla) do
    Output.handle(tupla)
  end

  #####################
  # === Funciones === #
  #####################

  def crear_moneda({:ok, attrs}) do
    %MonedaSchema{}
    |> MonedaSchema.changeset(attrs)
    |> insertar_moneda()
    |> output()
  end

  def editar_moneda({:ok, attrs}) do
    case obtener_moneda(attrs) do
      nil ->
        {:error, :moneda_not_found}
        |> output()

      moneda ->
        moneda
        |> MonedaSchema.changeset(attrs)
        |> actualizar_moneda()
        |> output()
    end
  end

  def ver_moneda({:ok, attrs}) do
    case obtener_moneda(attrs) do
      nil ->
        {:error, :ver_moneda_not_found}
        |> output()

      moneda ->
        {:moneda, moneda}
        |> output()
    end
  end

  def borrar_moneda({:ok, attrs}) do
    case obtener_moneda(attrs) do
      nil ->
        {:error, :moneda_not_found}
        |> output()

      moneda ->
        tiene_transacciones =
          from(t in TransaccionSchema,
            where:
              t.moneda_origen_id == ^moneda.id or
                t.moneda_destino_id == ^moneda.id,
            limit: 1
          )
          |> Repo.exists?()

        if tiene_transacciones do
          {:error, :moneda_in_use} |> output()
        else
          case Repo.delete(moneda) do
            {:ok, _} -> {:moneda, moneda} |> output()
            {:error, _} -> {:error, :moneda_delete_failed} |> output()
          end
        end
    end
  end
end
