defmodule ExpenseTracker.Categories do
  @moduledoc """
  The Categories context.
  """

  import Ecto.Query, warn: false

  alias ExpenseTracker.Repo
  alias ExpenseTracker.Categories.ExpenseCategory

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
end
