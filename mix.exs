defmodule EffectiveInterestRate.Mixfile do
  use Mix.Project

  def project do
    [
      app: :effective_interest_rate,
      version: "0.2.1",
      elixir: "~> 1.5",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, only: :dev, runtime: false},
      {:credo, only: :dev}
    ]
  end
end
