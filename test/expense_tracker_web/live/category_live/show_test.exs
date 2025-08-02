defmodule ExpenseTrackerWeb.CategoryLive.ShowTest do
  use ExpenseTrackerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ExpenseTracker.Categories
  alias ExpenseTracker.Expenses

  describe "expense form" do
    setup do
      {:ok, category} =
        Categories.create_expense_category(%{
          name: "Test Category",
          monthly_budget: 100_000,
          description: "Test category for expenses"
        })

      test_date = Date.utc_today() |> Date.beginning_of_month() |> Date.to_iso8601()

      %{category: category, test_date: test_date}
    end

    test "renders expense form when accessing new_expense action", %{
      conn: conn,
      category: category
    } do
      {:ok, _index_live, html} = live(conn, ~p"/categories/#{category.id}/new_expense")

      assert html =~ "New Expense for #{category.name}"
      assert html =~ "Add a new expense to this category"
      assert html =~ "expense-form"
      assert html =~ "Amount ($)"
      assert html =~ "Date"
      assert html =~ "Notes"
    end

    test "successfully creates expense with valid data", %{
      conn: conn,
      category: category,
      test_date: test_date
    } do
      {:ok, show_live, _html} = live(conn, ~p"/categories/#{category.id}/new_expense")

      assert show_live
             |> form("#expense-form",
               expense_form: %{
                 amount_input: "50.00",
                 date: test_date,
                 notes: "Test expense"
               }
             )
             |> render_submit()

      assert_patch(show_live, ~p"/categories/#{category.id}")

      assert render(show_live) =~ "Expense created successfully"

      category_data = Categories.get_category_with_expenses(category.id)
      assert length(category_data.recent_expenses) == 1
      [expense] = category_data.recent_expenses

      assert expense.base_amount == 5000
      assert expense.notes == "Test expense"
    end

    test "validates budget limit", %{conn: conn, category: category, test_date: test_date} do
      {:ok, show_live, _html} = live(conn, ~p"/categories/#{category.id}/new_expense")

      assert show_live
             |> form("#expense-form",
               expense_form: %{
                 amount_input: "1000.01",
                 date: test_date
               }
             )
             |> render_change() =~ "This expense would exceed your monthly budget"
    end

    test "validates budget limit with existing expenses", %{
      conn: conn,
      category: category,
      test_date: test_date
    } do
      {:ok, _expense} =
        Expenses.create_expense(category.id, %{
          "base_amount" => 60_000,
          "date" => Date.from_iso8601!(test_date),
          "notes" => "Existing expense"
        })

      {:ok, show_live, _html} = live(conn, ~p"/categories/#{category.id}/new_expense")

      # Try to add another expense that would exceed remaining budget
      assert show_live
             |> form("#expense-form",
               expense_form: %{
                 amount_input: "400.01",
                 date: test_date
               }
             )
             |> render_change() =~ "This expense would exceed your monthly budget"

      # But should allow expense within remaining budget
      refute show_live
             |> form("#expense-form",
               expense_form: %{
                 amount_input: "399.99",
                 date: test_date
               }
             )
             |> render_change() =~ "This expense would exceed your monthly budget"
    end

    test "shows budget warning when at 100% budget", %{
      conn: conn,
      category: category,
      test_date: test_date
    } do
      {:ok, _expense} =
        Expenses.create_expense(category.id, %{
          "base_amount" => 100_000,
          "date" => Date.from_iso8601!(test_date),
          "notes" => "Full budget expense"
        })

      {:ok, _show_live, html} = live(conn, ~p"/categories/#{category.id}")

      assert html =~ "Budget Reached"
      assert html =~ "You&#39;ve reached your monthly budget for this category"
    end

    test "disables add expense button when budget is at 100%", %{
      conn: conn,
      category: category,
      test_date: test_date
    } do
      {:ok, _expense} =
        Expenses.create_expense(category.id, %{
          "base_amount" => 100_000,
          "date" => Date.from_iso8601!(test_date)
        })

      {:ok, _show_live, html} = live(conn, ~p"/categories/#{category.id}")

      assert html =~ "disabled"
      assert html =~ "Add Expense"
    end

    test "updates budget progress bar after creating expense", %{
      conn: conn,
      category: category,
      test_date: test_date
    } do
      {:ok, show_live, _html} = live(conn, ~p"/categories/#{category.id}/new_expense")

      show_live
      |> form("#expense-form",
        expense_form: %{
          amount_input: "500.00",
          date: test_date,
          notes: "Half budget expense"
        }
      )
      |> render_submit()

      html = render(show_live)
      assert html =~ "50.0% used"
    end
  end
end
