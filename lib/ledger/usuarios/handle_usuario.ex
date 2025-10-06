defmodule Ledger.Usuarios.HandleUsuario do
  @commands %{
    crear_usuario: &Ledger.Usuarios.UsuarioFunc.crear_usuario/1,
    editar_usuario: &Ledger.Usuarios.UsuarioFunc.editar_usuario/1,
    # borrar_usuario: &Ledger.Usuarios.UsuarioFunc.borrar_usuario/1,
    # ver_usuario: &Ledger.Usuarios.UsuarioFunc.ver_usuario/1
  }

  def handle({accion, params}) do
    case Map.get(@commands, accion) do
      nil -> {:error, {:unknown_command, accion}}
      func -> func.(params)
    end
  end
end
