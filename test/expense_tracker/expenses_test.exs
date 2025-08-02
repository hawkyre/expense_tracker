defmodule ExpenseTracker.ExpensesTest do
  alias ExpenseTracker.Categories
  alias ExpenseTracker.Categories.Expense
  alias ExpenseTracker.Expenses

  use ExpenseTracker.DataCase

  describe "create_expense/2" do
    setup do
      {:ok, category} =
        Categories.create_expense_category(%{
          name: "Test Category",
          monthly_budget: 100_000
        })

      %{category: category}
    end

    test "creates a new expense for a category", %{category: category} do
      attrs = %{
        "base_amount" => 1500,
        "date" => ~D[2025-01-01],
        "notes" => "Test expense"
      }

      assert {:ok, %Expense{} = expense} = Expenses.create_expense(category.id, attrs)
      assert expense.category_id == category.id
    end

    test "creates a new expense without optional notes", %{category: category} do
      attrs = %{
        "base_amount" => 1500,
        "date" => ~D[2025-01-01]
      }

      assert {:ok, %Expense{} = expense} = Expenses.create_expense(category.id, attrs)
      assert expense.notes == nil
    end

    test "returns error with invalid expense data", %{category: category} do
      attrs = %{
        "base_amount" => -1500,
        "date" => ~D[2025-01-01]
      }

      assert {:error, %Ecto.Changeset{}} = Expenses.create_expense(category.id, attrs)
    end

    test "cannot exceed category monthly budget with a single expense", %{category: category} do
      attrs = %{
        "base_amount" => 100_001,
        "date" => ~D[2025-01-01]
      }

      assert {:error, "Monthly budget exceeded"} = Expenses.create_expense(category.id, attrs)
    end

    test "cannot exceed category monthly budget with multiple expenses", %{category: category} do
      attrs = %{
        "base_amount" => 60_000,
        "date" => ~D[2025-01-01]
      }

      assert {:ok, %Expense{} = expense} = Expenses.create_expense(category.id, attrs)

      attrs = %{
        "base_amount" => 60_000,
        "date" => ~D[2025-01-02]
      }

      assert {:error, "Monthly budget exceeded"} = Expenses.create_expense(category.id, attrs)
    end

    test "expenses across months do not affect the monthly budget", %{category: category} do
      attrs = %{
        "base_amount" => 60_000,
        "date" => ~D[2025-01-01]
      }

      assert {:ok, %Expense{} = expense} = Expenses.create_expense(category.id, attrs)

      attrs = %{
        "base_amount" => 60_000,
        "date" => ~D[2025-02-01]
      }

      assert {:ok, %Expense{} = expense} = Expenses.create_expense(category.id, attrs)
    end
  end
end
