# Quickstart: Anonymous Publish Configuration

**Feature**: 006-anonymous-publish-config
**Date**: 2025-12-28

## Overview

This guide demonstrates how to configure and use anonymous package publishing in HexHub.

## Prerequisites

- HexHub server running (development or production)
- Admin access to the admin dashboard
- Mix installed (for testing package publishing)

## Scenario 1: Enable Anonymous Publishing (Admin)

### Step 1: Access Admin Dashboard

Navigate to the admin dashboard:
```
http://localhost:4001/admin
```

### Step 2: Open Publish Settings

Click "Publish Settings" in the sidebar under Settings section.

### Step 3: Enable Anonymous Publishing

1. Toggle "Allow Anonymous Publishing" to **ON**
2. Read the confirmation dialog explaining the implications
3. Click "Confirm" to enable

### Step 4: Verify Setting

The status badge should show **Enabled** (green).

---

## Scenario 2: Publish Package Anonymously

### Prerequisites

- Anonymous publishing is enabled (Scenario 1)
- A valid Elixir package with `mix.exs`

### Step 1: Create Test Package

```bash
mkdir test_package && cd test_package

cat > mix.exs << 'EOF'
defmodule TestPackage.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_package,
      version: "0.1.0",
      elixir: "~> 1.15",
      description: "A test package for anonymous publishing",
      package: package()
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{}
    ]
  end
end
EOF

cat > lib/test_package.ex << 'EOF'
defmodule TestPackage do
  def hello, do: :world
end
EOF
```

### Step 2: Configure HexHub as Mirror

```bash
export HEX_MIRROR=http://localhost:4000
```

### Step 3: Publish Without Authentication

```bash
mix hex.publish package --yes
```

**Expected Output**:
```
Building test_package 0.1.0
  Included files:
    lib/test_package.ex
    mix.exs
Publishing test_package 0.1.0
Package published successfully.
```

### Step 4: Verify Publication

Check the package list:
```bash
curl http://localhost:4000/api/packages | jq '.packages[] | select(.name == "test_package")'
```

**Expected**: Package exists with "anonymous" as the owner.

---

## Scenario 3: Verify Anonymous User in Admin

### Step 1: Access Admin Users Page

Navigate to:
```
http://localhost:4001/admin/users
```

### Step 2: Find Anonymous User

Look for the user with:
- Username: `anonymous`
- Badge: "System User" indicator

### Step 3: View Anonymous User's Packages

Click on the "anonymous" user to see all packages published anonymously.

---

## Scenario 4: Disable Anonymous Publishing

### Step 1: Open Publish Settings

Navigate to:
```
http://localhost:4001/admin/publish-config
```

### Step 2: Disable

1. Toggle "Allow Anonymous Publishing" to **OFF**
2. Confirm the change

### Step 3: Verify Rejection

Try publishing without auth:
```bash
unset HEX_API_KEY
mix hex.publish package --yes
```

**Expected Output**:
```
** (Mix) Request failed: Authentication required
```

---

## Scenario 5: View Audit Logs

### Check Anonymous Publish Events

View server logs for anonymous publish entries:
```bash
grep "anonymous_publish" log/dev.log
```

**Expected Log Entry**:
```
[info] [package] Anonymous package publish package=test_package version=0.1.0 ip_address=127.0.0.1 duration_ms=150
```

---

## Verification Checklist

| Test | Expected Result |
|------|-----------------|
| Enable anonymous publishing | Setting persists, UI shows "Enabled" |
| Publish without API key (enabled) | Package published, attributed to "anonymous" |
| Publish without API key (disabled) | 401 Unauthorized error |
| View anonymous user | Shown in admin with system badge |
| Cannot delete anonymous user | Error: "Cannot delete system user" |
| Register as "anonymous" | Error: "Username is reserved" |

---

## Troubleshooting

### "Anonymous user not found"

The anonymous user is created on application startup. Restart the server:
```bash
mix phx.server
```

### "Setting not persisting"

Check Mnesia is running:
```elixir
iex> :mnesia.info()
```

### "Package shows wrong owner"

If published with valid API key, package is attributed to authenticated user, not "anonymous". This is expected behavior.

---

## API Reference

### Check Anonymous Publishing Status

```bash
# Via admin API (requires auth)
curl http://localhost:4001/admin/publish-config
```

### Publish Anonymously (when enabled)

```bash
curl -X POST \
  -H "Content-Type: application/octet-stream" \
  --data-binary @package.tar.gz \
  http://localhost:4000/publish
```
