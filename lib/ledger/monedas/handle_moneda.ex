defmodule Ledger.Monedas.HandleMoneda do
  @commands %{
    crear_moneda: &Ledger.Monedas.MonedaFunc.crear_moneda/1,
    editar_moneda: &Ledger.Monedas.MonedaFunc.editar_moneda/1,
    # borrar_moneda: &Ledger.Monedas.MonedaFunc.borrar_moneda/1,
    ver_moneda: &Ledger.Monedas.MonedaFunc.ver_moneda/1
  }

  def handle({accion, params}) do
    case Map.get(@commands, accion) do
      nil -> {:error, {:unknown_command, accion}}
      func -> func.(params)
    end
  end
end
