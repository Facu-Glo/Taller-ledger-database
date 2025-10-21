import Config

config :ledger, Ledger.Repo,
  username: "postgres",
  password: "example",
  database: "midb",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true
