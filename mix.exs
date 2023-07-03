defmodule KinoMembrane.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/membraneframework/kino_membrane"

  def project do
    [
      app: :kino_membrane,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      aliases: [
        setup: ["cmd npm ci --prefix assets", "deps.get"],
        build: ["cmd npm run build --prefix assets", "compile"]
      ],

      # hex
      description: "Dashboard for introspecting Membrane pipelines",
      package: package(),

      # docs
      name: "Membrane Kino dashboard",
      source_url: @github_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:membrane_core, github: "membraneframework/membrane_core", branch: "dashboard-0.12"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      },
      files:
        Path.wildcard("assets/*/{src,precompiled}/**") ++
          Path.wildcard("assets/*/{package.json,package-lock.json}") ++
          ~w(assets/calc_fingerprint.sh lib LICENSE mix.exs README.md .formatter.exs)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"] ++ Path.wildcard("examples/**"),
      groups_for_extras: [Examples: ~r/examples\/*/],
      formatters: ["html"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [KinoMembrane]
    ]
  end
end
