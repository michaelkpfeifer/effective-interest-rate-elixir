defmodule NewtonIterationTest do
  use ExUnit.Case
  doctest NewtonIteration

  describe "iterate/5" do
    test "iterate finds the root of the identity function" do
      f = fn x -> x end
      fp = fn _x -> 1 end

      {:ok, root} = NewtonIteration.iterate(f, fp, 1.0, 1.0e-9, 4)

      assert_in_delta(root, 0.0, 1.0e-9)
    end

    test "iterate does not find the root of x^4 - 1 with the desired accuracy in 4 iterations" do
      f = fn x -> :math.pow(x, 4) - 1 end
      fp = fn x -> 4 * :math.pow(x, 3) end

      assert NewtonIteration.iterate(f, fp, 2.0, 1.0e-9, 4) == :error
    end

    test "iterate finds the root of x^4 - 1 with the desired accuracy in less than 8 iterations" do
      f = fn x -> :math.pow(x, 4) - 1 end
      fp = fn x -> 4 * :math.pow(x, 3) end

      {:ok, root} = NewtonIteration.iterate(f, fp, 2.0, 1.0e-9, 8)

      assert_in_delta(root, 1.0, 1.0e-9)
    end
  end
end
