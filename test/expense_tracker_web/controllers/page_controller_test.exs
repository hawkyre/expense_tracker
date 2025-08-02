defmodule ExpenseTrackerWeb.PageControllerTest do
  use ExpenseTrackerWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Manage your expense categories"
  end
end
