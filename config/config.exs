import Config

# TODO usar variables de entorno
config :ledger, Ledger.Repo,
  database: "midb",
  username: "postgres",
  password: "example",
  hostname: "localhost",
  port: 5432

config :ledger,
  ecto_repos: [Ledger.Repo]

config :logger, level: :info
import_config "#{config_env()}.exs"
