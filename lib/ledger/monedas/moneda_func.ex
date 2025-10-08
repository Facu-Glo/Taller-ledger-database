defmodule Ledger.Monedas.MonedaFunc do
  alias Ledger.Repo

  # === Funciones Helpers === #

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
    Repo.get(Ledger.Monedas.Moneda, id)
  end

  defp actualizar_moneda(changeset) do
    case Repo.update(changeset) do
      {:ok, moneda} -> {:moneda, moneda}
      {:error, _} -> {:error, :invalid_update}
    end
  end

  defp output(error = {:error, _}) do
    Ledger.HandleError.handle_monedas(error)
  end

  defp output(tupla) do
    Ledger.HandleOutput.handle(tupla)
  end

  # === Funciones === #
  def crear_moneda({:ok, attrs}) do
    %Ledger.Monedas.Moneda{}
    |> Ledger.Monedas.Moneda.changeset(attrs)
    |> insertar_moneda()
    |> output()
  end

  def editar_moneda({:ok, attrs}) do
    case obtener_moneda(attrs) do
      nil ->
        {:error, :moneda_not_found} |> output()

      moneda ->
        nuevo_precio = attrs[:nuevo_precio]
        attrs_a_actualizar = %{precio_usd: nuevo_precio}

        moneda
        |> Ledger.Monedas.Moneda.changeset(attrs_a_actualizar)
        |> actualizar_moneda()
        |> output()
    end
  end

  def ver_moneda({:ok, attrs}) do
    case obtener_moneda(attrs) do
      nil ->
        {:error, :moneda_not_found} |> output()

      moneda ->
        {:moneda, moneda} |> output()
    end
  end
end
