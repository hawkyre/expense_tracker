defmodule ExpenseTracker.Categories.ExpenseCategory do
  use Ecto.Schema
  use TypedEctoSchema

  import Ecto.Changeset

  typed_schema "expense_categories" do
    field :name, :string
    field :description, :string
    field :monthly_budget, :integer
    field :monthly_budget_currency, :string, default: "USD"

    timestamps(type: :utc_datetime)
  end

  @spec create_changeset(map()) :: Ecto.Changeset.t()
  def create_changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  @spec changeset(ExpenseCategory.t(), map()) :: Ecto.Changeset.t()
  def changeset(expense_category, attrs) do
    expense_category
    |> cast(attrs, [
      :name,
      :description,
      :monthly_budget,
      :monthly_budget_currency
    ])
    |> validate_required([:name, :monthly_budget, :monthly_budget_currency])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:description, max: 500)
    |> validate_number(:monthly_budget, greater_than: 0, less_than: 100_000_000)
  end
end
