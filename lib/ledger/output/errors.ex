defmodule Ledger.Output.Errors do
  def error_usuario({:error, reason}) do
    case reason do
      :user_exists ->
        IO.inspect({:error, crear_usuario: "El nombre de usuario ya se encuentra en uso."})

      :user_not_found ->
        IO.inspect({:error, editar_usuario: "No se encontró el usuario."})

      :ver_user_not_found ->
        IO.inspect({:error, ver_usuario: "No se encontró el usuario."})

      :invalid_update ->
        IO.inspect({:error, editar_usuario: "No se pudo actualizar el usuario."})

      :invalid_age ->
        IO.inspect({:error, crear_usuario: "El usuario debe ser mayor de 18 años."})

      :same_name ->
        IO.inspect({:error, editar_usuario: "El nuevo nombre no puede ser igual al actual."})

      :user_has_transactions ->
        IO.inspect({:error, borrar_usuario: "El usuario tiene transacciones registradas."})

      :delete_failed ->
        IO.inspect({:error, borrar_usuario: "No se pudo eliminar el usuario."})

      _ ->
        IO.puts("Error desconocido: #{inspect(reason)}")
    end
  end

  def error_monedas({:error, reason}) do
    case reason do
      :nombre_corto ->
        IO.inspect({:error, crear_moneda: "El nombre de la moneda debe tener al menos 3 letras."})

      :nombre_largo ->
        IO.inspect(
          {:error, crear_moneda: "El nombre de la moneda no puede tener más de 4 letras."}
        )

      :nombre_formato_invalido ->
        IO.inspect({:error, crear_moneda: "El nombre de la moneda debe estar en mayúsculas."})

      :divisa_existe ->
        IO.inspect({:error, crear_moneda: "El nombre de la moneda ya se encuentra en uso."})

      :precio_invalido ->
        IO.inspect({:error, crear_moneda: "El precio de la moneda debe ser un número positivo."})

      :moneda_not_found ->
        IO.inspect({:error, editar_moneda: "No se encontró la moneda."})

      :invalid_update ->
        IO.inspect({:error, editar_moneda: "No se pudo actualizar la moneda."})

      :ver_moneda_not_found ->
        IO.inspect({:error, ver_moneda: "No se encontró la moneda."})

      :moneda_in_use ->
        IO.inspect({:error, borrar_moneda: "La moneda es parte de una transaccion"})

      _ ->
        IO.puts("Ocurrió un error desconocido al crear la moneda: #{inspect(reason)}")
    end
  end

  def error_transacciones({:error, tipo, reason}) do
    message =
      case reason do
        :not_found ->
          "No se encontró la transacción."

        :user_not_found ->
          "No se encontró el usuario."

        :moneda_not_found ->
          "No se encontró la moneda."

        :invalid_amount ->
          "El monto debe ser un número positivo."

        :insufficient_funds ->
          "Fondos insuficientes para realizar la operación."

        :cuenta_origen_no_existe ->
          "El usuario origen no tiene cuenta activa en esta moneda."

        :cuenta_destino_no_existe ->
          "El usuario destino no tiene cuenta activa en esta moneda."

        :cuenta_ya_existe ->
          "Ya existe una cuenta activa para este usuario en esta moneda."

        :no_hay_transacciones ->
          "El usuario no tiene transacciones registradas."

        :not_last ->
          "Solo se puede deshacer la ultima transacción realizada por los usuarios."

        _ ->
          "Ocurrió un error desconocido: #{inspect(reason)}"
      end

    IO.inspect({:error, [{tipo, message}]})
  end
end
