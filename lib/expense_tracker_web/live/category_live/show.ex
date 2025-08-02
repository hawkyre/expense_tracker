defmodule ExpenseTrackerWeb.CategoryLive.Show do
  use ExpenseTrackerWeb, :live_view

  alias ExpenseTracker.Categories
  alias ExpenseTracker.Categories.ExpenseForm
  alias ExpenseTracker.Expenses

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
          |> assign(:expense, nil)
          |> assign(:changeset, nil)

        {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:expense, nil)
    |> assign(:changeset, nil)
  end

  defp apply_action(socket, :new_expense, _params) do
    category_id = socket.assigns.category_data.category.id

    changeset =
      ExpenseForm.create_changeset(%{
        "category_id" => category_id,
        "date" => Date.utc_today()
      })

    socket
    |> assign(:expense, %ExpenseForm{category_id: category_id})
    |> assign(:changeset, changeset)
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
  def handle_event("new_expense", _, socket) do
    category_id = socket.assigns.category_data.category.id
    {:noreply, push_patch(socket, to: ~p"/categories/#{category_id}/new_expense")}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    category_id = socket.assigns.category_data.category.id
    {:noreply, push_patch(socket, to: ~p"/categories/#{category_id}")}
  end

  @impl true
  def handle_event("save", %{"expense_form" => expense_params}, socket) do
    category_id = socket.assigns.category_data.category.id

    case expense_params
         |> ExpenseForm.to_expense_params()
         |> then(fn params -> Expenses.create_expense(category_id, params) end) do
      {:ok, _expense} ->
        # Refresh the category data to show the new expense
        case Categories.get_category_with_expenses(category_id) do
          nil ->
            socket
            |> put_flash(:error, "Category not found")
            |> push_navigate(to: ~p"/")
            |> then(&{:noreply, &1})

          category_data ->
            budget_percentage =
              calculate_budget_percentage(
                category_data.total_expenses_current_month,
                category_data.category.monthly_budget
              )

            socket
            |> put_flash(:info, "Expense created successfully")
            |> assign(:category_data, category_data)
            |> assign(:budget_percentage, budget_percentage)
            |> push_patch(to: ~p"/categories/#{category_id}")
            |> then(&{:noreply, &1})
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:error, message} when is_binary(message) ->
        socket
        |> put_flash(:error, message)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_event("validate", %{"expense_form" => expense_params}, socket) do
    category_id = socket.assigns.category_data.category.id
    expense_params_with_category = Map.put(expense_params, "category_id", category_id)

    remaining_budget =
      socket.assigns.category_data.category.monthly_budget -
        socket.assigns.category_data.total_expenses_current_month

    changeset =
      socket.assigns.expense
      |> ExpenseForm.changeset(
        expense_params_with_category,
        remaining_budget
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
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
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg font-medium text-gray-900">Recent Expenses</h3>
              <p class="text-sm text-gray-600">Your 5 most recent expenses in this category</p>
            </div>
            <.button phx-click="new_expense" disabled={@budget_percentage >= 100}>
              Add Expense
            </.button>
          </div>
        </div>

        <div :if={Enum.empty?(@category_data.recent_expenses)} class="px-6 py-8 text-center">
          <div class="text-gray-500">
            <h3 class="text-sm font-medium text-gray-900">No expenses yet</h3>
            <p class="mt-1 mb-4 text-sm text-gray-500">
              Start by adding your first expense to this category.
            </p>
            <.button phx-click="new_expense">Add Your First Expense</.button>
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
      
    <!-- Expense Form Modal -->
      <.modal
        :if={@live_action == :new_expense}
        id="expense-modal"
        show
        on_cancel={JS.patch(~p"/categories/#{@category_data.category.id}")}
      >
        <.header>
          New Expense for {@category_data.category.name}
          <:subtitle>Add a new expense to this category</:subtitle>
        </.header>

        <.simple_form
          :let={f}
          for={@changeset}
          id="expense-form"
          phx-submit="save"
          phx-change="validate"
        >
          <.input field={f[:amount_input]} label="Amount ($)" required />
          <.input field={f[:date]} type="date" label="Date" required max={Date.utc_today()} />
          <.input field={f[:notes]} type="textarea" label="Notes" />
          <:actions>
            <.button phx-disable-with="Creating..." disabled={not @changeset.valid?}>
              Create Expense
            </.button>
            <.button
              type="button"
              phx-click={JS.patch(~p"/categories/#{@category_data.category.id}")}
              class="ml-3"
            >
              Cancel
            </.button>
          </:actions>
        </.simple_form>
      </.modal>
    </div>
    """
  end
end
