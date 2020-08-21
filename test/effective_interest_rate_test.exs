defmodule EffectiveInterestRateTest do
  use ExUnit.Case
  doctest EffectiveInterestRate

  test "effective interest rate is 0 in a very simple case" do
    payments = [{2000, ~D[2013-06-01]}, {-1000, ~D[2014-06-01]}, {-1000, ~D[2015-06-01]}]

    {:ok, effective_interest_rate} = EffectiveInterestRate.effective_interest_rate(payments)

    assert_in_delta(0.0, effective_interest_rate, 1.0e-6)
  end

  test "effective interest rate has the expected sign in a simple case" do
    payments = [
      {2000, ~D[2013-06-01]},
      {-1000, ~D[2014-06-01]},
      {-1000, ~D[2015-06-01]},
      {-100, ~D[2015-07-01]}
    ]

    {:ok, effective_interest_rate} = EffectiveInterestRate.effective_interest_rate(payments)

    assert effective_interest_rate > 0
  end

  test "effective interest rate returns the expected value for a stream of monthly payments" do
    payments =
      [{240_000, ~D[2015-01-01]}] ++
        for year <- Enum.to_list(2015..2034), month <- Enum.to_list(1..12) do
          {:ok, date} = Date.new(year, month, 1)
          {-1200, date}
        end

    {:ok, effective_interest_rate} = EffectiveInterestRate.effective_interest_rate(payments)

    assert_in_delta(1.91 / 100, effective_interest_rate, 1.0e-3)
  end

  test "effective interest rate returns the expected value for simple real life case" do
    payments = [{-1065.25, ~D[2011-04-21]}, {130.69, ~D[2014-05-23]}]

    {:ok, effective_interest_rate} = EffectiveInterestRate.effective_interest_rate(payments)

    assert_in_delta(-0.4931, effective_interest_rate, 1.0e-3)
  end
end
