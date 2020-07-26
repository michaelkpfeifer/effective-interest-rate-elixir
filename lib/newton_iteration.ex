defmodule NewtonIteration do
  @moduledoc """

  The NewtonIteration module implements the computation of roots of
  real functions using Newton's method.

  """

  @doc ~S"""

  Runs Newton's iteration.

  `f` is an anonymous function of one real variable and `fp` is the
  derivative of `f`.

  `start_value` is the first value used in the iteration process.
  Usually, this is a guess of where the wanted root of `f` may be
  located.

  `max_iteration_difference` and `max_iterations` are used to
  terminate the iteration process.

  If the absolute value of the difference between two consecutive
  values produced by the iteration process is smaller than
  `max_iteration_difference`, then `iterate/5` returns `{:ok, x_k}`
  where `x_k` is the latest value produced by the iteration.

  If the absolute values of the difference between two consecutive
  values after `max_iterations` is still larger than
  `max_iteration_difference`, then `iterate/5` returns `:error`.

  ## Examples

  The root of the identity function `fn x -> x end` is `0`.

    ```
    iex> {:ok, root} = NewtonIteration.iterate(
    ...>   fn x -> x end,
    ...>   fn _x -> 1 end,
    ...>   1.0,
    ...>   1.0e-9,
    ...>   4
    ...> )
    ...> Float.round(root, 6)
    0.0
    ```

  The roots of the quadratic function `fn x -> x * x - 4 end` are `2`
  and `-2` but `4` iterations are not sufficient to compute the root
  with the required accuracy.

    ```
    iex> f = fn x -> x * x - 4 end
    ...> fp = fn x -> 2 * x end
    ...> NewtonIteration.iterate(f, fp, 4.0, 1.0e-9, 4)
    :error
    ...> {:ok, root} = NewtonIteration.iterate(f, fp, 4.0, 1.0e-9, 8)
    ...> Float.round(root, 6)
    2.0
    ```

  """

  def iterate(f, fp, start_value, max_iteration_difference, max_iterations) do
    iterate(f, fp, start_value, max_iteration_difference, max_iterations, 0)
  end

  defp iterate(_, _, _, _, max_iterations, iteration_count)
       when iteration_count > max_iterations do
    :error
  end

  defp iterate(
         f,
         fp,
         previous_iteration,
         max_iteration_difference,
         max_iterations,
         iteration_count
       ) do
    iteration = previous_iteration - f.(previous_iteration) / fp.(previous_iteration)

    if abs(iteration - previous_iteration) <= max_iteration_difference do
      {:ok, iteration}
    else
      iterate(f, fp, iteration, max_iteration_difference, max_iterations, iteration_count + 1)
    end
  end
end
