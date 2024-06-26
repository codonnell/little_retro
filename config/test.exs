import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :little_retro, LittleRetro.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "little_retro_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Configure your database
config :little_retro, LittleRetro.EventStore,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "little_retro_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We start commanded manually to make the SQL sandbox work
config :little_retro,
  start_commanded: false,
  consistency: :strong

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :little_retro, LittleRetroWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "/ZihpwR7RlL0lB27fKeRAYHdQEsOr/g3qOxO37W1CCf4MIuwiRwlic6CW391iPbL",
  server: false

# In test we don't send emails.
config :little_retro, LittleRetro.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
