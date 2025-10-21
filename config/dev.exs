import Config

config :ledger, Ledger.Repo,
  username: "postgres",
  password: "example",
  database: "midb",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
