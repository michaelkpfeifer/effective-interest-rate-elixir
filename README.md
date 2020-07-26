### Introduction

The EffectiveInterestRate module provides a function for computing the
effective interest rate of a strem of payments in a very general case.

### Payment Streams

A *payment* is a tuple `{amount, date}` consisting of an amount (in
whatever currency) and a date. The amount can be positive or negative.

For example, `{-2000, ~D[2015-01-01]}` represents an amount of -2000
transferred at Jan 01, 2015.

A *payment stream* is a list of payments.

### Example

```
$ iex -S mix
Erlang/OTP 23 [erts-11.0.2] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe]

Interactive Elixir (1.10.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> payments = [{-2000, ~D[2015-01-01]},
...(1)> {1000, ~D[2016-01-01]},
...(1)> {1000, ~D[2017-01-01]},
...(1)> {200, ~D[2017-01-01]}]
[
  {-2000, ~D[2015-01-01]},
  {1000, ~D[2016-01-01]},
  {1000, ~D[2017-01-01]},
  {200, ~D[2017-01-01]}
]
iex(2)> EffectiveInterestRate.effective_interest_rate(payments)
{:ok, 0.06394102980498531}
```

### Documentation

Run`mix docs`

### Tests

Run `mix test`
