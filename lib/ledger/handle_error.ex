defmodule Ledger.HandleError do
  def handle_usuario({:error, reason}) do
    case reason do
      :user_exists ->
        IO.inspect({:error, crear_usuario: "El nombre de usuario ya se encuentra en uso."})

      :user_not_found ->
        IO.inspect({:error, editar_usuario: "No se encontró el usuario."})

      :invalid_update ->
        IO.inspect({:error, editar_usuario: "No se pudo actualizar el usuario."})

      :invalid_age ->
        IO.inspect({:error, crear_usuario: "El usuario debe ser mayor de 18 años."})

      :same_name ->
        IO.inspect({:error, editar_usuario: "El nuevo nombre no puede ser igual al actual."})

      _ ->
        IO.puts("Error desconocido: #{inspect(reason)}")
    end
  end

  def handle_monedas({:error, reason}) do
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

      _ ->
        IO.puts("Ocurrió un error desconocido al crear la moneda: #{inspect(reason)}")
    end
  end

  def handle_transacciones({:error, reason}) do
    case reason do
      :user_not_found ->
        IO.inspect({:error, alta_cuenta: "No se encontró el usuario."})

      :moneda_not_found ->
        IO.inspect({:error, alta_cuenta: "No se encontró la moneda."})

      :invalid_amount ->
        IO.inspect({:error, alta_cuenta: "El monto debe ser un número positivo."})

      :insufficient_funds ->
        IO.inspect({:error, transferencia: "Fondos insuficientes para realizar la transferencia."})

      :cuenta_origen_no_existe -> 
        IO.puts("Error: El usuario origen no tiene cuenta activa en esta moneda")
      
      :cuenta_destino_no_existe -> 
        IO.puts("Error: El usuario destino no tiene cuenta activa en esta moneda")
      
      :cuenta_ya_existe -> 
        IO.puts("Error: Ya existe una cuenta activa para este usuario en esta moneda")
      _ ->
        IO.puts("Ocurrió un error desconocido en la transacción: #{inspect(reason)}")
    end
  end
end
