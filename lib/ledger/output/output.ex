defmodule Ledger.Output.Output do
  def handle({:usuario, usuario}) do
    IO.puts("""

    ──────────────────────────────────────────────────────────────
      Usuario ID: #{usuario.id}
      Nombre: #{usuario.nombre}
      Fecha de nacimiento: #{usuario.fecha_nacimiento}
      Fecha de creación: #{usuario.fecha_creacion}
      Última edición: #{usuario.fecha_edicion}
    ──────────────────────────────────────────────────────────────
    """)
  end

  def handle({:moneda, moneda}) do
    IO.puts("""

    ──────────────────────────────────────────────────────────────
      Moneda ID: #{moneda.id}
      Nombre: #{moneda.nombre}
      Precio USD: #{moneda.precio_usd}
      Fecha de creación: #{moneda.fecha_creacion}
      Última edición: #{moneda.fecha_edicion}
    ──────────────────────────────────────────────────────────────
    """)
  end

  def handle({:listar_transacciones, transacciones}) when is_list(transacciones) do
    if transacciones == [] do
      IO.puts("\n──────────────────────────────────────────────────────────────")
      IO.puts("  No hay transacciones registradas.")
      IO.puts("──────────────────────────────────────────────────────────────\n")
    else
      Enum.each(transacciones, fn t ->
        handle({:transaccion, t})
      end)
    end
  end

  def handle({:transaccion, t}) do
    base_info = """
    ──────────────────────────────────────────────────────────────

      Transacción ID: #{t.id}
      Tipo: #{t.tipo}
      Monto: #{t.monto}
    """

    detalle =
      case t.tipo do
        "ALTA_CUENTA" ->
          """
            Usuario: #{t.usuario_destino.nombre}
            Moneda: #{t.moneda_destino.nombre}
          """

        "TRANSFERENCIA" ->
          """
            Usuario origen: #{t.usuario_origen.nombre}
            Usuario destino: #{t.usuario_destino.nombre}
            Moneda: #{t.moneda_destino.nombre}
          """

        "SWAP" ->
          """
            Usuario: #{t.usuario_origen.nombre}
            Moneda origen: #{t.moneda_origen.nombre}
            Moneda destino: #{t.moneda_destino.nombre}
          """

        "REVERSION_ALTA_CUENTA" ->
          """
            Usuario: #{t.usuario_origen.nombre}
            Moneda: #{t.moneda_destino.nombre}
          """

        _ ->
          "Tipo de transacción desconocido."
      end

    IO.puts(
      base_info <> detalle <> "\n──────────────────────────────────────────────────────────────"
    )
  end

  def handle({:balance, tipo, balances}) do
    if tipo == :moneda do
      balance_con_moneda(:moneda, balances)
    else
      balance_sin_moneda(:sin_moneda, balances)
    end
  end

  defp balance_sin_moneda(:sin_moneda, balances) do
    IO.puts("──────────────────────────────────────────────────────────────")

    Enum.each(balances, fn %{moneda_id: moneda_id, total: monto} ->
      moneda = Ledger.Repo.get(Ledger.Monedas.MonedaSchema, moneda_id)
      nombre = if moneda, do: moneda.nombre, else: "Desconocida"

      IO.puts("  Moneda: #{nombre} | Balance: #{monto}")
    end)

    IO.puts("──────────────────────────────────────────────────────────────")
  end

  def balance_con_moneda(:moneda, balance) do
    IO.puts("──────────────────────────────────────────────────────────────")
    moneda = balance.moneda
    total = balance.total

    IO.puts("  Moneda: #{moneda} | Balance: #{total}")
    IO.puts("──────────────────────────────────────────────────────────────")
  end
end
