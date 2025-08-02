defmodule ExpenseTracker.Repo.Migrations.CreateExpenses do
  use Ecto.Migration

  def change do
    create table(:expenses) do
      add :category_id, references(:expense_categories, on_delete: :delete_all), null: false
      add :currency, :string, null: false, default: "USD"
      add :base_amount, :integer, null: false
      add :date, :date, null: false
      add :notes, :string

      timestamps(type: :utc_datetime)
    end

    create index(:expenses, [:category_id])
    create index(:expenses, [:date])
  end
end
