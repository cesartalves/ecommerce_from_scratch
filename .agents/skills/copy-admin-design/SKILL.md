---
name: copy-admin-design
description: Reproduce, extend, or refactor Rails ERB admin screens so they match this repository's established visual system. Use when creating an admin page, translating a mockup or existing screen into the admin style, standardizing inconsistent admin UI, adding admin tables/forms/cards/empty states, or reviewing a screen for visual and responsive consistency with the Cesar Colecionismo admin.
---

# Copy Admin Design

Reproduce the admin's design language without cloning a screenshot mechanically. Preserve the application's Rails conventions, reuse existing classes, and add the smallest necessary CSS extension.

## Inspect the source of truth

Before editing, read:

- `app/views/layouts/admin.html.erb` for shell, navigation, flash, and content structure.
- `app/assets/stylesheets/admin.scss` for canonical components and breakpoints.
- One existing view closest to the requested screen under `app/views/admin/`.
- `references/design-system.md` for the component map and visual rules.

Treat live repository files as authoritative when they differ from the reference.

## Build the screen

1. Identify the nearest existing page archetype: dashboard, index/table, form, authentication, details, or empty state.
2. Reuse its ERB hierarchy and `admin-*` classes. Compose existing components before creating a new class.
3. Keep domain-specific data and actions accessible: semantic headings, labels, table headers, `data-label` on responsive table cells, `aria-label` where context is not visible, and descriptive button text.
4. Use Rails helpers (`link_to`, `button_to`, `form_with`, `number_to_currency`, `class_names`) instead of hand-built equivalents.
5. Add new CSS only when the existing component set cannot express the layout. Prefix additions with `admin-`, use the existing spacing/radius/color vocabulary, and group them beside the related component.
6. Implement mobile behavior at the established `1100px`, `767.98px`, and `520px` breakpoints. Never leave a desktop-only table or two-column form unusable on small screens.
7. Preserve loading, empty, error, validation, long-content, and missing-image/data states.

## Visual fidelity rules

- Preserve the dark navy shell, warm gold accent, pale blue-gray canvas, white panels, restrained shadows, and compact typography.
- Prefer hierarchy through spacing, weight, borders, and muted text. Do not add decorative gradients, saturated colors, oversized typography, or unrelated component libraries.
- Use the existing symbol vocabulary for small icons unless the project adopts an icon library globally.
- Keep actions predictable: primary gold, secondary outlined, destructive red, text links brown-gold.
- Match density to nearby screens. Admin interfaces should remain compact and scannable.

## Verify

After implementation:

1. Run the focused controller/system tests for the screen.
2. Run `bin/rubocop` on changed Ruby files and `git diff --check`.
3. Inspect the rendered page at desktop and mobile widths when browser tooling is available.
4. Check active navigation, overflow, focus states, blank data, validation errors, and action semantics.
5. Report any visual verification that could not be performed.

Do not rewrite unrelated admin CSS or redesign the global shell unless the user explicitly requests it.
