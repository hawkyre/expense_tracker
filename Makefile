.PHONY: db-up up

db-up:
	@docker start expense-pg 2>/dev/null || docker run -d \
		--name expense-pg \
		-p 5432:5432 \
		-v expense_tracker_db:/var/lib/postgresql/data \
		postgres:latest

up:
	@make db-up
	@mix phx.server