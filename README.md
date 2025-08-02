# ExpenseTracker

To start the Expense Tracker server:

- Run `mix setup` to install and setup dependencies
- If you already have a Postgres database running on port 5432, you can start the Phoenix endpoint directly with `mix phx.server` or inside IEx with `iex -S mix phx.server`
- If you don't have such database running you can execute `make up`, which runs a Postgres docker container if it's not running already and subsequently starts the server. Its volume is persisted so you don't lose the data when restarting the server.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser and start playing!
