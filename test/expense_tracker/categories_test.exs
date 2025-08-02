defmodule ExpenseTracker.CategoriesTest do
  use ExpenseTracker.DataCase

  alias ExpenseTracker.Categories
  alias ExpenseTracker.Categories.ExpenseCategory

  describe "list_expense_categories/0" do
    test "returns a list of expense categories" do
      assert Categories.list_expense_categories() == []
    end
  end

  describe "create_expense_category/1" do
    test "creates a new expense category" do
      assert {:ok, %ExpenseCategory{}} =
               Categories.create_expense_category(%{name: "Test Category", monthly_budget: 1000})
    end
  end
end
