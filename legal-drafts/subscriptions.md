# Kitchen Prep Board — Ads and Remove-Ads Subscription

The free Android version of Kitchen Prep Board provides the core app functionality with advertising. An optional Google Play subscription removes ads while the subscription entitlement is active.

## Recommended Android 1.0 product

- Product ID: `remove_ads_monthly`
- Base plan ID: `monthly`
- Product type: auto-renewing monthly subscription
- Benefit: removes advertising while the subscription is active
- Recommended US base price: **US$1.49/month**
- Free trial: **none**
- Introductory offer: **none at launch**
- Annual plan: **none at launch**

The free version already lets users evaluate the complete utility, so a subscription free trial adds billing/support complexity without adding meaningful product discovery.

## Pricing rationale

Current market research places simple ad-removal subscriptions around **US$0.99–$1.99/month**. Comparable cooking/meal products with additional premium features are more expensive: Cookmate around $1.99/month, Mealime Pro $2.99/month and Samsung Food+ $6.99/month.

Because Kitchen Prep Board's subscription removes ads only, $2.99+ would be difficult to justify. $0.99 would be very easy to buy but unnecessarily gives up subscription ARPU. **$1.49/month is the recommended midpoint** for a long-session kitchen utility.

## Price and renewal

The app must display the price and billing period returned by Google Play for the user's storefront. The production UI must not rely on a hard-coded base price. The US$1.49 figure is the recommended Play Console base price, not a string to hard-code in the app.

Google Play may generate or suggest localized prices, and GoodUse Studios may manually use lower local price points in lower-income markets where appropriate.

The subscription renews automatically monthly according to the terms displayed by Google Play unless the user cancels it. Users can manage or cancel subscriptions through Google Play. Cancellation stops future renewal but does not ordinarily erase local app data.

## Refunds

Refunds and cancellation rights are governed by Google Play policy and applicable mandatory consumer law. Kitchen Prep Board must not promise a narrower refund right than applicable law provides.

## Privacy

Google Play processes the payment transaction. Kitchen Prep Board receives purchase/entitlement information needed to determine whether ads should be removed. See the Privacy Policy for details.

## Advertising

If the subscription entitlement is not active, advertising may be requested only when Google UMP / AdMob privacy state permits it. If the entitlement is active, advertising is suppressed.

## Release confirmations required

Before publication:

1. create/activate `remove_ads_monthly` with base plan `monthly` in Play Console;
2. set the US base price to $1.49 unless the owner changes this recommendation;
3. configure no free trial and no introductory offer at launch;
4. verify product availability in intended storefronts;
5. display localized ProductDetails pricing and renewal information before purchase;
6. provide Manage subscription; and
7. test purchase, acknowledgement, restore/reconciliation, cancellation and expiry using a Play-track build.

This document is aligned with the current Android 1.0 recommendation and should be rechecked against the final Play Console product immediately before release.