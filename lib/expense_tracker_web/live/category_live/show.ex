defmodule ExpenseTrackerWeb.CategoryLive.Show do
  use ExpenseTrackerWeb, :live_view

  alias ExpenseTracker.Categories

  @impl true
  def mount(%{"id" => category_id}, _session, socket) do
    case Categories.get_category_with_expenses(String.to_integer(category_id)) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Category not found")
         |> push_navigate(to: ~p"/")}

      category_data ->
        budget_percentage =
          calculate_budget_percentage(
            category_data.total_expenses_current_month,
            category_data.category.monthly_budget
          )

        socket =
          socket
          |> assign(:category_data, category_data)
          |> assign(:budget_percentage, budget_percentage)
          |> assign(:page_title, category_data.category.name)

        {:ok, socket}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp calculate_budget_percentage(total_expenses, budget) when budget > 0 do
    percentage = total_expenses / budget * 100
    min(percentage, 100)
  end

  defp calculate_budget_percentage(_total_expenses, _budget), do: 0

  defp progress_bar_color(percentage) do
    cond do
      percentage >= 100 -> "bg-red-500"
      percentage >= 75 -> "bg-yellow-500"
      percentage >= 50 -> "bg-orange-500"
      true -> "bg-green-500"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <.link
          navigate={~p"/"}
          class="text-sm text-gray-600 hover:text-gray-800 flex items-center gap-1"
        >
          ← Back to Categories
        </.link>
        <div class="mt-2">
          {@category_data.category.name}
        </div>
        <:subtitle>
          Category details and recent expenses
        </:subtitle>
      </.header>
      
    <!-- Category Description -->
      <div
        :if={@category_data.category.description}
        class="bg-gray-50 rounded-lg p-4 border border-gray-200"
      >
        <p class="text-gray-700">
          {@category_data.category.description}
        </p>
      </div>
      
    <!-- Budget Progress Card -->
      <div class="bg-white shadow rounded-lg p-6 border border-gray-200">
        <div class="space-y-4">
          <!-- Budget Progress -->
          <div class="space-y-3">
            <div class="flex justify-between items-center">
              <span class="text-lg font-semibold text-gray-900">
                {Calendar.strftime(Date.utc_today(), "%B %Y")} Monthly Progress
              </span>
              <span class="text-sm text-gray-600">
                {format_currency(
                  @category_data.total_expenses_current_month,
                  @category_data.category.monthly_budget_currency
                )} / {format_currency(
                  @category_data.category.monthly_budget,
                  @category_data.category.monthly_budget_currency
                )}
              </span>
            </div>

            <div class="w-full bg-gray-200 rounded-full h-3">
              <div
                class={"h-3 rounded-full transition-all duration-300 #{progress_bar_color(@budget_percentage)}"}
                style={"width: #{@budget_percentage}%"}
              >
              </div>
            </div>

            <div class="flex justify-between items-center text-xs text-gray-500">
              <span>0%</span>
              <span class="font-medium">
                {Float.round(@budget_percentage, 2)}% used
              </span>
              <span>100%</span>
            </div>

            <div
              :if={@budget_percentage == 100}
              class="bg-red-50 border border-red-200 rounded-md py-3 px-3"
            >
              <h3 class="text-sm font-medium text-red-800">
                Budget Reached
              </h3>
              <p class="text-sm text-red-700">
                You've reached your monthly budget for this category.
              </p>
            </div>

            <div
              :if={@budget_percentage >= 75 and @budget_percentage < 100}
              class="bg-yellow-50 border border-yellow-200 rounded-md p-3"
            >
              <h3 class="text-sm font-medium text-yellow-800">
                Approaching Budget Limit
              </h3>
              <p class="text-sm text-yellow-700">
                You've used {Float.round(@budget_percentage, 1)}% of your monthly budget. Consider monitoring your spending.
              </p>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Recent Expenses -->
      <div class="bg-white shadow rounded-lg border border-gray-200">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-medium text-gray-900">Recent Expenses</h3>
          <p class="text-sm text-gray-600">Your 5 most recent expenses in this category</p>
        </div>

        <div :if={Enum.empty?(@category_data.recent_expenses)} class="px-6 py-8 text-center">
          <div class="text-gray-500">
            <h3 class="text-sm font-medium text-gray-900">No expenses yet</h3>
            <p class="mt-1 text-sm text-gray-500">
              Start by adding your first expense to this category.
            </p>
          </div>
        </div>

        <div :if={not Enum.empty?(@category_data.recent_expenses)} class="divide-y divide-gray-200">
          <div :for={expense <- @category_data.recent_expenses} class="px-6 py-4 hover:bg-gray-50">
            <div class="flex items-center justify-between">
              <div class="flex-1">
                <div class="flex items-center justify-between">
                  <p class="text-sm font-medium text-gray-900">
                    {if expense.notes && expense.notes != "",
                      do: expense.notes,
                      else: "Untitled Expense"}
                  </p>
                  <p class="text-sm font-bold text-gray-900">
                    {format_currency(expense.base_amount, expense.currency)}
                  </p>
                </div>
                <p class="text-sm text-gray-500 mt-1">
                  {Calendar.strftime(expense.date, "%B %d, %Y")}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
