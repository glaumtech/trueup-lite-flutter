# TrueUp Lite Flutter — feature context

## Online order fulfillment (staff app)

Screens live under `lib/screens/store_orders/`.

| Action | Where | Purpose |
|--------|--------|---------|
| Call | Ship To phone row | Opens device dialer (`tel:`) |
| WhatsApp | Ship To phone row (green chat icon) | Opens WhatsApp to customer via `wa.me` with `formatCustomerOrderMessage` (no address or staff notes) |
| Share (app bar) | Order detail header | System share sheet with `formatOnlineOrder` (full address + receipt for couriers) |

Phone normalization for WhatsApp: ten-digit numbers default to country code `91`. Helpers in `lib/utils/whatsapp_launcher.dart`.
