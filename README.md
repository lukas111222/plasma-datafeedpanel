# Plasma 6 Data Feed Panel Plasmoid

This Plasma 6 plasmoid polls a JSON API endpoint, extracts one or more values via configurable JSON paths, and shows them in the panel.

## Features

- Configurable API URL (default: `http://localhost:3000`)
- Configurable HTTP request headers (for example `Authorization: Bearer <token>`)
- Configurable widget title
- Configurable JSON paths (for example `value` and `value2`)
- Separate configurable hover JSON paths for tooltip-only values
- Configurable number of displayed values
- Configurable separator between values
- Separate configurable hover separator (supports `\\n` for line breaks)
- Configurable refresh interval in seconds (default: `60`)
- Configurable display width in pixels for panel text
- Configurable text alignment (left, center, right)
- Placeholder output (`--`) during startup and on errors
- Overlap protection for slow requests

## Expected API Contract

Default payload:

```json
{
  "value": 10,
  "value2": 42
}
```

Each target value can be a number or a string. Empty strings are treated as invalid.

## Local Install (Plasma 6)

From the project root:

```bash
kpackagetool6 -t Plasma/Applet -i .
```

If it was already installed, update with:

```bash
kpackagetool6 -t Plasma/Applet -u .
```

Then add the widget in Plasma:

1. Open panel edit mode.
2. Add widgets.
3. Search for `Data Feed Panel`.
4. Place it on the panel.

Optional quick preview outside panel integration:

```bash
plasmoidviewer -a de.lukasb04.datafeedpanel
```

## Build .plasmoid Bundle

Create an installable bundle from the project root:

```bash
./build.sh
```

This creates:

- `dist/de.lukasb04.datafeedpanel-<version>.plasmoid`

The script reads `KPlugin.Id` and `KPlugin.Version` from `metadata.json`.

Requirements:

- `zip` must be installed.

Install on a client:

```bash
kpackagetool6 -t Plasma/Applet -i dist/de.lukasb04.datafeedpanel-0.1.0.plasmoid
```

Update on a client:

```bash
kpackagetool6 -t Plasma/Applet -u dist/de.lukasb04.datafeedpanel-0.1.0.plasmoid
```

## Create Release Artifact

Create a new release bundle from the project root:

```bash
./release.sh
```

Alternative modes:

```bash
# Keep version as-is, only build + checksum
./release.sh --no-bump

# Set an explicit version, then build + checksum
./release.sh --set-version 0.2.0
```

What it does:

1. By default, bumps `KPlugin.Version` patch version in `metadata.json` (for example `0.1.0 -> 0.1.1`).
2. Runs `./build.sh`.
3. Writes a SHA256 checksum file next to the artifact.

Requirements:

- `sha256sum` or `shasum` must be installed.

Result files:

- `dist/<plugin-id>-<new-version>.plasmoid`
- `dist/<plugin-id>-<new-version>.plasmoid.sha256`

## GitHub Actions (Build + Release)

This repository includes two workflows:

- `.github/workflows/ci-build.yml`
  - Runs on every push and pull request.
  - Executes `./build.sh`.
  - Uploads `dist/*.plasmoid` as a workflow artifact.

- `.github/workflows/release.yml`
  - Runs on tags matching `v*.*.*`.
  - Executes `./release.sh --no-bump`.
  - Verifies that tag version matches `metadata.json` version.
  - Publishes `dist/*.plasmoid` and `dist/*.sha256` to GitHub Releases.

Release process:

1. Update `metadata.json` version (for example to `0.2.0`) and push commit.
2. Create and push a matching tag:

```bash
git tag v0.2.0
git push origin v0.2.0
```

3. The release workflow builds and publishes assets automatically.

Important:

- Tag and metadata version must match exactly, otherwise release fails.
- `workflow_dispatch` can run the workflow manually, but publishing is only done for tag runs.

## Configuration

Widget settings expose:

- API URL
- HTTP request headers (one header per line, format `Name: Value`)
- Title
- JSON paths list (line-, comma-, or semicolon-separated)
- Hover JSON paths list (line-, comma-, or semicolon-separated)
- Number of values to display
- Separator between displayed values
- Hover separator between tooltip values
- Refresh interval in seconds
- Display width in pixels (panel view)
- Text alignment (left, center, right)

Invalid values or fetch/parsing errors display `--` until a successful fetch occurs.

## Verification Checklist

1. API returns valid JSON with a number or text value and the widget shows that value.
2. Update API value and confirm the panel updates within the configured interval.
3. Break the API (stop server/return invalid JSON) and confirm `--` is shown.
4. Restore API and confirm the widget recovers automatically.
5. Change URL/path/interval in configuration and verify behavior updates accordingly.
