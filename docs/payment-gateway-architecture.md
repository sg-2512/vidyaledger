# Payment Gateway Architecture

VidyaLedger should remain the school finance ledger and reconciliation system.
It should not pool parent funds or act as a payment aggregator. Live money
movement must happen through an authorised payment aggregator or the school's
bank/UPI merchant setup.

## Implemented Now

- `payment_requests` stores UPI intent and hosted-checkout requests per student.
- `create_payment_request` creates an auditable request with provider, amount,
  checkout URL, optional UPI URI, expiry, and audit log.
- Staff can create requests from the Payments screen.
- Parents can see and copy linked payment requests in the Parent Portal.
- Manual receipt posting remains separate from online request creation.

## Provider Strategy

- `UPI Intent`: Generates a `upi://pay` URI for low-friction demo and school
  merchant UPI flows.
- `Razorpay`, `Cashfree`, `PhonePe`, `PayU`: Store hosted-checkout request
  metadata now. Production integration should be done from a Supabase Edge
  Function or backend service using provider secrets.

## Production Flow

1. Staff creates a payment request for a student and provider.
2. Backend creates a provider order/payment session.
3. Parent pays through UPI or hosted checkout.
4. Provider webhook reaches backend.
5. Backend verifies webhook signature.
6. Backend marks payment request paid/failed.
7. Backend calls `record_payment_with_receipt`.
8. Ledger, receipt, reconciliation, and audit rows are posted atomically.

## Required Environment Secrets

Keep these only on the server/backend side:

- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `CASHFREE_CLIENT_ID`
- `CASHFREE_CLIENT_SECRET`
- `PHONEPE_CLIENT_ID`
- `PHONEPE_CLIENT_SECRET`
- `PAYU_KEY`
- `PAYU_SALT`
- `PAYMENT_WEBHOOK_SECRET`

## Demo Positioning

For the hackathon, show that VidyaLedger has a provider-neutral payment layer:
manual payments, UPI intent links, gateway checkout placeholders, receipt
posting, reconciliation, ledger entries, and audit logs are separated cleanly.
