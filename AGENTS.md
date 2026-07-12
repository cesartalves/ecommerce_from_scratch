# Repository Guidelines

## Project Structure & Module Organization

This is a Rails 7.2 e-commerce application. Application code lives in `app/`: models represent products, orders, payments, and users; controllers are split between storefront flows and `app/controllers/admin/`; views use ERB; Stimulus controllers live in `app/javascript/controllers/`; and styles are in `app/assets/stylesheets/`. Payment integration code belongs in `app/services/mercado_pago/`, while background work lives in `app/jobs/`. Database migrations and seed data are under `db/`. Tests mirror the application structure in `test/`, with shared fixtures in `test/fixtures/`. Configuration is stored in `config/`.

## Build, Test, and Development Commands

- `bin/setup` installs gems, prepares the database, and clears temporary files.
- `bin/rails server` starts the app locally on port 3000.
- `docker compose up --build` starts Rails, PostgreSQL, and Redis in containers.
- `bin/rails db:prepare` creates or migrates the current environment's database.
- `bin/rails test` runs the full Minitest suite; pass a path such as `test/models/order_test.rb` to narrow it.
- `bin/rubocop` checks Ruby and Rails style.
- `bin/brakeman` scans Rails code for common security issues.
- `bundle exec sidekiq -C config/sidekiq.yml` runs background jobs outside Docker.

## Coding Style & Naming Conventions

Use two-space indentation for Ruby, ERB, YAML, and JavaScript. Follow Rails conventions: singular `snake_case` model files (`payment.rb`), plural controller names (`orders_controller.rb`), and `CamelCase` constants. Keep controllers focused on HTTP flow; move payment-provider logic into service objects and asynchronous polling into jobs. RuboCop inherits `rubocop-rails-omakase`; run it before submitting changes.

## Testing Guidelines

The project uses Minitest with fixtures, Capybara, and Selenium. Name tests `*_test.rb` and place them in the matching folder (`test/models`, `test/controllers`, or `test/jobs`). Add regression coverage for bug fixes and test success, validation, and failure paths for checkout or payment changes. Run `RAILS_ENV=test bin/rails db:prepare` if the test schema is stale.

## Commit & Pull Request Guidelines

History uses short, imperative summaries such as `Improve the app` and `Make Payments Work`. Prefer a focused subject that states the outcome, for example `Handle pending Mercado Pago payments`. Keep each commit scoped to one concern. Pull requests should include a concise description, testing performed, related issue links, migration or environment-variable notes, and screenshots for visible UI changes.

## Security & Configuration

Never commit credentials or `.env` files. Configure `MP_ACCESS_TOKEN`, `MP_PUBLIC_KEY`, `REDIS_URL`, database variables, and `RAILS_MASTER_KEY` through the environment. Treat checkout, admin authentication, and webhook changes as security-sensitive and run Brakeman before review.
