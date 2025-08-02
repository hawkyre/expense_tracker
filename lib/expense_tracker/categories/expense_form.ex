defmodule ExpenseTracker.Categories.ExpenseForm do
  use Ecto.Schema
  use TypedEctoSchema

  import Ecto.Changeset

  alias ExpenseTracker.CurrencyTransform
  alias ExpenseTrackerWeb.Format.Currency

  embedded_schema do
    field :amount_input, :string, virtual: true
    field :date, :date
    field :notes, :string
    field :currency, :string, default: "USD"
    field :category_id, :integer, virtual: true
  end

  @spec create_changeset(map()) :: Ecto.Changeset.t()
  def create_changeset(attrs) do
    changeset(%__MODULE__{}, attrs, 0)
  end

  @doc """
  Create expense params from an expense form.
  """
  @spec to_expense_params(map()) :: map()
  def to_expense_params(attrs) do
    changeset = attrs |> create_changeset() |> apply_changes()

    %{
      "base_amount" =>
        CurrencyTransform.transform_amount(changeset.amount_input, changeset.currency),
      "date" => changeset.date,
      "notes" => changeset.notes,
      "currency" => changeset.currency || "USD"
    }
  end

  @doc """
  Changeset for the frontend form.
  """
  @spec changeset(ExpenseForm.t(), map(), integer()) :: Ecto.Changeset.t()
  def changeset(expense_form, attrs, remaining_budget) do
    expense_form
    |> cast(attrs, [:amount_input, :date, :notes, :currency, :category_id])
    |> validate_required([:amount_input, :date])
    |> validate_length(:notes, max: 1000)
    |> validate_date_not_future()
    |> validate_amount_input()
    |> validate_budget_limit(remaining_budget)
  end

  defp validate_amount_input(changeset) do
    case get_field(changeset, :amount_input) do
      amount_str when is_binary(amount_str) ->
        case Float.parse(amount_str) do
          {amount_float, rem} when rem in ["", "."] -> validate_amount(changeset, amount_float)
          _ -> add_error(changeset, :amount_input, "Invalid amount")
        end

      _ ->
        add_error(changeset, :amount_input, "Invalid amount")
    end
  end

  defp validate_amount(changeset, amount_float) when amount_float < 0.01 do
    add_error(changeset, :amount_input, "Amount must be at least $0.01")
  end

  defp validate_amount(changeset, amount_float) when amount_float > 100_000 do
    add_error(changeset, :amount_input, "Amount must be less than $100,000")
  end

  defp validate_amount(changeset, _amount_float) do
    changeset
  end

  defp validate_date_not_future(changeset) do
    case get_field(changeset, :date) do
      %Date{} = date ->
        if Date.compare(date, Date.utc_today()) == :gt do
          add_error(changeset, :date, "Date cannot be in the future")
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  defp validate_budget_limit(%{valid?: true} = changeset, remaining_budget) do
    category_id = get_field(changeset, :category_id)
    date = get_field(changeset, :date)
    amount_input = get_field(changeset, :amount_input)
    currency = get_field(changeset, :currency)

    # Only validate if we have all required fields
    if category_id && date && amount_input && changeset.valid? do
      case Float.parse(amount_input) do
        {_amount_float, _} ->
          amount_cents = CurrencyTransform.transform_amount(amount_input, currency)
          check_budget_limit(changeset, amount_cents, remaining_budget)

        _ ->
          changeset
      end
    else
      changeset
    end
  end

  defp validate_budget_limit(changeset, _budget_remaining) do
    changeset
  end

  defp check_budget_limit(changeset, amount_cents, remaining_budget) do
    if amount_cents > remaining_budget do
      remaining_dollars =
        Currency.format_currency(remaining_budget, get_field(changeset, :currency))

      add_error(
        changeset,
        :amount_input,
        "This expense would exceed your monthly budget. You have #{remaining_dollars} remaining this month."
      )
    else
      changeset
    end
  end
end
