# AppBox SDK Example

A small SwiftUI app that links the AppBox SDK through SPM and publishes itself with the [AppBox fastlane plugin](https://github.com/getappbox/fastlane-plugin-appbox) — the whole loop in one project: fastlane builds and uploads, AppBox hosts, and the SDK inside the app finds the next build.

The app shows the version and build it is running, lets you check for an update on demand, and gets the SDK's own alert at launch when a newer build is published.

## Run it

```bash
open Example/AppBoxSDKExample.xcodeproj
```

The project references the package one directory up, so it always builds against the SDK in this checkout. Nothing to resolve, nothing to install.

## Publish it and watch it update

Two ways to do it: [`Scripts/upload.sh`](Scripts/upload.sh) drives `appboxcli` directly and needs nothing but Xcode, or the fastlane lanes do the same through the [AppBox plugin](https://github.com/getappbox/fastlane-plugin-appbox). Both upload with keep-same-link on.

Install the tooling once:

```bash
curl -s https://getappbox.com/install.sh | bash
```

Open AppBox, sign in with Dropbox, and install `appboxcli` from **AppBox ▸ Preferences ▸ General** — both the script and the fastlane plugin shell out to it.

### With the script

Check the machine is ready:

```bash
Example/Scripts/upload.sh --check
```

Then publish the first build, letting the script write the link it gets back into the sample:

```bash
Example/Scripts/upload.sh --set-link
```

It archives, exports a `debugging` (development) IPA, uploads with `appboxcli upload --keepsamelink`, and prints `APPBOX_SHARE_URL`, `APPBOX_IPA_URL` and `APPBOX_MANIFEST_URL`. With `--set-link` it also patches `fallbackInstallLink` in [`AppBoxSDKExample/ExampleConfiguration.swift`](AppBoxSDKExample/ExampleConfiguration.swift), so the *next* build is the first one that watches the link.

Build output is hidden: you get one line per step, and a failure prints only the error lines plus the path to the full log under `build/logs/`. `--verbose` streams everything instead.

Publish again and install that build on a device from the link:

```bash
Example/Scripts/upload.sh
```

Every run stamps a fresh `CFBundleVersion` from the clock, so each upload is a newer build of the same version. The example compares version *and* build, so the next run after that makes the installed app show the update alert when you reopen it.

| Option | What it does |
|---|---|
| `--check` | Run the preflight checks and stop. |
| `--ipa PATH` | Upload a prebuilt IPA instead of archiving one. |
| `--set-link` | Write the install link into `ExampleConfiguration.swift`. |
| `--emails a@b.com,c@d.com` | Email the install link as well. |
| `--message TEXT` | Personal message shown under "Message from the developer". |
| `--build-number N` | Use this `CFBundleVersion` instead of the timestamp. |
| `--verbose` | Stream the full build and upload logs instead of hiding them. |
| `--method`, `--team`, `--dbfolder`, `--slack-webhook`, `--teams-webhook` | Passed through to the export and to `appboxcli`. |

`--help` lists them all.

### With fastlane

```bash
bundle install
```

```bash
bundle exec fastlane install_plugins
```

```bash
bundle exec fastlane appbox_release
```

| Lane | What it does |
|---|---|
| `appbox_release` | Build, upload keeping the same link, print the install link. |
| `appbox_release_with_email` | The same, and email the link to `EMAILS`. |
| `build` | Build for the simulator without uploading — no signing needed. |

The lanes build with `gym` and upload with `appbox(keep_same_link: true)`, stamping the same clock-based build number (override it with `BUILD_NUMBER=…`). To email testers:

```bash
EMAILS=you@example.com bundle exec fastlane appbox_release_with_email
```

## Why keep-same-link matters

The SDK watches one link for the life of the installed app. With keep-same-link on, every upload replaces the build behind that one link, so a build already on a tester's device finds the next one. Without it each upload gets a fresh link and the installed build keeps watching an `appinfo.json` that never changes again.

## Passing the link without editing code

`ExampleConfiguration` also reads `APPBOX_INSTALL_LINK` from the environment, which the Xcode scheme can set — handy while trying different links from the simulator. An environment variable does not survive into an archived build, so a real upload needs the link in `fallbackInstallLink`.
