defmodule ExpenseTrackerWeb.Format.Currency do
  @moduledoc """
  Module for formatting currency amounts.
  """

  alias Decimal, as: D

  @doc """
  Formats an amount in cents to a currency string.

  ## Examples

    iex> format_currency(1000, "USD")
    "$10.00"
  """
  @spec format_currency(integer(), String.t()) :: String.t()
  def format_currency(amount, currency) do
    amount
    |> D.round(2)
    |> D.div(100)
    |> D.to_float()
    |> :erlang.float_to_binary(decimals: 2)
    |> format_string(currency)
  end

  defp format_string(amount, "USD") do
    "$#{amount}"
  end

  defp format_string(amount, currency) do
    "#{currency} #{amount}"
  end
end
