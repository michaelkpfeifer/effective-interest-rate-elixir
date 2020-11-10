defmodule PaymentStream do
  @moduledoc """

  The PaymentStream module provides utilities for dealing with streams
  of payments.

  ## Payment Streams

  A *payment* is a tuple `{amount, date}` consisting of an amount (in
  whatever currency) and a date. The amount can be positive or
  negative.

  For example, `{-2000, ~D[2015-01-01]}` represents an amount of -2000
  transferred at Jan 01, 2015.

  A *payment stream* is a list of payments.

  ## Relative Payment Streams

  Let `[{a_1, t_1}, ..., {a_n, t_n}]` be a payment stream and let
  `{a_f, t_f}` be the earliest payment in this stream. A *relative
  payment stream* is a list `[{a_1, r_1}, ..., {a_n, r_n}]` where
  `r_k` is the difference of `t_k` and `t_f` "expressed in years".

  More precisely, `r_k` is computed as follows: Let `t_f` be the
  `d_f`th day in a year `y_f` and let `t_k` be the `d_k`th day in year
  `y_k`. (Days are indexed starting at `0`. Jan 01 is day `0`.)  Let
  `D(y)` denote the number of days in a year `y`. For a leap year `y`,
  `D(y)` is 366. Otherwise, `D(y)` is 365. Then

    ```
    r_k = (y_k - y_f) + (d_k / D(y_k) - d_f / D(y_f)).
    ```

  ## The Net Present Value Function

  A relative payment stream `[{a_1, r_1}, ..., {a_n, r_n}]` gives rise
  to the definition of the net present value function

    ```
    npv(x) = a_1 * (1 + x)^(-r_1) + ... + a_n * (1 + x)^(-r_n)
    ```

  of single real variable `x`. The internal interest rate of the
  original payment stream is the root of the `npv` function.

  In general, there is no closed formula for the computation of the
  roots of `npv`. However, given a "reasonable" start value, Newton's
  method converges very fast to the wanted root.

  Newton's method requires the computation of the derivative `npv'` of
  `npv`.  Fortunately, `npv'` can be easily written in a closed form:

    ```
    npv' = a_1 * (-r_1) * (1 + x)^(-r_1 - 1) + ... + a_n * (-r_n) * (1 + x)^(-r_n - 1)
    ```

  """

  @doc ~S"""

  Finds the earliest payment in a payment stream.

  ## Examples

    ```
    iex> PaymentStream.earliest_payment([{-1000, ~D[2021-01-01]}, {1000, ~D[2020-01-01]}])
    {1000, ~D[2020-01-01]}
    ```

  """

  def earliest_payment(payment_stream) do
    Enum.sort_by(payment_stream, fn {_amount, date} -> date end) |> Enum.at(0)
  end

  @doc ~S"""

  Converts a payment stream to a relative payment stream.

  ## Examples

    ```
    iex> PaymentStream.to_relative_payment_stream([{1000, ~D[2020-01-01]}, {1000, ~D[2021-01-01]}])
    [{1000, 0.0}, {1000, 1.0}]
    ```

  """

  def to_relative_payment_stream(payment_stream) do
    t_f = earliest_payment(payment_stream)
    Enum.map(payment_stream, fn payment -> to_relative_payment(t_f, payment) end)
  end

  defp to_relative_payment({_a_f, t_f}, {a_k, t_k}) do
    {a_k, t_k.year - t_f.year + relative_day_in_year(t_k) - relative_day_in_year(t_f)}
  end

  defp relative_day_in_year(t) do
    d = day_in_year(t)

    if Date.leap_year?(t) do
      d / 366
    else
      d / 365
    end
  end

  defp day_in_year(t) do
    {:ok, jan01} = Date.new(t.year, 1, 1)
    Date.diff(t, jan01)
  end

  @doc ~S"""

  Computes the net present value function `npv`of a relative payment
  stream.

  ## Examples

  Let `[{1000, ~D[2021-01-01]}, {-1000, ~D[2022-01-01]}]` be a very
  simple payment stream. Since the amount payed on Jan 01, 2021 is the
  negative of the amount received one year later on Jan 01, 2022, the
  internal interest rate for this payment stream should be `0`.

  The relative payment stream corresponding to the payment stream
  above is `[{1000, 0.0}, {-1000, 1.0}]` and then the corresponding
  `npv` function is

    ```
    npv(x) = 1000 * (1 + x)^0.0 + (-1000) * (1 + x)^-1.0
    ```

  so that

    ```
    npv(0) = 1000 * (1 + 0)^0.00 + (-1000) * (1 + 0)^-1.0
           = 1000 * 1 - 1000 * 1
           = 0
    ```

    ```
    iex> [{1000, ~D[2021-01-01]}, {-1000, ~D[2022-01-01]}]
    ...> |> PaymentStream.to_relative_payment_stream()
    ...> |> PaymentStream.net_present_value()
    ...> |> apply([0.0])
    0.0
    ```

  """

  def net_present_value(relative_payment_stream) do
    fn x ->
      Enum.reduce(
        relative_payment_stream,
        0,
        fn {a, r}, sum -> sum + a * :math.pow(1 + x, -r) end
      )
    end
  end

  @doc ~S"""

  Computes the derivative `npv'` of the net present value function of
  a relative payment stream.

  ## Examples

  Let `[{1000, 0.0}, {-1000, 1.0}]` be very simple realtive payment
  stream with a corrsponding net present value function

    ```
    npv(x) = 1000 * (1 + x)^0.0 + (-1000) * (1 + x)^(-1.0)
    ```

  Then the derivative of `npv` is

    ```
    npv'(x) = 0.0 * 1000 * (1 + x)^(-1.0) + (-1.0) * (-1000) * (1 + x)^-(2.0)
            = 1000 * (1 + x)^(-2.0)
    ```

    ```
    iex> [{1000, 0.0}, {-1000, 1.0}]
    ...> |> PaymentStream.net_present_value_derivative()
    ...> |> apply([0.0])
    1000.0
    ```
  """

  def net_present_value_derivative(relative_payment_stream) do
    fn x ->
      Enum.reduce(
        relative_payment_stream,
        0,
        fn {a, r}, sum -> sum + a * -r * :math.pow(1 + x, -r - 1) end
      )
    end
  end
end
