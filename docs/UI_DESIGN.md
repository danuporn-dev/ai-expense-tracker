# My Wallet UI

The interface uses the supplied reference's pink, peach and cream palette, soft card corners and generous spacing. The wallet and receipt illustrations are Flutter shapes, so they scale without bitmap assets.

- Background: `#FFFAF6`
- Primary/buttons: `#D13C65`
- Soft pink: `#FFE8EE`
- Peach: `#FFEEDB`
- Main text: `#392B31`
- Supporting text: `#8C757D`
- Income: `#25836D`; expenses: `#D34F5E`

Nunito is used for Latin text and numbers; Noto Sans Thai is the Thai fallback. Font files and their SIL Open Font License notices are bundled locally under `mobile/assets/fonts`; the app does not fetch fonts at runtime.

Sources: [Nunito](https://github.com/google/fonts/tree/main/ofl/nunito), [Noto Sans Thai](https://github.com/google/fonts/tree/main/ofl/notosansthai).

Emulator previews using demonstration data: [Dashboard](../screenshotforgithub/02-dashboard-month.png), [Income](../screenshotforgithub/04-income-saved.png), [Receipt scanner](../screenshotforgithub/03-receipt-selected.png), [Subscriptions](../screenshotforgithub/06-subscription-calendar.png). See the [complete process gallery](../screenshotforgithub/README.md).

Previous emulator verification covered dashboard, income, receipt scanner and subscriptions. See [test results](TEST_CASES.md) for automated checks and build history.
