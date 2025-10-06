defmodule Ledger do
  alias Ledger.Parser.Parser

  def main(args) do
    IO.puts("Hello, Ledger!")
    IO.inspect(args)

    case Parser.parser_args(args) do
      {:transacciones, _config} -> IO.puts("TRANSACCION")
      {:balance, _config} -> IO.puts("BALANCE")
      {:error, _error} -> IO.puts("ERROR")
    end
  end
end
