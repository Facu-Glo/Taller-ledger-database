defmodule Ledger do
  alias Ledger.Parser.Parser
  alias Ledger.Usuarios.HandleUsuario
  alias Ledger.Monedas.HandleMoneda

  def main(args) do
    case Parser.parser_args(args) do
      {:crear_usuario, params} -> HandleUsuario.handle({:crear_usuario, params})
      {:editar_usuario, params} -> HandleUsuario.handle({:editar_usuario, params})
      {:ver_usuario, params} -> HandleUsuario.handle({:ver_usuario, params})

      {:borrar_usuario, params} -> IO.inspect({:borrar_usuario, params})

      {:crear_moneda, params} -> HandleMoneda.handle({:crear_moneda, params})
      {:editar_moneda, params} -> HandleMoneda.handle({:editar_moneda, params})
      {:ver_moneda, params} -> HandleMoneda.handle({:ver_moneda, params})

      {:borrar_moneda, params} -> IO.inspect({:borrar_moneda, params})

      {:alta_cuenta, params} -> IO.inspect({:alta_cuenta, params})
      {:realizar_transferencia, params} -> IO.inspect({:realizar_transferencia, params})
      {:realizar_swap, params} -> IO.inspect({:realizar_swap, params})
      {:deshacer_transaccion, params} -> IO.inspect({:deshacer_transaccion, params})
      {:ver_transaccion, params} -> IO.inspect({:ver_transaccion, params})
      {:error, reason} -> IO.inspect({:error, reason})
    end
  end
end
