defmodule Ledger.Transacciones.TransaccionFunc do
  alias Ledger.Repo
  alias Ledger.Transacciones.Transaccion
  alias Ledger.Usuarios.Usuario
  alias Ledger.Monedas.Moneda
  import Ecto.Query

  # === Funciones Helpers === #

  defp validar_usuario(id) do
    case Repo.get(Usuario, id) do
      nil -> {:error, :user_not_found}
      usuario -> {:ok, usuario}
    end
  end

  defp validar_moneda(id) do
    case Repo.get(Moneda, id) do
      nil -> {:error, :moneda_not_found}
      moneda -> {:ok, moneda}
    end
  end

  defp validar_monto(monto) when is_number(monto) and monto > 0, do: {:ok, monto}
  defp validar_monto(_), do: {:error, :invalid_amount}

  defp saldo_suficiente?(usuario_id, moneda_id, monto) do
    saldo_actual = calcular_saldo(usuario_id, moneda_id)
    IO.puts("Saldo actual: #{saldo_actual}, Monto requerido: #{monto}")
    saldo_actual >= monto
  end

  defp calcular_saldo(usuario_id, moneda_id) do
    transacciones =
      from(t in Transaccion,
        where:
          (t.usuario_origen_id == ^usuario_id or t.usuario_destino_id == ^usuario_id) and
            (t.moneda_origen_id == ^moneda_id or t.moneda_destino_id == ^moneda_id),
        select:
          {t.tipo, t.usuario_origen_id, t.usuario_destino_id, t.moneda_origen_id,
           t.moneda_destino_id, t.monto}
      )
      |> Repo.all()

    Enum.reduce(transacciones, 0.0, fn
      # Alta cuenta → suma al saldo si el usuario es el destino
      {"alta_cuenta", _origen, destino, mo_orig, _mo_dest, monto}, acc
      when destino == usuario_id and mo_orig == moneda_id ->
        acc + monto

      # Transferencia → resta si el usuario es el origen
      {"transferencia", origen, _destino, mo_orig, _mo_dest, monto}, acc
      when origen == usuario_id and mo_orig == moneda_id ->
        acc - monto

      # Transferencia → suma si el usuario es el destino
      {"transferencia", _origen, destino, _mo_orig, mo_dest, monto}, acc
      when destino == usuario_id and mo_dest == moneda_id ->
        acc + monto

      # Swap → resta si el usuario es el origen y la moneda es la de origen
      {"swap", origen, _destino, mo_orig, _mo_dest, monto}, acc
      when origen == usuario_id and mo_orig == moneda_id ->
        acc - monto

      # Swap → suma si el usuario es el destino y la moneda es la de destino
      {"swap", _origen, destino, _mo_orig, mo_dest, monto}, acc
      when destino == usuario_id and mo_dest == moneda_id ->
        acc + monto

      # Cualquier otro caso → no afecta
      _, acc ->
        acc
    end)
  end

  defp tiene_cuenta_activa?(usuario_id, moneda_id) do
    query =
      from t in Transaccion,
        where:
          t.usuario_destino_id == ^usuario_id and
            t.moneda_origen_id == ^moneda_id and
            t.tipo == "alta_cuenta",
        limit: 1

    Repo.exists?(query)
  end

  defp output(error = {:error, _}) do
    Ledger.HandleError.handle_transacciones(error)
  end

  # === Funciones Públicas === #

  def alta_cuenta({:ok, attrs}) do
    Repo.transaction(fn ->
      with {:ok, _usuario} <- validar_usuario(attrs[:usuario_destino_id]),
           {:ok, _moneda} <- validar_moneda(attrs[:moneda_origen_id]),
           {:ok, _monto} <- validar_monto(attrs[:monto]),
           false <- tiene_cuenta_activa?(attrs[:usuario_destino_id], attrs[:moneda_origen_id]) do
        transaccion_attrs =
          attrs
          |> Map.put(:timestamp, DateTime.utc_now())
          |> Map.put(:tipo, "alta_cuenta")

        case %Transaccion{}
             |> Transaccion.changeset(transaccion_attrs)
             |> Repo.insert() do
          {:ok, transaccion} -> transaccion
          {:error, changeset} -> Repo.rollback(changeset)
        end
      else
        {:error, reason} ->
          output({:error, reason})
          Repo.rollback(reason)

        true ->
          output({:error, :cuenta_ya_existe})
          Repo.rollback(:cuenta_ya_existe)
      end
    end)
  end

  def realizar_transferencia({:ok, attrs}) do
    Repo.transaction(fn ->
      with {:ok, usuario_origen} <- validar_usuario(attrs[:usuario_origen_id]),
           {:ok, usuario_destino} <- validar_usuario(attrs[:usuario_destino_id]),
           {:ok, moneda} <- validar_moneda(attrs[:moneda_id]),
           {:ok, monto} <- validar_monto(attrs[:monto]),
           true <- tiene_cuenta_activa?(usuario_origen.id, moneda.id) || :cuenta_origen_no_existe,
           true <-
             tiene_cuenta_activa?(usuario_destino.id, moneda.id) || :cuenta_destino_no_existe,
           true <- saldo_suficiente?(usuario_origen.id, moneda.id, monto) || :insufficient_funds do
        transaccion_attrs = %{
          timestamp: DateTime.utc_now(),
          tipo: "transferencia",
          moneda_origen_id: moneda.id,
          moneda_destino_id: moneda.id,
          usuario_origen_id: usuario_origen.id,
          usuario_destino_id: usuario_destino.id,
          monto: monto
        }

        case %Transaccion{}
             |> Transaccion.changeset(transaccion_attrs)
             |> Repo.insert() do
          {:ok, _transaccion} -> {:ok, :transferencia_exitosa}
          {:error, changeset} -> Repo.rollback(changeset)
        end
      else
        {:error, reason} ->
          output({:error, reason})
          Repo.rollback(reason)

        :cuenta_origen_no_existe ->
          output({:error, :cuenta_origen_no_existe})
          Repo.rollback(:cuenta_origen_no_existe)

        :cuenta_destino_no_existe ->
          output({:error, :cuenta_destino_no_existe})
          Repo.rollback(:cuenta_destino_no_existe)

        :insufficient_funds ->
          output({:error, :insufficient_funds})
          Repo.rollback(:insufficient_funds)
      end
    end)
  end

  # Función para consultar saldo (útil para la API)
  def obtener_saldo(usuario_id, moneda_id) do
    with {:ok, _usuario} <- validar_usuario(usuario_id),
         {:ok, _moneda} <- validar_moneda(moneda_id) do
      saldo = calcular_saldo(usuario_id, moneda_id)
      {:ok, saldo}
    end
  end

  def ver_transaccion({:ok, attrs}) do
    _id = attrs[:id]

  end
end
