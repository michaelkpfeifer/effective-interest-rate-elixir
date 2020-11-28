defmodule EffectiveInterestRate do
  @start_value -0.75
  @max_iteration_difference 1.0e-9
  @max_iterations 64

  @moduledoc """

  The EffectiveInterestRate module implements the computation of the
  effective interest rate of a stream of payments in a very general
  case.

  Details about payment streams can be found in the documentation of
  the PaymentStream module.

  """

  @doc ~S"""

  Computes the effective interest rate of a payment stream

  ## Examples

    ```
    iex> payments = [{2000, ~D[2021-06-01]}, {-1000, ~D[2022-06-01]}, {-1000, ~D[2023-06-01]}]
    ...> {:ok, rate} = EffectiveInterestRate.effective_interest_rate(payments)
    ...> Float.round(rate, 6)
    0.0

    ```

  """

  def effective_interest_rate(payment_stream) do
    relative_payment_stream = PaymentStream.to_relative_payment_stream(payment_stream)

    NewtonIteration.iterate(
      PaymentStream.net_present_value(relative_payment_stream),
      PaymentStream.net_present_value_derivative(relative_payment_stream),
      @start_value,
      @max_iteration_difference,
      @max_iterations
    )
  end
end
