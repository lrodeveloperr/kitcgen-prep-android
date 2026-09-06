# Kitchen Prep Board — Ads and Remove-Ads Subscription

The free Android version of Kitchen Prep Board provides the core app functionality with advertising. An optional Google Play subscription removes ads while the subscription entitlement is active.

## Android 1.0 product — locked

- Product ID: `remove_ads_monthly`
- Base plan ID: `monthly`
- Product type: auto-renewing monthly subscription
- Benefit: removes advertising while the subscription is active
- **U.S. base price: US$1.49/month**
- Free trial: **none**
- Introductory offer: **none at launch**
- Annual plan: **none at launch**

The free version already lets users evaluate the complete utility, so a subscription free trial adds billing/support complexity without adding meaningful product discovery.

## Pricing rationale

Simple ad-removal subscriptions commonly sit around US$0.99–$1.99/month, while cooking/meal apps that bundle substantial premium functionality are materially more expensive. Because Kitchen Prep Board's paid benefit is ad removal only, **US$1.49/month** is the selected launch midpoint: low-friction for frequent users while preserving materially more subscriber ARPU than US$0.99.

## Price and renewal

The U.S. Play Console base plan is to be configured at **US$1.49/month**. Google Play may generate localized storefront prices from that base, and GoodUse Studios may selectively reduce local prices later where conversion data supports it.

The app itself must display the price and billing period returned by Google Play `ProductDetails` for the user's storefront. It must not use a hard-coded `$1.49` string as the user's price. The current store-readiness branch queries the `monthly` base plan and exposes the live Google Play formatted price in Settings before purchase.

The subscription renews automatically monthly according to the terms displayed by Google Play unless the user cancels it. Users can manage or cancel subscriptions through Google Play. Cancellation stops future renewal but does not ordinarily erase local app data.

## Refunds

Refunds and cancellation rights are governed by Google Play policy and applicable mandatory consumer law. Kitchen Prep Board must not promise a narrower refund right than applicable law provides.

## Privacy

Google Play processes the payment transaction. Kitchen Prep Board receives purchase/entitlement information needed to determine whether ads should be removed. See the Privacy Policy for details.

## Advertising

If the subscription entitlement is not active, advertising may be requested only when Google UMP / AdMob privacy state permits it. If the entitlement is active, advertising is suppressed.

## Remaining Play Console configuration

Before publication:

1. create/activate `remove_ads_monthly` with base plan `monthly`;
2. set the U.S. base price to **US$1.49/month**;
3. configure **no free trial** and **no introductory offer**;
4. verify generated/localized prices in intended storefronts;
5. verify the app displays Google Play's localized `ProductDetails` price and monthly renewal information before purchase;
6. verify Manage subscription; and
7. test purchase, acknowledgment, restore/reconciliation, cancellation and expiry using a Play-track build.

The price decision is final for Android 1.0 unless the owner explicitly changes it later.