defmodule ExpenseTrackerWeb.CategoryLive.Index do
  use ExpenseTrackerWeb, :live_view

  alias ExpenseTracker.Categories

  @impl true
  def mount(_params, _session, socket) do
    categories = Categories.list_expense_categories()

    socket
    |> assign(:has_categories, Enum.count(categories) > 0)
    |> stream(:categories, categories)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Categories")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Categories
      <:subtitle>Manage your expense categories</:subtitle>
    </.header>

    <div class="mt-8">
      <div id="categories" phx-update="stream" class="space-y-4">
        <div
          :for={{id, category} <- @streams.categories}
          id={id}
          class="bg-white shadow rounded-lg p-6 border border-gray-200"
        >
          <div class="mb-4">
            <h3 class="text-lg font-semibold text-gray-900">{category.name}</h3>
          </div>

          <div class="space-y-2">
            <div :if={category.description} class="text-sm text-gray-600">
              {category.description}
            </div>

            <div class="flex items-center gap-2">
              <span class="text-sm font-medium text-gray-700">Monthly Budget:</span>
              <span class="text-sm font-bold text-orange-600 bg-orange-100 px-2 py-1 rounded-md">
                {category.monthly_budget_currency} {:erlang.float_to_binary(
                  category.monthly_budget / 100,
                  decimals: 2
                )}
              </span>
            </div>
          </div>

          <div class="mt-4 text-xs text-gray-500">
            Created {Calendar.strftime(category.inserted_at, "%B %d, %Y")}
          </div>
        </div>
      </div>

      <div :if={!@has_categories} class="text-center py-12">
        <div class="text-gray-500">
          <h3 class="mt-2 text-sm font-medium text-gray-900">No categories yet</h3>
          <p class="mt-1 mb-4 text-sm text-gray-500">
            Get started by creating your first expense category.
          </p>
          <.button phx-click="new_category">Create Category</.button>
        </div>
      </div>
    </div>
    """
  end
end
