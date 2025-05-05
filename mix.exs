defmodule BroadwaySQSInit.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "A utility to ensure an SQS queue exists before starting a Broadway pipeline."

  def project do
    [
      app: :broadway_sqs_init,
      version: @version,
      elixir: "~> 1.18",
      description: @description,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.19.0", only: :dev},
      {:req, "~> 0.5", only: [:test, :dev]},
      {:broadway, ">= 0.0.0"},
      {:broadway_sqs, ">= 0.0.0"},
      {:ex_aws_sqs, ">= 0.0.0"},
      {:ex_aws, ">= 0.0.0"}
    ]
  end

  defp docs do
    [
      main: "BroadwaySQSInit",
      source_ref: "v#{@version}",
      source_url: "https://github.com/Talsky-Tech/BroadwaySQSInit",
    ]
  end

  defp package do
    %{
      name: "broadway_sqs_init",
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/Talsky-Tech/BroadwaySQSInit"}
    }
  end
end
