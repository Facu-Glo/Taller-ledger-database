defmodule Ledger.HandleError do
  def handle_usuario({:error, reason}) do
    case reason do
      :user_exists ->
        IO.inspect({:error, crear_usuario: "El nombre de usuario ya se encuentra en uso."})

      :user_not_found ->
        IO.inspect({:error, editar_usuario: "No se encontró el usuario."})

      :invalid_update ->
        IO.inspect({:error, editar_usuario: "No se pudo actualizar el usuario."})

      _ ->
        IO.puts("Error desconocido: #{inspect(reason)}")
    end
  end
end
