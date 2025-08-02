defmodule ExpenseTracker.CategoriesTest do
  use ExpenseTracker.DataCase

  alias ExpenseTracker.Categories
  alias ExpenseTracker.Categories.ExpenseCategory
  alias ExpenseTracker.Expenses

  describe "list_expense_categories/0" do
    test "returns a list of expense categories" do
      assert Categories.list_expense_categories() == []
    end
  end

  describe "create_expense_category/1" do
    test "creates a new expense category" do
      assert {:ok, %ExpenseCategory{}} =
               Categories.create_expense_category(%{
                 name: "Test Category",
                 monthly_budget: "1000"
               })
    end
  end

  describe "get_category_with_expenses/1" do
    setup do
      {:ok, category} =
        Categories.create_expense_category(%{
          name: "Test Category",
          monthly_budget: 100_000
        })

      %{category: category}
    end

    test "returns nil for non-existent category" do
      assert Categories.get_category_with_expenses(999) == nil
    end

    test "returns category with empty expenses when category has no expenses", %{
      category: category
    } do
      result = Categories.get_category_with_expenses(category.id)

      assert result.category.id == category.id
      assert result.recent_expenses == []
      assert result.total_expenses_current_month == 0
    end

    test "returns category with recent expenses and total sum", %{category: category} do
      beginning_of_month = Date.beginning_of_month(Date.utc_today())

      # Create 7 expenses with different dates
      expense_attrs = [
        %{
          "currency" => "USD",
          "base_amount" => 1000,
          "date" => beginning_of_month,
          "notes" => "Expense 1"
        },
        %{
          "currency" => "USD",
          "base_amount" => 2000,
          "date" => beginning_of_month |> Date.add(1),
          "notes" => "Expense 2"
        },
        %{
          "currency" => "USD",
          "base_amount" => 1500,
          "date" => beginning_of_month |> Date.add(2),
          "notes" => "Expense 3"
        },
        %{
          "currency" => "USD",
          "base_amount" => 3000,
          "date" => beginning_of_month |> Date.add(3),
          "notes" => "Expense 4"
        },
        %{
          "currency" => "USD",
          "base_amount" => 2500,
          "date" => beginning_of_month |> Date.add(4),
          "notes" => "Expense 5"
        },
        %{
          "currency" => "USD",
          "base_amount" => 1800,
          "date" => beginning_of_month |> Date.add(5),
          "notes" => "Expense 6"
        },
        %{
          "currency" => "USD",
          "base_amount" => 2200,
          "date" => beginning_of_month |> Date.add(6),
          "notes" => "Expense 7"
        }
      ]

      # Create all expenses
      for attrs <- expense_attrs do
        {:ok, _expense} = Expenses.create_expense(category.id, attrs)
      end

      result = Categories.get_category_with_expenses(category.id)

      # Should return category
      assert result.category.id == category.id

      # Should return only 5 most recent expenses (ordered by date desc)
      assert length(result.recent_expenses) == 5
      expense_dates = Enum.map(result.recent_expenses, & &1.date)

      assert expense_dates == [
               beginning_of_month |> Date.add(6),
               beginning_of_month |> Date.add(5),
               beginning_of_month |> Date.add(4),
               beginning_of_month |> Date.add(3),
               beginning_of_month |> Date.add(2)
             ]

      # Should return total sum of all expenses (not just the 5 most recent)
      expected_total = 1000 + 2000 + 1500 + 3000 + 2500 + 1800 + 2200
      assert result.total_expenses_current_month == expected_total
    end

    test "handles expenses across months correctly", %{category: category} do
      beginning_of_month = Date.beginning_of_month(Date.utc_today())
      # Create only 3 expenses
      expense_attrs = [
        %{
          "currency" => "USD",
          "base_amount" => 1000,
          "date" => beginning_of_month,
          "notes" => "Expense 1"
        },
        %{
          "currency" => "USD",
          "base_amount" => 2000,
          "date" => beginning_of_month |> Date.add(1),
          "notes" => "Expense 2"
        },
        %{
          "currency" => "USD",
          "base_amount" => 1500,
          "date" => beginning_of_month |> Date.add(-1),
          "notes" => "Expense 3"
        }
      ]

      for attrs <- expense_attrs do
        {:ok, _expense} = Expenses.create_expense(category.id, attrs)
      end

      result = Categories.get_category_with_expenses(category.id)

      # Should return all 3 expenses
      assert length(result.recent_expenses) == 3

      # Should return total sum of expenses in the current month (August 2025)
      assert result.total_expenses_current_month == 3000
    end
  end
end
