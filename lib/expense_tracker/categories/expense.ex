defmodule ExpenseTracker.Categories.Expense do
  @moduledoc """
  Schema for an expense.
  """

  use Ecto.Schema
  use TypedEctoSchema

  import Ecto.Changeset

  alias ExpenseTracker.Categories.ExpenseCategory

  typed_schema "expenses" do
    field :currency, :string, default: "USD"
    field :base_amount, :integer
    field :date, :date
    field :notes, :string

    belongs_to :category, ExpenseCategory

    timestamps(type: :utc_datetime)
  end

  @spec create_changeset(map()) :: Ecto.Changeset.t()
  def create_changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  @spec changeset(Expense.t(), map()) :: Ecto.Changeset.t()
  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [
      :currency,
      :base_amount,
      :date,
      :notes,
      :category_id
    ])
    |> validate_required([:currency, :base_amount, :date, :category_id])
    |> validate_number(:base_amount, greater_than: 0)
    |> validate_length(:notes, max: 1000)
    |> foreign_key_constraint(:category_id)
  end
end
