defmodule PaymentStreamTest do
  use ExUnit.Case
  doctest PaymentStream

  describe "earliest_payment/1" do
    test "earliest payment of a stream of of one payments is the given payment" do
      payment = {1000, ~D[2020-01-01]}
      payment_stream = [payment]

      assert PaymentStream.earliest_payment(payment_stream) == payment
    end

    test "earliest payment of a stream of payments is the earliest one" do
      earliest_payment = {-1000, ~D[2020-01-01]}
      payment = {500, ~D[2020-07-01]}
      newest_payment = {500, ~D[2021-01-01]}
      payment_stream = [newest_payment, payment, earliest_payment]

      assert PaymentStream.earliest_payment(payment_stream) == earliest_payment
    end
  end

  describe "to_relative_payment_stream/1" do
    test "relative date for payment stream with one payment is zero" do
      payment_stream = [{1000, ~D[2020-01-01]}]

      [{amount, relative_day_in_year}] = PaymentStream.to_relative_payment_stream(payment_stream)

      assert amount == 1000
      assert relative_day_in_year == 0.0
    end

    test "relative date for earliest payment in payment stream is zero" do
      earliest_payment = {-1000, ~D[2020-01-01]}
      payment = {500, ~D[2021-01-01]}
      newest_payment = {500, ~D[2022-01-01]}
      payment_stream = [earliest_payment, payment, newest_payment]

      assert PaymentStream.to_relative_payment_stream(payment_stream) == [
               {-1000, 0.0},
               {500, 1.0},
               {500, 2.0}
             ]
    end

    test "relative date respects non leap year" do
      payment_jan01 = {-1000, ~D[2019-01-01]}
      payment_jan02 = {500, ~D[2019-01-02]}
      payment_dec31 = {500, ~D[2019-12-31]}
      payment_stream = [payment_jan01, payment_jan02, payment_dec31]

      [{_, _}, {_, t_1}, {_, t_2}] = PaymentStream.to_relative_payment_stream(payment_stream)

      assert_in_delta(t_1, 1 / 365, 1.0e-9)
      assert_in_delta(t_2, 364 / 365, 1.0e-9)
    end

    test "relative date respects leap year" do
      payment_jan01 = {-1000, ~D[2020-01-01]}
      payment_jan02 = {500, ~D[2020-01-02]}
      payment_dec31 = {500, ~D[2020-12-31]}
      payment_stream = [payment_jan01, payment_jan02, payment_dec31]

      [{_, _}, {_, t_1}, {_, t_2}] = PaymentStream.to_relative_payment_stream(payment_stream)

      assert_in_delta(t_1, 1 / 366, 1.0e-9)
      assert_in_delta(t_2, 365 / 366, 1.0e-9)
    end

    test "leap years are respected across year boundaries" do
      first_payment = {-1000, ~D[2019-12-01]}
      second_payment = {1000, ~D[2020-01-31]}
      payment_stream = [first_payment, second_payment]

      [{_, _}, {_, t_1}] = PaymentStream.to_relative_payment_stream(payment_stream)

      assert_in_delta(t_1, 1 - 334 / 365 + 30 / 366, 1.0e-9)
    end
  end

  describe "net_present_value/1" do
    test "net present value for an interest rate of 0 is equal to the sum of amounts" do
      payment_1 = {-1000, ~D[2019-01-01]}
      payment_2 = {1600, ~D[2019-04-04]}
      payment_3 = {-2000, ~D[2019-07-07]}
      payment_4 = {1600, ~D[2019-10-10]}

      npv =
        [payment_1, payment_2, payment_3, payment_4]
        |> PaymentStream.to_relative_payment_stream()
        |> PaymentStream.net_present_value()

      assert_in_delta(npv.(0.0), 200.0, 1.0e-9)
    end

    test "net_present_value/1 returns the expected manually computed result" do
      payment_1 = {-1000, ~D[2019-01-01]}
      payment_2 = {500, ~D[2020-01-01]}
      payment_3 = {500, ~D[2021-01-01]}

      npv =
        [payment_1, payment_2, payment_3]
        |> PaymentStream.to_relative_payment_stream()
        |> PaymentStream.net_present_value()

      assert_in_delta(npv.(1.0), -625.0, 1.0e-9)
    end
  end

  describe "net_present_value_derivative/" do
    test "net_present_value_derivative/1 returns the expected manually computed result" do
      payment_1 = {-1000, ~D[2019-01-01]}
      payment_2 = {500, ~D[2020-01-01]}
      payment_3 = {500, ~D[2021-01-01]}

      npvp =
        [payment_1, payment_2, payment_3]
        |> PaymentStream.to_relative_payment_stream()
        |> PaymentStream.net_present_value_derivative()

      assert_in_delta(npvp.(1.0), -250.0, 1.0e-9)
    end
  end
end
