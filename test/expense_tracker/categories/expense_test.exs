defmodule ExpenseTracker.Categories.ExpenseTest do
  use ExpenseTracker.DataCase

  alias ExpenseTracker.Categories.Expense

  describe "create_changeset/1" do
    test "creates a valid expense with all required fields" do
      attrs = %{
        category_id: 1,
        currency: "USD",
        base_amount: 1500,
        date: ~D[2025-01-01],
        notes: "Test expense"
      }

      assert %Ecto.Changeset{valid?: true} = Expense.create_changeset(attrs)
    end

    test "creates a valid expense without optional notes" do
      attrs = %{
        category_id: 1,
        currency: "USD",
        base_amount: 1500,
        date: ~D[2025-01-01]
      }

      assert %Ecto.Changeset{valid?: true} = Expense.create_changeset(attrs)
    end

    test "requires category_id" do
      attrs = %{
        currency: "USD",
        base_amount: 1500,
        date: ~D[2025-01-01]
      }

      assert %Ecto.Changeset{errors: [category_id: _]} = Expense.create_changeset(attrs)
    end

    test "requires base_amount" do
      attrs = %{
        category_id: 1,
        currency: "USD",
        date: ~D[2025-01-01]
      }

      assert %Ecto.Changeset{errors: [base_amount: _]} = Expense.create_changeset(attrs)
    end

    test "requires date" do
      attrs = %{
        category_id: 1,
        currency: "USD",
        base_amount: 1500
      }

      assert %Ecto.Changeset{errors: [date: _]} = Expense.create_changeset(attrs)
    end

    test "base_amount must be greater than 0" do
      attrs = %{
        category_id: 1,
        currency: "USD",
        base_amount: 0,
        date: ~D[2025-01-01]
      }

      assert %Ecto.Changeset{errors: [base_amount: _]} = Expense.create_changeset(attrs)

      attrs = %{attrs | base_amount: -100}
      assert %Ecto.Changeset{errors: [base_amount: _]} = Expense.create_changeset(attrs)
    end

    test "notes cannot exceed 1000 characters" do
      long_notes = String.duplicate("a", 1001)

      attrs = %{
        category_id: 1,
        currency: "USD",
        base_amount: 1500,
        date: ~D[2025-01-01],
        notes: long_notes
      }

      assert %Ecto.Changeset{errors: [notes: _]} = Expense.create_changeset(attrs)

      # Test that 1000 characters is valid
      valid_notes = String.duplicate("a", 1000)
      attrs = %{attrs | notes: valid_notes}
      assert %Ecto.Changeset{valid?: true} = Expense.create_changeset(attrs)
    end
  end
end
