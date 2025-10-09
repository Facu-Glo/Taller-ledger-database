defmodule Ledger.Transacciones.HandleTransaccion do
  @command %{
    alta_cuenta: &Ledger.Transacciones.TransaccionFunc.alta_cuenta/1,
    realizar_transferencia: &Ledger.Transacciones.TransaccionFunc.realizar_transferencia/1
  }

  def handle({accion, params}) do
    case Map.get(@command, accion) do
      nil -> {:error, {:unknown_command, accion}}
      func -> func.(params)
    end
  end
end
