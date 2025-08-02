defmodule ExpenseTracker.Expenses do
  @moduledoc """
  The Expenses context.
  """

  alias ExpenseTracker.Categories
  alias ExpenseTracker.Categories.Expense
  alias ExpenseTracker.Repo

  import Ecto.Changeset

  @doc """
  Creates a new expense for a given category.

  Returns `{:ok, %Expense{}}` if the expense is created successfully,
  or `{:error, %Ecto.Changeset{}}` if the arguments are invalid.
  """
  @spec create_expense(integer(), map()) ::
          {:ok, Expense.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def create_expense(category_id, attrs) do
    attrs = Map.put(attrs, "category_id", category_id)

    with %Ecto.Changeset{valid?: true} = cs <- Expense.create_changeset(attrs),
         :ok <-
           check_expense_within_budget(
             category_id,
             get_field(cs, :date),
             get_field(cs, :base_amount)
           ) do
      Repo.insert(cs)
    else
      %Ecto.Changeset{} = cs -> {:error, cs}
      error -> error
    end
  end

  defp check_expense_within_budget(category_id, date, amount) do
    %{monthly_budget: monthly_budget} = Categories.get_category(category_id)

    sum_of_expenses_in_month =
      Categories.get_sum_of_expenses_in_date_month(category_id, date)

    if sum_of_expenses_in_month + amount <= monthly_budget do
      :ok
    else
      {:error, "Monthly budget exceeded"}
    end
  end
end
