# LittleRetro

A simple, fast, reactive, and easy to use retro platform. Still a work in progress!

To get the validated elixir and erlang versions using `asdf`:
  * Install `asdf` with `brew install asdf` or following the [instructions](https://asdf-vm.com/guide/getting-started.html)
    * If you install with homebrew, make sure to source the shim in your shell as explained [here](https://asdf-vm.com/guide/getting-started.html#_3-install-asdf).
  * Install `asdf-erlang` with `asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git`
  * Install `asdf-elixir` with `asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git`
  * Install the validated erlang and elixir versions with `asdf install` (it may take a few minutes to compile erlang)

To start your Phoenix server:

  * Run `mix deps.get` to get dependencies
  * Run `mix do event_store.create, event_store.init` to initialize the event store
    * If you get an error about a `postgres` user not existing, you can run `psql -c "create user postgres superuser with password 'postgres'"` and try again
  * Run `cd assets && yarn install && cd ..` to install JS dependencies
  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## How to add a new retro action

1. Write domain-level tests [here](test/little_retro/retros_test.exs).
1. Add an implementing domain function [here](lib/little_retro/retros.ex).
1. Add an implementing command [here](lib/little_retro/retros/commands).
1. Add the command to the router [here](lib/little_retro/retros/router.ex).
1. Add an implementing event [here](lib/little_retro/retros/events).
1. Implement `execute` and `apply` functions for the command and event in the [aggregate](lib/little_retro/aggregates/retro.ex).
1. Publish the event via `Phoenix.PubSub` [here](lib/little_retro/retros/event_handlers/retro_pub_sub.ex).
1. If it is a custom pubsub event, add a handler to it in the liveview [here](lib/little_retro_web/live/retro_live.ex).
1. Implement the UI using the [liveview](lib/little_retro_web/live/retro_live.ex) and [component](lib/little_retro_web/components/retro_components.ex) modules.
1. If feasible, add liveview tests for the action [here](test/little_retro_web/live/retro_live_test.exs).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
