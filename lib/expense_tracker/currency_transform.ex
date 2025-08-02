defmodule ExpenseTracker.CurrencyTransform do
  @moduledoc """
  Module for transforming currency amounts from string to integer.
  """

  alias Decimal, as: D

  @doc """
  Transforms a currency amount from a string to an integer.

  ## Examples

    iex> transform_amount("100.00", "USD")
    10000

    iex> transform_amount("100.00", "EUR")
    ** (RuntimeError) Currency not supported
  """
  @spec transform_amount(String.t(), String.t()) :: integer()
  def transform_amount(amount, "USD") do
    amount |> D.round(2) |> D.new() |> D.mult(100) |> D.to_integer()
  end

  def transform_amount(_, _) do
    raise "Currency not supported"
  end
end
