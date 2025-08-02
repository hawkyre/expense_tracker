defmodule ExpenseTracker.Categories do
  @moduledoc """
  The Categories context.
  """

  import Ecto.Query, warn: false

  alias ExpenseTracker.Repo
  alias ExpenseTracker.Categories.ExpenseCategory
  alias ExpenseTracker.Categories.Expense

  @doc """
  Returns the list of all expense categories.
  """
  @spec list_expense_categories() :: [ExpenseCategory.t()]
  def list_expense_categories do
    Repo.all(ExpenseCategory)
  end

  @doc """
  Creates a new expense category.

  Returns `{:ok, %ExpenseCategory{}}` if the category is created successfully,
  or `{:error, %Ecto.Changeset{}}` if the arguments are invalid.
  """
  @spec create_expense_category(map()) ::
          {:ok, ExpenseCategory.t()} | {:error, Ecto.Changeset.t()}
  def create_expense_category(attrs) do
    attrs
    |> ExpenseCategory.create_changeset()
    |> Repo.insert()
  end

  @doc """
  Gets a specific category.
  """
  @spec get_category(integer()) :: ExpenseCategory.t() | nil
  def get_category(category_id) do
    Repo.get(ExpenseCategory, category_id)
  end

  @doc """
  Gets a specific category with its most recent 5 expenses and total expense sum.

  Returns a map with category info, recent expenses, and total sum, or nil if not found.
  """
  @spec get_category_with_expenses(integer()) ::
          %{
            category: ExpenseCategory.t(),
            recent_expenses: [Expense.t()],
            total_expenses_sum: integer()
          }
          | nil
  def get_category_with_expenses(category_id) do
    case Repo.get(ExpenseCategory, category_id) do
      nil ->
        nil

      category ->
        recent_expenses_query =
          from(e in Expense,
            where: e.category_id == ^category_id,
            order_by: [desc: e.date],
            limit: 5
          )

        recent_expenses = Repo.all(recent_expenses_query)
        total_sum = get_sum_of_expenses_in_date_month(category_id, Date.utc_today()) || 0

        %{
          category: category,
          recent_expenses: recent_expenses,
          total_expenses_current_month: total_sum
        }
    end
  end

  @doc """
  Gets the sum of expenses for a given category, in the month of the provided date.
  """
  @spec get_sum_of_expenses_in_date_month(integer(), Date.t()) :: integer()
  def get_sum_of_expenses_in_date_month(category_id, date) do
    first_day = Date.beginning_of_month(date)
    last_day = Date.end_of_month(date)

    Repo.aggregate(
      from(e in Expense,
        where: e.category_id == ^category_id,
        where: e.date >= ^first_day,
        where: e.date <= ^last_day
      ),
      :sum,
      :base_amount
    ) || 0
  end
end
