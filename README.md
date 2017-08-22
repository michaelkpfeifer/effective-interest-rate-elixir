# Introduction

The EffectiveInterestRate module provides a function for computing
effective interest rates of a series of payments in a very general
case.

# Installation

Copy lib/effective_interest_rate.ex to a place where your application
can find it.

# Data Structures

A payment is a tuple '{amount, date}' consisting of the amount of the
payment and the date of the payment. For example,
'{-2000, ~D[2015-01-01]}' represents a payment of -2000 at January 01,
2015. A series of payments is represented as a list of payments.

# Example


```
$ iex
Erlang/OTP 20 [erts-9.0] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (1.5.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> c("effective_interest_rate.ex")
[EffectiveInterestRate]
iex(2)> payments_with_date = [{-2000, ~D[2015-01-01]},
...(2)> {1000, ~D[2016-01-01]},
...(2)> {1000, ~D[2017-01-01]},
...(2)> {200, ~D[2017-01-01]}]
[{-2000, ~D[2015-01-01]}, {1000, ~D[2016-01-01]}, {1000, ~D[2017-01-01]},
 {200, ~D[2017-01-01]}]
iex(3)> EffectiveInterestRate.effective_interest_rate(payments_with_date)
0.06394102980498531
iex(4)>
```
