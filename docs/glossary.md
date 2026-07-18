# Domain Terms

- **Cart:** An order with `cart` status that can still receive line items.
- **Order completion:** The transactional transition to `paid`, including stock reservation and shipping-address capture.
- **Customer address:** The user's editable current address.
- **Shipping address:** An immutable order-owned copy of the customer address captured at completion.
- **Shipping quote:** Correios service, price, and delivery estimate applied to an order.

## Technical Terms and Acronyms

- **MP:** Mercado Pago.
- **CEP:** Brazilian postal code.
- **ERB:** Rails embedded Ruby templates.

## Naming Conventions

Use `shipping_address` for the order association and `address` for the user's current profile address.
