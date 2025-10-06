defmodule Ledger do
  alias Ledger.Parser.Parser

  def main(args) do
    case Parser.parser_args(args) do
      {:transacciones, config} -> IO.inspect(config)
      {:balance, config} -> IO.inspect(config)
      {:error, config} -> IO.inspect(config)
    end
  end
end
