defmodule EffectiveInterestRateTest do
  use ExUnit.Case
  doctest EffectiveInterestRate

  test "first payment of a list of one payments is the only payment in the list" do
    payments_with_date = [{2000, ~D[2015-06-01]}]
    first_payment_with_date = EffectiveInterestRate.first_payment_with_date(payments_with_date)
    assert {2000, ~D[2015-06-01]} == first_payment_with_date
  end

  test "first payment of a list of payments is the oldest payment in the list" do
    payments_with_date = [{-1000, ~D[2015-06-01]},
                          {-1000, ~D[2014-06-01]},
                          {2000, ~D[2013-06-01]},
                          {-100, ~D[2015-07-01]}]
    first_payment_with_date = EffectiveInterestRate.first_payment_with_date(payments_with_date)
    assert {2000, ~D[2013-06-01]} == first_payment_with_date
  end

  test "offset in year respects leap year" do
    assert 0 / 365 == EffectiveInterestRate.offset_in_year(~D[2015-01-01])
    assert 0 / 366 == EffectiveInterestRate.offset_in_year(~D[2016-01-01])
    assert 1 / 365 == EffectiveInterestRate.offset_in_year(~D[2015-01-02])
    assert 1 / 366 == EffectiveInterestRate.offset_in_year(~D[2016-01-02])
    assert 364 / 365 == EffectiveInterestRate.offset_in_year(~D[2015-12-31])
    assert 365 / 366 == EffectiveInterestRate.offset_in_year(~D[2016-12-31])
  end

  test "payment offset takes first payment date into consideration" do
    payment_offset_1 = EffectiveInterestRate.payment_offset({1000, ~D[2015-01-01]}, 2015, 0)
    assert 0.0 == payment_offset_1
    payment_offset_2 = EffectiveInterestRate.payment_offset({1000, ~D[2016-01-01]}, 2015, 0)
    assert 1.0 == payment_offset_2
    payment_offset_3 = EffectiveInterestRate.payment_offset({1000, ~D[2016-07-02]}, 2016, 0)
    assert 0.5 == payment_offset_3
    payment_offset_4 = EffectiveInterestRate.payment_offset({1000, ~D[2016-07-02]}, 2016, 0.5)
    assert 0.0 == payment_offset_4
  end

  test "conversion to payments with offsets succeeds in trvial case" do
    payments_with_date = [{2000, ~D[2015-06-01]}]
    payments_with_offset = EffectiveInterestRate.convert_to_payments_with_offset(payments_with_date)
    [{payment, offset}] = payments_with_offset
    assert 2000 == payment
    assert 0.0 == offset
  end

  test "conversion to payments with offsets succeeds in simple case" do
    payments_with_date = [{2000, ~D[2013-06-01]},
			  {-1000, ~D[2014-06-01]},
			  {-1000, ~D[2015-06-01]},
			  {-100, ~D[2015-07-01]}]
    payments_with_offset = EffectiveInterestRate.convert_to_payments_with_offset(payments_with_date)
    payments = Enum.map(payments_with_offset, fn(entry) -> elem(entry, 0) end)
    [offset1, offset2, offset3, offset4] = Enum.map(payments_with_offset, fn(entry) -> elem(entry, 1) end)
    assert [2000, -1000, -1000, -100] == payments
    assert 0.0 == offset1
    assert 1.0 == offset2
    assert 2.0 == offset3
    assert 2.05 < offset4
    assert 2.1 > offset4
  end

  test "evaluation of sum expression returns expected sum" do
    payments_with_date = [{2000, ~D[2013-06-01]},
			  {-1000, ~D[2014-06-01]},
			  {-1000, ~D[2015-06-01]}]
    payments_with_offset = EffectiveInterestRate.convert_to_payments_with_offset(payments_with_date)
    value0 = EffectiveInterestRate.evaluate(payments_with_offset, 0.0)
    assert 0.0 == value0
    value1 = EffectiveInterestRate.evaluate(payments_with_offset, 1.0)
    assert 1250.0 == value1
  end

  test "derivative of terms in sum shows expected results" do
    assert {0.0, 1.0} == EffectiveInterestRate.derive_payment_with_offset({1000.0, 0.0})
    assert {-1000.0, 2.0} == EffectiveInterestRate.derive_payment_with_offset({1000.0, 1.0})
    assert {-2000.0, 3.0} == EffectiveInterestRate.derive_payment_with_offset({1000.0, 2.0})
    assert {-500.0, 1.5} == EffectiveInterestRate.derive_payment_with_offset({1000.0, 0.5})
  end

  test "effective interest rate is correct for very simple case" do
    payments_with_date = [{2000, ~D[2013-06-01]},
  			  {-1000, ~D[2014-06-01]},
  			  {-1000, ~D[2015-06-01]}]
    effective_interest_rate = EffectiveInterestRate.effective_interest_rate(payments_with_date)
    assert abs(effective_interest_rate) < 10.0e-6
  end

  test "effective interest rate is correct for simple case" do
    payments_with_date = [{2000, ~D[2013-06-01]},
  			  {-1000, ~D[2014-06-01]},
  			  {-1000, ~D[2015-06-01]},
  			  {-100, ~D[2015-07-01]}]
    effective_interest_rate = EffectiveInterestRate.effective_interest_rate(payments_with_date)
    assert effective_interest_rate > 0
  end

  test "effective interest rate is correct for series of monthly payments" do
    payments_with_date = [{240000, ~D[2015-01-01]}] ++
    for year <- Enum.to_list(2015..2034), month <- Enum.to_list(1..12) do
      {:ok, date} = Date.new(year, month, 1)
      {-1200, date}
    end
    effective_interest_rate = EffectiveInterestRate.effective_interest_rate(payments_with_date)
    assert abs(effective_interest_rate - 1.91/100) < 10.0e-4
  end

  test "effective interest rate is correct for simple real life case" do
    payments_with_date = [{-1065.25, ~D[2011-04-21]},
  			  {130.69, ~D[2014-05-23]}]
    effective_interest_rate = EffectiveInterestRate.effective_interest_rate(payments_with_date)
    assert abs(effective_interest_rate - (- 0.4931)) < 0.0001
  end
end
