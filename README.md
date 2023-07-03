# Membrane Kino Dashboard

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_kino_dashboard.svg)](https://hex.pm/packages/membrane_kino_dashboard)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_kino_dashboard)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_kino_dashboard.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_kino_dashboard)

Dashboard for introspecting [Membrane](https://membraneframework.org) pipelines. Can be used via [Livebook](https://livebook.dev/).

## Installation

The package can be installed by adding `membrane_kino_dashboard` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_kino_dashboard, "~> 0.1.0"}
  ]
end
```

or by calling

```elixir
Mix.install([:membrane_kino_dashboard])
```

## Usage

To run the dashboard, install `:membrane_kino_dashboard` as described above, and type the following in a [Livebook](https://livebook.dev/) cell:

```elixir
Membrane.Kino.pipeline_dashboard(pipeline)
```

The pipeline can either be started within the Livebook (see [example](examples/pipeline_in_livebook.livemd)) or you can connect to a node where the pipeline is running (see [example](examples/connect_to_node.livemd)).

## Development

This package contains JavaScript subproject. It's precompiled, so you only need to compile them if you change its code or need to generate a source map. In that case, run

```sh
mix setup # fetches JS and Elixir deps
mix build # compiles JS and Elixir code
```

or compile each project manually

```sh
npm ci --prefix assets
npm run build --prefix assets
mix deps.get
mix compile
```

## Copyright and License

Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_kino_dashboard)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_kino_dashboard)

Licensed under the [Apache License, Version 2.0](LICENSE)
