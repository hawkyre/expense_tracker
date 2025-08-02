defmodule ExpenseTracker.Categories.ExpenseCategoryTest do
  use ExpenseTracker.DataCase

  alias ExpenseTracker.Categories.ExpenseCategory

  describe "create_changeset/1" do
    test "creates a new expense category" do
      attrs = %{name: "Test Category", monthly_budget: 1000, description: "Test Description"}
      assert %Ecto.Changeset{valid?: true} = ExpenseCategory.create_changeset(attrs)
    end

    test "name cannot be empty" do
      attrs = %{name: "", monthly_budget: 1000}
      assert %Ecto.Changeset{errors: [name: _]} = ExpenseCategory.create_changeset(attrs)
    end

    test "budget cannot be negative or zero" do
      attrs = %{name: "Test Category", monthly_budget: -1000}

      assert %Ecto.Changeset{errors: [monthly_budget: _]} =
               ExpenseCategory.create_changeset(attrs)

      assert %Ecto.Changeset{errors: [monthly_budget: _]} =
               ExpenseCategory.create_changeset(%{attrs | monthly_budget: 0})
    end
  end
end
