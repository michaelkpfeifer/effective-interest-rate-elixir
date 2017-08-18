defmodule EffectiveInterestRate do
  @max_iterations 64
  @max_diff_iterations 10.0e-10

  @moduledoc """
  EffectiveInterestRate implements the computation of the effective
  interest rate of a series of payments in a very general case.
  """

  def effective_interest_rate(payments_with_date) do
    payments_with_offset = convert_to_payments_with_offset(payments_with_date)
    payments_with_offset_derivative = Enum.map(payments_with_offset, fn(payment_with_offset) ->
      derive_payment_with_offset(payment_with_offset)
    end)
    effective_interest_rate(payments_with_offset, payments_with_offset_derivative, 0, -0.75)
  end

  defp effective_interest_rate(_, _, @max_iterations, iteration) do
    iteration
  end

  defp effective_interest_rate(payments_with_offset,
    payments_with_offset_derivative,
    iterations_count,
    previous_iteration) do
    nominator = evaluate(payments_with_offset, previous_iteration)
    denominator = evaluate(payments_with_offset_derivative, previous_iteration)
    next_iteration = previous_iteration - (nominator / denominator)
    if abs(next_iteration - previous_iteration) < @max_diff_iterations do
      next_iteration
    else
	effective_interest_rate(payments_with_offset,
	  payments_with_offset_derivative,
	  iterations_count + 1,
	  next_iteration)
    end
  end

  @doc """
  first_payment_with_date returns the oldest payment in a list of
  payments with date.

  ## Examples

      iex> EffectiveInterestRate.first_payment_with_date([{1000, ~D[2000-01-01]}, {1000, ~D[2001-01-01]}])
      {1000, ~D[2000-01-01]}

  """
  def first_payment_with_date([payment_with_date | remaining_payments_with_date]) do
    first_payment_with_date(payment_with_date, remaining_payments_with_date)
  end

  defp first_payment_with_date(payment_with_date, []) do
    payment_with_date
  end

  defp first_payment_with_date(payment_with_date, [next_payment_with_date | next_remaining_payments_with_date]) do
    {_, date} = payment_with_date
    {_, next_date} = next_payment_with_date
    if (date < next_date) do
      first_payment_with_date(payment_with_date, next_remaining_payments_with_date)
    else
      first_payment_with_date(next_payment_with_date, next_remaining_payments_with_date)
    end
  end

  def offset_in_year(date) do
    year = date.year
    {:ok, jan_first} = Date.new(year, 1, 1)
    number_of_days = Date.diff(date, jan_first)

    if Date.leap_year?(date) do
      number_of_days / 366
    else
      number_of_days / 365
    end
  end

  def payment_offset(payment_with_date, first_payment_year, first_payment_offset) do
    {_, payment_date} = payment_with_date
    year = payment_date.year
    year_difference = year - first_payment_year
    payment_offset_in_year = offset_in_year(payment_date)
    payment_offset_in_year + year_difference - first_payment_offset
  end

  def convert_to_payments_with_offset(payments_with_date) do
    {_, first_payment_date} = first_payment_with_date(payments_with_date)
    first_payment_offset = offset_in_year(first_payment_date)
    first_payment_year = first_payment_date.year
    Enum.map(payments_with_date, fn(payment_with_date) ->
      {payment, _} = payment_with_date
      offset = payment_offset(payment_with_date, first_payment_year, first_payment_offset)
      {payment, offset}
    end)
  end

  def evaluate(terms, x) do
    List.foldl(terms,
      0,
      fn(term, sum) ->
	{amount, offset} = term
	sum + amount * :math.pow((1 + x), -offset)
      end
    )
  end

  def derive_payment_with_offset(payment_with_offset) do
    {amount, offset} = payment_with_offset
    {-offset * amount, -(-offset - 1)}
  end
end
