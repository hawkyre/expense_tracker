defmodule ExpenseTracker.Categories.ExpenseCategoryForm do
  use Ecto.Schema
  use TypedEctoSchema

  import Ecto.Changeset

  alias Decimal, as: D

  embedded_schema do
    field :name, :string
    field :description, :string
    field :monthly_budget_input, :string, virtual: true
  end

  @spec create_changeset(map()) :: Ecto.Changeset.t()
  def create_changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  @doc """
  Create expense category params from a expense category form.
  """
  @spec to_expense_category_params(map()) :: map()
  def to_expense_category_params(attrs) do
    changeset = attrs |> create_changeset() |> apply_changes()

    %{
      "name" => changeset.name,
      "description" => changeset.description,
      "monthly_budget" => transform_monthly_budget(changeset.monthly_budget_input)
    }
  end

  @doc """
  Changeset for the frontend form.
  """
  @spec changeset(ExpenseCategoryForm.t(), map()) :: Ecto.Changeset.t()
  def changeset(expense_category_form, attrs) do
    expense_category_form
    |> cast(attrs, [:name, :description, :monthly_budget_input])
    |> validate_required([:name, :monthly_budget_input])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:description, max: 500)
    |> validate_monthly_budget_input()
  end

  defp validate_monthly_budget_input(changeset) do
    case get_field(changeset, :monthly_budget_input) do
      budget_str when is_binary(budget_str) ->
        case Float.parse(budget_str) do
          {budget_float, rem} when rem in ["", "."] -> validate_budget(changeset, budget_float)
          _ -> add_error(changeset, :monthly_budget_input, "Invalid monthly budget")
        end

      _ ->
        add_error(changeset, :monthly_budget_input, "Invalid monthly budget")
    end
  end

  defp validate_budget(changeset, budget_float) when budget_float < 0.01 do
    add_error(changeset, :monthly_budget_input, "Monthly budget must be at least $0.01")
  end

  defp validate_budget(changeset, budget_float) when budget_float > 100_000 do
    add_error(changeset, :monthly_budget_input, "Monthly budget must be less than $100,000")
  end

  defp validate_budget(changeset, _budget_float) do
    changeset
  end

  defp transform_monthly_budget(monthly_budget_float_string) do
    monthly_budget_float_string |> D.new() |> D.mult(100) |> D.to_integer()
  end
end
