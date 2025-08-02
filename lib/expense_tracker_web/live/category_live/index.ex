defmodule ExpenseTrackerWeb.CategoryLive.Index do
  alias ExpenseTracker.Categories.ExpenseCategory
  use ExpenseTrackerWeb, :live_view

  alias ExpenseTracker.Categories
  alias ExpenseTracker.Categories.ExpenseCategoryForm

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
    socket
    |> assign(:page_title, "Categories")
    |> assign(:category, nil)
    |> assign(:changeset, nil)
  end

  defp apply_action(socket, :new, _params) do
    changeset = ExpenseCategoryForm.create_changeset(%{})

    socket
    |> assign(:page_title, "New Category")
    |> assign(:category, %ExpenseCategoryForm{})
    |> assign(:changeset, changeset)
  end

  @impl true
  def handle_event("new_category", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/new")}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/")}
  end

  @impl true
  def handle_event("save", %{"expense_category_form" => category_params}, socket) do
    case category_params
         |> ExpenseCategoryForm.to_expense_category_params()
         |> Categories.create_expense_category() do
      {:ok, category} ->
        socket
        |> put_flash(:info, "Category created successfully")
        |> stream_insert(:categories, category)
        |> assign(:has_categories, true)
        |> push_patch(to: ~p"/")
        |> then(&{:noreply, &1})

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"expense_category_form" => category_params}, socket) do
    changeset =
      socket.assigns.category
      |> ExpenseCategoryForm.changeset(category_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Categories
      <:subtitle>Manage your expense categories</:subtitle>
      <:actions>
        <.button phx-click="new_category">New Category</.button>
      </:actions>
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

    <.modal :if={@live_action == :new} id="category-modal" show on_cancel={JS.patch(~p"/")}>
      <.header>
        New Category
        <:subtitle>Add a new expense category to organize your spending</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="category-form"
        phx-submit="save"
        phx-change="validate"
      >
        <.input field={f[:name]} type="text" label="Name" required />
        <.input field={f[:description]} type="textarea" label="Description" />
        <.input field={f[:monthly_budget_input]} label="Monthly Budget ($)" required />
        <:actions>
          <.button phx-disable-with="Creating..." disabled={not @changeset.valid?}>
            Create Category
          </.button>
          <.button type="button" phx-click={JS.patch(~p"/")} class="ml-3">
            Cancel
          </.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end
end
