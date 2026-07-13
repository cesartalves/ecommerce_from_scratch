# Ecommerce From Scratch

## Correios shipping

The checkout calculates PAC and SEDEX prices and delivery estimates using the
official Correios APIs. Configure credentials through the environment:

```bash
CORREIOS_USERNAME=your-meu-correios-user
CORREIOS_ACCESS_CODE=your-meu-correios-access-code
CORREIOS_ORIGIN_ZIP=17509031
CORREIOS_SHIPPING_ENABLED=false
```

Shipping is disabled by default so checkout remains available without a
Correios quote. Set `CORREIOS_SHIPPING_ENABLED=true` when the price API access
is authorized and freight should be charged again.

The service codes default to `03298` for PAC and `03220` for SEDEX. Contracts
using different product codes can override them with `CORREIOS_PAC_CODE` and
`CORREIOS_SEDEX_CODE`.

Every product must have weight in grams and packaged length, width, and height
in centimeters. These fields are managed in the admin product form.

# Rails notes

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
