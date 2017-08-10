defmodule EffectiveInterestRate.Mixfile do
  use Mix.Project

  def project do
    [
      app: :effective_interest_rate,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
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
      {:ex_doc, only: :dev},
      {:earmark, only: :dev}
    ]
  end
end
