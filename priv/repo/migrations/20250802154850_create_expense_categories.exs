defmodule ExpenseTracker.Repo.Migrations.CreateExpenseCategories do
  use Ecto.Migration

  def change do
    create table(:expense_categories) do
      add :name, :string, null: false
      add :description, :string
      add :monthly_budget, :integer, null: false
      add :monthly_budget_currency, :string, null: false, default: "USD"

      timestamps(type: :utc_datetime)
    end
  end
end
