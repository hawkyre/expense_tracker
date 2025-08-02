# Simple expense tracker

This project implements an expense tracker using Phoenix and LiveView. It allows users to create expense categories and register expenses within those categories, ensuring they don't go over the monthly limit for each category.

## Architecture

I decided on making 2 liveviews, one for displaying each resource, and each with a modal form to create the respective resources. Each modal is toggled through the current live action.

Contexts encapsulate the business logic, such as creating or retrieving resources.

There are 2 schemas for the database resources and 2 embedded schemas for the user's forms, since I wanted them to be able to input the currency as a string. There is some logic in such schemas to ensure amounts are valid, and specially inside the ExpenseForm schema where I validate the budget isn't exceeded and show a proper error message to improve the UX. For this, I passed an extra parameter indicating the remaining budget to the changeset. The embedded schemas then are able to build the params for the database schemas by properly transforming their attributes.

I use the `Decimal` library to handle parsing of currency from string to the base amounts that we store in the database, which is the correct way to handle numbers where precision loss is unacceptable. I do use `Float.parse` in the changesets because I wanted to be a bit more permissive on treating user input, but this is purely used for validation.

## Currency handling

I added a currency field to both the monthly budget and the expenses, no multi-currency logic was implemented other than formatting currencies for display (`ExpenseTrackerWeb.Format.Currency.format_currency/2`) and transform form currencies from user input to base amounts (`ExpenseTracker.CurrencyTransform.transform_amount/2`).

In order to handle multi-currency support, we would need to hook up the server with a currency exchange API that is able to return the exchanges for a given day and currency pair.

Converting currencies is simple, we fetch and cache the currency conversion for the given date and currency pair, calculate the amount in the target currency and display it to the user. We would need to ensure that the exchange rate reflects the base amount we store.

Parsing currencies from the form is implemented in the `ExpenseTracker.CurrencyTransform` module, which takes a string representing an amount and a currency denomination and transforms it into a base amount.

The more complex logic comes when calculating whether a category has exceeded its monthly budget. For that, we'd need to bring the currencies and amounts of each currency from the database, convert all currencies to, for example, the category's budget currency and validate it isn't exceeded. Since it might take a bit of time to do it in real time, we can load and cache daily all the currencies we might need on our database to reduce API latency.

There is a little hack I made on the form schemas, where I hard-coded `0.01` as the minimum amount allowed for the user. This only makes sense with currencies that have 100 sub-units, such as dollars or euros, but would break for others such as yens. We would need to get the minimum amount from the currency, which would involve creating a module to return said values while storing the corresponding minimum mapping in a module attribute.

## Testing strategy

I usually like to test at the level of the highest-level user interaction; in most projects I split frontend and backend and use a separate frontend framework such as React or Svelte so there I'd test at the API level. Here, however, I added tests at 3 different levels:

- At the schema level, to ensure the most common validations work
- At the context level, which would be the "equivalent" other than testing live views in this case, where I test as much logic and edge cases as possible
- At the live-view level, for which I opted to just test the creation of expenses and its effects on the underlying category details view. Rather than testing the form changesets, I preferred testing here which is where the user actually inputs their values, and I can check that the expected messages are rendered.

## Other things

I forgot to add the mandatory description on expenses and kept only the optional notes. To fix this, I thought of several approaches, but I think this would be the best:

- Add a `null: true` description column
- Fill it with the current notes value, or "Unnamed Expense" if not present.
- Set `null: false` on the description
- Erase the notes field on existing expenses, so they are effectively promoted to description.

Reverting the migration would be rather delicate, but we could probably just demote the description to notes. It would erase the existing notes when re-running the migration, but since the description is more important this is probably what does the least harm overall.

This would make the most sense for the users, since they would have been filling in the notes as the description of the expense. The codebase changes other than this are trivial.
