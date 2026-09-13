# TODO — Dabberli request-new.html redesign

Tasks are ordered by dependency. Do them top to bottom — do not skip ahead even if a
later task looks independent. Each task should be completable and testable in one cycle.

## Schema (Supabase migrations)

Create each as a NEW file under `supabase/migrations/`, never edit an already-applied
migration. Follow the existing naming pattern (`NNN_description.sql`).

- [ ] Add `purpose` column to `public.property_requests`: `TEXT NOT NULL CHECK (purpose IN ('rent', 'buy'))`, no default (must be explicit at insert time — do not backfill a default for new rows going forward, but existing rows need a one-time backfill to `'rent'` before the NOT NULL constraint can be applied).
- [ ] Add `governorate` column to `public.property_requests`: `TEXT` — one of Iraq's 18 governorates (English slug values, e.g. `baghdad`, `basra`, `nineveh` — do not use Arabic strings as the stored value, keep Arabic only in the UI label). Keep the existing `city` column as-is for backward compatibility; do not drop or rename it.
- [ ] Add `area` column to `public.property_requests`: `TEXT`, nullable — holds the selected sub-area within a governorate, or free-text when the user picks "أخرى" (other). Keep existing `area_name` column untouched.
- [ ] Add `property_subtype` column to `public.property_requests`: `TEXT`, nullable, with a CHECK constraint that only restricts values when `category = 'residential'`: `CHECK (category <> 'residential' OR property_subtype IN ('apartment', 'house', 'villa', 'duplex'))`.
- [ ] Add `rental_period` column to `public.property_requests`: `TEXT`, nullable, `CHECK (rental_period IN ('daily', 'weekly', 'monthly', 'yearly'))`, no DB-level default (the default of "monthly" is a UI/form default, not a schema default — a `buy` request should have `rental_period` as NULL).
- [ ] Update `CLAUDE.md`'s `property_requests` schema section to document all five new columns (name, type, constraint, purpose) so the doc matches the live schema.

## Static data

- [ ] Create `site/js/iraq-locations.js` exporting a plain object mapping each of Iraq's 18 governorate slugs to `{ label: "<Arabic name>", areas: [{ value, label }, ...] }`. Include 8–15 of the most common areas/neighborhoods per governorate. Every governorate's area list must end with an `{ value: "other", label: "أخرى" }` entry.
- [ ] Create `site/js/numerals.js` exporting a function `toWesternDigits(str)` that maps Arabic-Indic digits (٠-٩) to Western digits (0-9), leaving everything else unchanged.

## Form: `site/request-new.html`

- [ ] Reorganize the form into grouped `<fieldset>` sections with `<legend>` headings: (1) الفئة والغرض, (2) الموقع, (3) الميزانية, (4) المواصفات, (5) تفاصيل إضافية. Preserve every existing field ID used by the submit handler.
- [ ] Add a required "الغرض" field (رغبة الإيجار/الشراء) as a two-option control (`rent` / `buy`) in the first fieldset, no option pre-selected — the form must not submit until the user picks one explicitly.
- [ ] Replace the free-text "المدينة" input with a "المحافظة" `<select>` populated from `iraq-locations.js`. Replace "المنطقة" with a dependent `<select>` that repopulates from the chosen governorate's `areas` list whenever the governorate changes; when "أخرى" is selected in the area dropdown, reveal a free-text input for the area name.
- [ ] Replace the "أقل سعر" / "أعلى سعر" pair with a single "سقف الميزانية" number input. In the submit handler, compute `min_price` as 70% of the entered value (rounded) and send both `min_price` and `max_price` to `createRequest` — do not ask the user for `min_price` directly.
- [ ] Add a "نوع العقار" `<select>` (شقة / بيت / فيلا / دوبلكس) that is shown only when الفئة = سكني (residential) and hidden + cleared otherwise, wired to the new `property_subtype` field.
- [ ] Add a "مدة الإيجار" `<select>` (يومي / أسبوعي / شهري / سنوي), defaulting to "شهري", shown only when الغرض = إيجار (rent) and hidden + cleared (sent as `null`) when الغرض = شراء (buy).
- [ ] Wire `numerals.js`'s `toWesternDigits` to every numeric input's `input` event (budget, bedrooms, bathrooms) so Arabic-Indic digits typed by the user are converted live.
- [ ] Replace the single generic `#error` banner with per-field inline error messages shown under each invalid field on submit.

## Propagation

- [ ] Update `site/js/requests.js`: `createRequest` already spreads all passed fields — no signature change needed, but confirm the new field names (`purpose`, `governorate`, `area`, `property_subtype`, `rental_period`) match the migration column names exactly.
- [ ] Update `site/dashboard.html`'s request card rendering to add tags for المحافظة, الغرض, and سقف الميزانية alongside the existing category/city tags (use the same `createElement`/`textContent` pattern already used there — do not introduce `innerHTML`).
- [ ] Update `site/request.html`'s detail card to display all new fields (الغرض, المحافظة, المنطقة, نوع العقار, سقف الميزانية, مدة الإيجار when applicable) using the same safe DOM-building pattern already in that file.

## Verification (do this before marking the final task done)

- [ ] Manually walk the full flow locally: create a request with every new field filled, confirm it appears correctly on `dashboard.html` and `request.html`, confirm `buy` requests hide rental_period entirely, confirm Arabic digits typed into the budget field convert to Western digits before submit.
