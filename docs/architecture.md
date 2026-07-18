# System Overview

Cesar Colecionismo is a Rails e-commerce monolith with a storefront and an administrator namespace.

## Technology Stack

Rails 7.2, ERB, Stimulus, PostgreSQL, Redis, Sidekiq, Minitest, Capybara, and Selenium.

## Module and Service Boundaries

Models own order, inventory, and address invariants. Controllers coordinate HTTP flows. Payment-provider code lives in `app/services/mercado_pago/`, shipping integration code under `app/services/correios/`, and asynchronous polling in `app/jobs/`.

## Data and Request Flows

Customers maintain one current address. Checkout creates and pays an order. When an order becomes paid, inventory is reserved and the current customer address is copied into an order-owned shipping address snapshot.

## Architecture Invariants

- Provider-specific logic stays out of controllers and models where practical.
- A paid order preserves its checkout-time shipping address even if the customer later changes their profile address.
- Stock reservation and paid-state transition occur atomically and are safe to repeat.
