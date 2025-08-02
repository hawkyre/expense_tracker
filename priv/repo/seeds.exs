# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ExpenseTracker.Repo.insert!(%ExpenseTracker.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

ExpenseTracker.Categories.create_expense_category(%{
  name: "Food",
  description: "High quality food and drinks are the core of a good life",
  monthly_budget: 50_000
})

ExpenseTracker.Categories.create_expense_category(%{
  name: "Elixir courses",
  description: "To improve my Elixir skills",
  monthly_budget: 75_000
})
