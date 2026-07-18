# Integration Catalog

- Mercado Pago: payment creation and status updates.
- Correios: package-based shipping quotes.
- Redis/Sidekiq: background payment status polling.

## Authentication and Access

External credentials come from environment variables. Administrator pages require a user with the admin role.

## Contracts and Data Flows

Checkout sends payment data to Mercado Pago and destination/package data to shipping services. Provider payment updates call the order completion flow rather than writing paid state directly.

## Failure Modes and Retries

Payment polling runs asynchronously and may retry. Order completion is idempotent for inventory reservation and shipping-address creation.

## Ownership

Integration adapters are maintained in their service namespaces; checkout orchestration is owned by `CheckoutsController`, and payment polling by `CheckPaymentStatusJob`.
