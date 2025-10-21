defmodule Ledger.Parser.Parser do
  alias Ledger.Parser.{Usuarios, Monedas, Transacciones}

  defp wrap_command(command, {:ok, map}), do: {command, {:ok, map}}
  defp wrap_command(_command, {:error, reason}), do: {:error, reason}

  def parser_args(["crear_usuario" | flags]),
    do: wrap_command(:crear_usuario, Usuarios.parse_crear(flags))

  def parser_args(["editar_usuario" | flags]),
    do: wrap_command(:editar_usuario, Usuarios.parse_editar(flags))

  def parser_args(["ver_usuario" | flags]),
    do: wrap_command(:ver_usuario, Usuarios.parse_id(flags))

  def parser_args(["borrar_usuario" | flags]),
    do: wrap_command(:borrar_usuario, Usuarios.parse_id(flags))

  def parser_args(["crear_moneda" | flags]),
    do: wrap_command(:crear_moneda, Monedas.parse_crear(flags))

  def parser_args(["editar_moneda" | flags]),
    do: wrap_command(:editar_moneda, Monedas.parse_editar(flags))

  def parser_args(["ver_moneda" | flags]),
    do: wrap_command(:ver_moneda, Monedas.parse_id(flags))

  def parser_args(["borrar_moneda" | flags]),
    do: wrap_command(:borrar_moneda, Monedas.parse_id(flags))

  def parser_args(["alta_cuenta" | flags]),
    do: wrap_command(:alta_cuenta, Transacciones.parse_alta_cuenta(flags))

  def parser_args(["realizar_transferencia" | flags]),
    do: wrap_command(:realizar_transferencia, Transacciones.parse_transferencia(flags))

  def parser_args(["realizar_swap" | flags]),
    do: wrap_command(:realizar_swap, Transacciones.parse_swap(flags))

  def parser_args(["deshacer_transaccion" | flags]),
    do: wrap_command(:deshacer_transaccion, Transacciones.parse_id(flags))

  def parser_args(["ver_transaccion" | flags]),
    do: wrap_command(:ver_transaccion, Transacciones.parse_id(flags))

  def parser_args(["balance" | flags]),
    do: wrap_command(:balance, Transacciones.parse_balance(flags))

  def parser_args(["listar_transacciones" | flags]),
    do: wrap_command(:listar_transacciones, Transacciones.parse_id_tp1(flags))

  def parser_args(_), do: {:error, :invalid_subcommand}
end
