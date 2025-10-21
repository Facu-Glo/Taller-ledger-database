defmodule Ledger.Transacciones.FuncionesTransaccion do
  alias Ledger.Repo
  alias Ledger.Transacciones.TransaccionSchema
  alias Ledger.Usuarios.UsuarioSchema
  alias Ledger.Monedas.MonedaSchema
  alias Ledger.Output.{Errors, Output}
  import Ecto.Query

  ########################################
  ##### === Funciones Auxiliares === #####
  ########################################

  def output(error = {:error, _tipo, reason}) do
    Errors.error_transacciones(error)
    {:error, reason}
  end

  def output(t = {:ok, transaccion}) do
    Output.handle({:transaccion, transaccion})
    t
  end

  def output_listar(t = {:ok, transacciones}) do
    Output.handle({:listar_transacciones, transacciones})
    t
  end

  def output_listar({:error, _, _} = error) do
    Errors.error_transacciones(error)
  end

  def output_balance({:error, _, _} = error) do
    Errors.error_transacciones(error)
  end

  def output_balance({:ok, tipo, balances}) do
    Output.handle({:balance, tipo, balances})
    {:ok, balances}
  end

  defp get_moneda_por_nombre(nombre) do
    case Repo.get_by(MonedaSchema, nombre: nombre) do
      nil -> {:error, :moneda_not_found}
      moneda -> {:ok, moneda}
    end
  end

  defp obtener_moneda_id_opcional(nil), do: {:ok, nil}

  defp obtener_moneda_id_opcional(nombre) do
    case get_moneda_por_nombre(nombre) do
      {:ok, moneda} ->
        {:ok, moneda.id}

      {:error, _} ->
        {:error, :balance, :moneda_nil}
    end
  end

  defp usuario_existe(usuario_id, tipo) do
    case Repo.get(UsuarioSchema, usuario_id) do
      nil -> {:error, tipo, :user_not_found}
      usuario -> {:ok, usuario}
    end
  end

  defp moneda_existe(moneda_id, tipo) do
    case Repo.get(MonedaSchema, moneda_id) do
      nil -> {:error, tipo, :moneda_not_found}
      moneda -> {:ok, moneda}
    end
  end

  defp monto_positivo(attrs, tipo) do
    monto = Map.get(attrs, :monto)

    if monto > 0 do
      {:ok, monto}
    else
      {:error, tipo, :invalid_amount}
    end
  end

  defp cuenta_activa(usuario_id, moneda_id, tipo_funcion, origen_destino) do
    query =
      from(t in TransaccionSchema,
        where: t.usuario_destino_id == ^usuario_id and t.moneda_destino_id == ^moneda_id
      )

    if Repo.exists?(query) do
      {:ok, :active}
    else
      reason =
        case origen_destino do
          :origen -> :cuenta_origen_no_existe
          :destino -> :cuenta_destino_no_existe
        end

      {:error, tipo_funcion, reason}
    end
  end

  defp preload_transaccion(transaccion) do
    Repo.preload(transaccion, [
      :usuario_origen,
      :usuario_destino,
      :moneda_origen,
      :moneda_destino
    ])
  end

  defp calcular_balance(usuario_id, moneda_id) do
    transacciones =
      from(t in TransaccionSchema,
        where:
          (t.usuario_origen_id == ^usuario_id or t.usuario_destino_id == ^usuario_id) and
            (t.moneda_origen_id == ^moneda_id or t.moneda_destino_id == ^moneda_id),
        preload: [:moneda_origen, :moneda_destino]
      )
      |> Repo.all()

    Enum.reduce(transacciones, 0.0, fn t, saldo ->
      cond do
        t.tipo == "ALTA_CUENTA" and t.usuario_destino_id == usuario_id and
            t.moneda_destino_id == moneda_id ->
          saldo + t.monto

        t.tipo == "TRANSFERENCIA" and t.usuario_origen_id == usuario_id and
            t.moneda_destino_id == moneda_id ->
          saldo - t.monto

        t.tipo == "TRANSFERENCIA" and t.usuario_destino_id == usuario_id and
            t.moneda_destino_id == moneda_id ->
          saldo + t.monto

        t.tipo == "SWAP" and t.usuario_origen_id == usuario_id and
            t.moneda_origen_id == moneda_id ->
          saldo - t.monto

        t.tipo == "SWAP" and t.usuario_origen_id == usuario_id and
            t.moneda_destino_id == moneda_id ->
          monto_convertido =
            if t.moneda_destino.precio_usd == 0 do
              0.0
            else
              t.monto * t.moneda_origen.precio_usd / t.moneda_destino.precio_usd
            end

          saldo + monto_convertido

        t.tipo == "REVERSION_ALTA_CUENTA" and t.usuario_origen_id == usuario_id and
            t.moneda_destino_id == moneda_id ->
          saldo - t.monto

        true ->
          saldo
      end
    end)
  end

  defp validar_monto(usuario_id, moneda_id, monto, tipo) do
    saldo = calcular_balance(usuario_id, moneda_id)

    if saldo >= monto do
      {:ok, :sufficient_funds}
    else
      {:error, tipo, :insufficient_funds}
    end
  end

  defp consulta_balances(usuario_id) do
    alta_cuentas_query =
      from(t in TransaccionSchema,
        where: t.usuario_destino_id == ^usuario_id and t.tipo == "ALTA_CUENTA",
        select: t.moneda_destino_id
      )

    Repo.all(alta_cuentas_query) |> Enum.uniq()
  end

  defp listar_balances(usuario_id, nil) do
    monedas = consulta_balances(usuario_id)

    balances =
      Enum.map(monedas, fn moneda_id ->
        saldo = calcular_balance(usuario_id, moneda_id)
        %{moneda_id: moneda_id, total: saldo}
      end)

    {:ok, :sin_moneda, balances}
    |> output_balance()
  end

  defp listar_balances(usuario_id, moneda_id) do
    monedas = consulta_balances(usuario_id)

    balances =
      Enum.map(monedas, fn moneda_id ->
        saldo = calcular_balance(usuario_id, moneda_id)
        %{moneda_id: moneda_id, total: saldo}
      end)

    moneda_ref = Repo.get(MonedaSchema, moneda_id)

    total =
      if moneda_ref.precio_usd == 0 do
        0.0
      else
        total_convertido =
          balances
          |> Enum.reduce(0.0, fn b, acc ->
            moneda = Repo.get(MonedaSchema, b.moneda_id)
            acc + b.total * moneda.precio_usd / moneda_ref.precio_usd
          end)

        total_convertido
      end

    balances = %{total: total, moneda: moneda_ref.nombre}

    {:ok, :moneda, balances}
    |> output_balance()
  end

  defp generar_transaccion_opuesta(transaccion) do
    case transaccion.tipo do
      "ALTA_CUENTA" ->
        %{
          tipo: "REVERSION_ALTA_CUENTA",
          monto: transaccion.monto,
          usuario_origen_id: transaccion.usuario_destino_id,
          moneda_destino_id: transaccion.moneda_destino_id
        }

      "TRANSFERENCIA" ->
        %{
          tipo: "TRANSFERENCIA",
          monto: transaccion.monto,
          usuario_origen_id: transaccion.usuario_destino_id,
          usuario_destino_id: transaccion.usuario_origen_id,
          moneda_origen_id: transaccion.moneda_origen_id,
          moneda_destino_id: transaccion.moneda_destino_id
        }

      "SWAP" ->
        monto_opuesto =
          if transaccion.moneda_destino.precio_usd == 0 do
            0.0
          else
            transaccion.monto * transaccion.moneda_origen.precio_usd /
              transaccion.moneda_destino.precio_usd
          end

        %{
          tipo: "SWAP",
          monto: monto_opuesto,
          usuario_origen_id: transaccion.usuario_origen_id,
          moneda_origen_id: transaccion.moneda_destino_id,
          moneda_destino_id: transaccion.moneda_origen_id
        }

      "REVERSION_ALTA_CUENTA" ->
        %{
          tipo: "ALTA_CUENTA",
          monto: transaccion.monto,
          usuario_destino_id: transaccion.usuario_origen_id,
          moneda_destino_id: transaccion.moneda_destino_id
        }

      _ ->
        {:error, :deshacer, :tipo_no_soportado}
    end
  end

  defp ultima_transaccion?(transaccion) do
    usuario_ids =
      [transaccion.usuario_origen_id, transaccion.usuario_destino_id]
      |> Enum.reject(fn t -> is_nil(t) end)

    query =
      from(t in TransaccionSchema,
        where:
          (t.usuario_origen_id in ^usuario_ids or t.usuario_destino_id in ^usuario_ids) and
            t.timestamp > ^transaccion.timestamp,
        select: count(t.id)
      )

    Repo.one(query) == 0
  end

  defp insertar_transaccion(attrs) do
    case %TransaccionSchema{}
         |> TransaccionSchema.changeset(attrs)
         |> Repo.insert() do
      {:ok, transaccion} ->
        transaccion
        |> preload_transaccion()
        |> then(fn t -> {:ok, t} end)

      {:error, _changeset} = error ->
        error
    end
  end

  #############################
  ##### === Funciones === #####
  #############################

  def alta_cuenta({:ok, attrs}) do
    Repo.transact(fn ->
      usuario = attrs[:usuario_destino_id]
      moneda = attrs[:moneda_destino_id]

      resultado =
        with {:ok, _} <- usuario_existe(usuario, :alta_cuenta),
             {:ok, _} <- moneda_existe(moneda, :alta_cuenta),
             {:ok, _} <- monto_positivo(attrs, :alta_cuenta) do
          attrs = Map.put(attrs, :tipo, "ALTA_CUENTA")

          insertar_transaccion(attrs)
        else
          error -> error
        end

      output(resultado)
    end)
  end

  def realizar_transferencia({:ok, attrs}) do
    Repo.transact(fn ->
      usuario_origen = attrs[:usuario_origen_id]
      usuario_destino = attrs[:usuario_destino_id]
      moneda = attrs[:moneda_destino_id]
      monto = attrs[:monto]

      with {:ok, _} <- usuario_existe(usuario_origen, :transferencia),
           {:ok, _} <- usuario_existe(usuario_destino, :transferencia),
           {:ok, _} <- moneda_existe(moneda, :transferencia),
           {:ok, _} <- cuenta_activa(usuario_origen, moneda, :transferencia, :origen),
           {:ok, _} <- cuenta_activa(usuario_destino, moneda, :transferencia, :destino),
           {:ok, _} <- monto_positivo(attrs, :transferencia),
           {:ok, _} <- validar_monto(usuario_origen, moneda, monto, :transferencia) do
        attrs = Map.put(attrs, :tipo, "TRANSFERENCIA")

        insertar_transaccion(attrs)
        |> output()
      else
        {:error, _, _} = error ->
          output(error)
      end
    end)
  end

  def realizar_swap({:ok, attrs}) do
    Repo.transact(fn ->
      usuario = attrs[:usuario_origen_id]
      moneda_origen = attrs[:moneda_origen_id]
      moneda_destino = attrs[:moneda_destino_id]
      monto = attrs[:monto]

      with {:ok, _} <- usuario_existe(usuario, :swap),
           {:ok, _} <- moneda_existe(moneda_origen, :swap),
           {:ok, _} <- moneda_existe(moneda_destino, :swap),
           {:ok, _} <- cuenta_activa(usuario, moneda_origen, :swap, :origen),
           {:ok, _} <- cuenta_activa(usuario, moneda_destino, :swap, :origen),
           {:ok, _} <- monto_positivo(attrs, :swap),
           {:ok, _} <- validar_monto(usuario, moneda_origen, monto, :swap) do
        attrs = Map.put(attrs, :tipo, "SWAP")

        insertar_transaccion(attrs)
        |> output()
      else
        {:error, _, _} = error ->
          output(error)
      end
    end)
  end

  def ver_transaccion({:ok, attrs}) do
    id_transaccion = attrs[:id]

    case Repo.get(TransaccionSchema, id_transaccion) do
      nil ->
        {:error, :ver_transaccion, :not_found} |> output()

      transaccion ->
        transaccion
        |> preload_transaccion()
        |> then(fn t -> {:ok, t} end)
        |> output()
    end
  end

  def deshacer_transaccion({:ok, attrs}) do
    id_transaccion = attrs[:id]

    case Repo.get(TransaccionSchema, id_transaccion) do
      nil ->
        {:error, :deshacer, :not_found}

      transaccion ->
        transaccion = preload_transaccion(transaccion)

        if ultima_transaccion?(transaccion) do
          attrs_opuesta = generar_transaccion_opuesta(transaccion)

          Repo.transact(fn ->
            insertar_transaccion(attrs_opuesta)
            |> output()
          end)
        else
          {:error, :deshacer, :not_last}
          |> output()
        end
    end
  end

  def balance({:ok, attrs}) do
    usuario_id = Map.get(attrs, :usuario_id)
    moneda = Map.get(attrs, :moneda_id)

    with {:ok, _} <- usuario_existe(usuario_id, :balance),
         {:ok, moneda_id} <- obtener_moneda_id_opcional(moneda) do
      listar_balances(usuario_id, moneda_id)
    else
      {:error, _, _} = error ->
        output_balance(error)
    end
  end

  def listar_transacciones({:ok, %{id: nil}}) do
    TransaccionSchema
    |> preload([:usuario_origen, :usuario_destino, :moneda_origen, :moneda_destino])
    |> Repo.all()
    |> then(fn transacciones -> {:ok, transacciones} end)
    |> output_listar()
  end

  def listar_transacciones({:ok, %{id: usuario_id}}) do
    with {:ok, _usuario} <- usuario_existe(usuario_id, :listar) do
      TransaccionSchema
      |> where([t], t.usuario_origen_id == ^usuario_id or t.usuario_destino_id == ^usuario_id)
      |> preload([:usuario_origen, :usuario_destino, :moneda_origen, :moneda_destino])
      |> Repo.all()
      |> then(fn transacciones -> {:ok, transacciones} end)
      |> output_listar()
    else
      {:error, tipo, motivo} ->
        {:error, tipo, motivo}
        |> output_listar()
    end
  end
end
