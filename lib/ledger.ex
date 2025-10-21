defmodule Ledger do
  alias Ledger.Parser.Parser
  alias Ledger.Handler

  def main(args) do
    case Parser.parser_args(args) do
      {:balance, params} ->
        Handler.handle({:balance, params})

      {:listar_transacciones, params} ->
        Handler.handle({:listar_transacciones, params})

      {:crear_usuario, params} ->
        Handler.handle({:crear_usuario, params})

      {:editar_usuario, params} ->
        Handler.handle({:editar_usuario, params})

      {:ver_usuario, params} ->
        Handler.handle({:ver_usuario, params})

      {:borrar_usuario, params} ->
        Handler.handle({:borrar_usuario, params})

      {:crear_moneda, params} ->
        Handler.handle({:crear_moneda, params})

      {:editar_moneda, params} ->
        Handler.handle({:editar_moneda, params})

      {:ver_moneda, params} ->
        Handler.handle({:ver_moneda, params})

      {:borrar_moneda, params} ->
        Handler.handle({:borrar_moneda, params})

      {:alta_cuenta, params} ->
        Handler.handle({:alta_cuenta, params})

      {:realizar_transferencia, params} ->
        Handler.handle({:realizar_transferencia, params})

      {:realizar_swap, params} ->
        Handler.handle({:realizar_swap, params})

      {:deshacer_transaccion, params} ->
        Handler.handle({:deshacer_transaccion, params})

      {:ver_transaccion, params} ->
        Handler.handle({:ver_transaccion, params})

      {:error, reason} ->
        IO.inspect({:error, reason})
    end
  end
end
