# Admin API Contract: Publish Configuration

**Feature**: 006-anonymous-publish-config
**Date**: 2025-12-28

## Overview

Admin endpoints for managing anonymous publish configuration. These endpoints are part of the admin web interface (not the public API).

## Endpoints

### GET /admin/publish-config

Display the publish configuration settings page.

**Response**: HTML page with configuration form

**Template Variables**:
```elixir
%{
  config: %{
    enabled: boolean(),
    updated_at: DateTime.t() | nil
  }
}
```

**HTML Elements**:
- Toggle switch for "Allow Anonymous Publishing"
- Current status indicator (Enabled/Disabled)
- Last updated timestamp
- Save button

---

### POST /admin/publish-config

Update the publish configuration settings.

**Request Body** (form data):
```
enabled=true|false
```

**Success Response**:
- Redirect to `GET /admin/publish-config`
- Flash message: "Publish configuration updated successfully"

**Error Response**:
- Redirect to `GET /admin/publish-config`
- Flash error: "Failed to update configuration: {reason}"

---

## UI Components

### Toggle Switch

DaisyUI toggle component:
```heex
<div class="form-control">
  <label class="label cursor-pointer">
    <span class="label-text">Allow Anonymous Publishing</span>
    <input
      type="checkbox"
      name="enabled"
      value="true"
      class="toggle toggle-primary"
      checked={@config.enabled}
    />
  </label>
</div>
```

### Confirmation Dialog

JavaScript confirmation on toggle change:
```javascript
// Show modal before form submission
document.getElementById('publish-config-form').addEventListener('submit', (e) => {
  const enabled = document.querySelector('[name=enabled]').checked;
  const message = enabled
    ? 'Enabling anonymous publishing allows anyone to publish packages without authentication. Continue?'
    : 'Disabling anonymous publishing will require authentication for all package publishes. Continue?';

  if (!confirm(message)) {
    e.preventDefault();
  }
});
```

### Status Badge

Current status display:
```heex
<div class="badge badge-{@config.enabled && "success" || "warning"}">
  {@config.enabled && "Enabled" || "Disabled"}
</div>
```

---

## Admin Navigation

Add link to admin sidebar:
```heex
<li>
  <.link href={~p"/admin/publish-config"}>
    <.icon name="hero-cog-6-tooth" />
    Publish Settings
  </.link>
</li>
```

Position: Under existing settings (Upstream, Storage)
