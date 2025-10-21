defmodule Ledger.Handler do
  @commands %{
    crear_usuario: &Ledger.Usuarios.FuncionesUsuario.crear_usuario/1,
    editar_usuario: &Ledger.Usuarios.FuncionesUsuario.editar_usuario/1,
    borrar_usuario: &Ledger.Usuarios.FuncionesUsuario.borrar_usuario/1,
    ver_usuario: &Ledger.Usuarios.FuncionesUsuario.ver_usuario/1,
    #
    crear_moneda: &Ledger.Monedas.FuncionesMoneda.crear_moneda/1,
    editar_moneda: &Ledger.Monedas.FuncionesMoneda.editar_moneda/1,
    borrar_moneda: &Ledger.Monedas.FuncionesMoneda.borrar_moneda/1,
    ver_moneda: &Ledger.Monedas.FuncionesMoneda.ver_moneda/1,
    #
    alta_cuenta: &Ledger.Transacciones.FuncionesTransaccion.alta_cuenta/1,
    realizar_transferencia: &Ledger.Transacciones.FuncionesTransaccion.realizar_transferencia/1,
    realizar_swap: &Ledger.Transacciones.FuncionesTransaccion.realizar_swap/1,
    ver_transaccion: &Ledger.Transacciones.FuncionesTransaccion.ver_transaccion/1,
    deshacer_transaccion: &Ledger.Transacciones.FuncionesTransaccion.deshacer_transaccion/1,
    balance: &Ledger.Transacciones.FuncionesTransaccion.balance/1,
    listar_transacciones: &Ledger.Transacciones.FuncionesTransaccion.listar_transacciones/1
  }

  def handle({accion, params}) do
    case Map.get(@commands, accion) do
      nil -> {:error, {:unknown_command, accion}}
      func -> func.(params)
    end
  end
end
