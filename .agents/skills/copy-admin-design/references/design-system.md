# Admin design system

## Source map

| Concern | Canonical source |
|---|---|
| Shell and navigation | `app/views/layouts/admin.html.erb` |
| Tokens and components | `app/assets/stylesheets/admin.scss` |
| Dashboard/cards | `app/views/admin/dashboard/index.html.erb` |
| Responsive data tables | `app/views/admin/products/index.html.erb`, `app/views/admin/orders/index.html.erb` |
| Forms and validation | `app/views/admin/products/_form.html.erb` |
| Authentication | `app/views/admin/login/login.html.erb` |
| Detail page | `app/views/admin/customers/show.html.erb` |

## Visual vocabulary

- Canvas: `#f3f6f9`; primary text: `#17212f`; shell: `#101a27`.
- Accent: `#e8b44c`; accent text/links use darker golds such as `#9a6a0c` and `#8a5c05`.
- Panels: white with `#e0e6ec` border, 15–16px radius, and low-opacity blue-gray shadow.
- Muted copy: blue-grays around `#708093`, `#8390a0`, and `#96a2b0`.
- Font stack: Inter with system sans-serif fallbacks.
- Page titles: compact negative tracking, strong weight, approximately 2.35rem desktop and 1.8rem mobile.
- Body/table copy: compact, generally 0.68–0.92rem.

Use these as a vocabulary, not duplicated variables. Prefer existing selectors from `admin.scss`.

## Component map

- Page heading: `.admin-page-heading`, `.admin-eyebrow`, optional `.admin-count` and action.
- Content surface: `.admin-panel`, `.admin-panel__header`, `.admin-panel__body`.
- Metrics: `.admin-stats`, `.admin-stat-card`, icon/label/value descendants.
- Buttons: `.admin-button` plus `--primary`, `--secondary`, `--danger`, `--small`, or `--block`.
- Tables: `.admin-table-wrap`, `.admin-table`; add a page-specific modifier when mobile card transformation is needed.
- Forms: `.admin-form`, `.admin-form-grid`, `.admin-field`, `--wide`, `.admin-form-actions`, `.admin-form-errors`.
- Status: `.admin-badge` with semantic modifiers.
- Feedback: `.admin-flash`, `.admin-empty-state`, `.admin-muted`.
- Details: `.admin-detail-grid`, `.admin-detail-list`.

## Responsive contract

- At 1100px: reduce content gutters and collapse four metrics into two columns.
- At 767.98px: replace the fixed sidebar with horizontal navigation; reduce content padding; transform designated tables into labeled card rows using each cell's `data-label`.
- At 520px: stack headings/actions, metrics, form fields, and form actions into one column.
- Add screen-specific responsive rules only after applying this existing contract.

## Page recipe

```erb
<% content_for :title, "Título" %>

<div class="admin-page-heading">
  <div>
    <span class="admin-eyebrow">Contexto</span>
    <h1>Título</h1>
    <p>Descrição curta e operacional.</p>
  </div>
  <%= link_to "Ação", destination_path, class: "admin-button admin-button--primary" %>
</div>

<section class="admin-panel">
  <div class="admin-panel__header">
    <div>
      <h2>Seção</h2>
      <p>Explicação curta.</p>
    </div>
  </div>
  <div class="admin-panel__body">
    <!-- Conteúdo -->
  </div>
</section>
```

Adapt the recipe to the nearest real screen; do not force every page into it.
