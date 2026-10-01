# Publishing a customized build with GitHub Actions

Two workflows build the app under **your own identity** (own application id,
bundle identifier, app name and default server) and publish it to Google Play
and Apple's App Store Connect. The committed project still carries the upstream
values (`de.wger.flutter`, `de.wger.flutter.community`, `wger`, `https://wger.de`);
the customization is applied at build time in CI only.

| Workflow | Trigger | Environment | Android | iOS |
| --- | --- | --- | --- | --- |
| `publish-qa.yml` | push to `master`, manual | `qa` | Play **internal** track | **TestFlight** |
| `publish-production.yml` | manual, push of a tag `v*.*.*` | `production` | Play **production** track (draft by default) | **App Store Connect** upload (no review submission by default) |

Both run the tests (`ci.yml`) first. The shared build and upload steps live in the
reusable workflows `publish-android.yml` and `publish-ios.yml`, and in the
composite actions `.github/actions/publish-config`, `android-sign` and
`ios-sign`. The upstream workflows (`make-release.yml`, `build-*.yml`) are
untouched, except that `ci.yml` accepts an optional `ref` and has a per caller
concurrency group.

## How the customization is injected

| What | Source | Mechanism |
| --- | --- | --- |
| Android application id | `APP_ID_ANDROID` | `WGER_APP_ID` env (or `-PappId=`) read by `android/app/build.gradle`, default `de.wger.flutter`. Only `applicationId` changes, the namespace and Kotlin package stay. |
| Android app name | `APP_NAME` | `WGER_APP_NAME` env (or `-PappName=`) becomes the `app_name` string resource, default `wger`. Debug builds append ` - debug`. |
| iOS bundle identifier | `APP_ID_IOS` | fastlane lane `customize` (`update_app_identifier`) rewrites `PRODUCT_BUNDLE_IDENTIFIER` in the checked out project. |
| iOS display name | `APP_NAME` | same lane, `update_info_plist` sets `CFBundleDisplayName`. |
| iOS signing | certificate and profile secrets | same lane, `update_code_signing_settings` switches the Runner target to manual signing with your team, identity and profile. |
| Default server | `QA_SERVER_URL` / `PROD_SERVER_URL` | `--dart-define=WGER_DEFAULT_SERVER=<url>`, read in `lib/core/consts.dart`. Unset or empty keeps `https://wger.de`. |
| Version name | `pubspec.yaml` | unchanged, e.g. `2.1.0` |
| Build number / version code | minutes since 2024 × 10 + run number mod 10 + `BUILD_NUMBER_OFFSET` | `flutter build ... --build-number` |

The publish workflows refuse to run with the upstream ids, so a missing variable
can never publish under the wger identity. Local and upstream builds are not
affected: without the environment variables and defines nothing changes.

You can try the same thing locally:

```sh
WGER_APP_ID=com.example.fit WGER_APP_NAME="Example Fit" \
  flutter build apk --dart-define=WGER_DEFAULT_SERVER=https://wger.example.com
```

## Variables

Create them under Settings > Secrets and variables > Actions > Variables, either
on the repository or on the environment (an environment value wins).

| Variable | Needed by | Example | Notes |
| --- | --- | --- | --- |
| `APP_ID_ANDROID` | Android | `com.example.fit` | Must not be, or start with, `de.wger.flutter`. |
| `APP_ID_IOS` | iOS | `com.example.fit` | Must not be, or start with, `de.wger.flutter`. Must match the App ID of the provisioning profile. |
| `APP_NAME` | both | `Example Fit` | At most 30 characters. |
| `QA_SERVER_URL` | qa | `https://qa.wger.example.com` | `https://`, trailing slash is removed. |
| `PROD_SERVER_URL` | production | `https://wger.example.com` | Same. |
| `BUILD_NUMBER_OFFSET` | optional | `0` | Added to the build number, see below. |
| `PLAY_RELEASE_STATUS` | optional, qa | `draft` | Release status of the internal track upload, default `completed`. Production uses the run input. |

### Build numbers

The build number is `minutes since 2024-01-01 UTC × 10 + run_number mod 10 +
BUILD_NUMBER_OFFSET`. It comes from the clock, so `publish-qa` and
`publish-production` share one rising sequence (Google Play and App Store Connect
want unique and rising numbers for the app as a whole, across all tracks), and the
run number keeps two builds started in the same minute apart.
`BUILD_NUMBER_OFFSET` is only needed when the app already has higher numbers in
the stores. Google Play only accepts version codes up to
2100000000, the workflow checks it. If you move an existing app to this
pipeline, set the offset above the highest number already uploaded.

## Secrets

Create them as environment secrets on `qa` and on `production` (they may hold
different values, for example separate keystores), or as repository secrets if
both share them.

| Secret | Platform | Content |
| --- | --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Android | Upload keystore, base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Android | Password of the keystore |
| `ANDROID_KEY_ALIAS` | Android | Alias of the key |
| `ANDROID_KEY_PASSWORD` | Android | Password of the key |
| `PLAY_SERVICE_ACCOUNT_JSON` | Android | Google Cloud service account key (the whole json) |
| `IOS_DIST_CERT_P12_BASE64` | iOS | Apple Distribution certificate with private key (.p12), base64 |
| `IOS_DIST_CERT_PASSWORD` | iOS | Password chosen when exporting the .p12 |
| `IOS_PROVISIONING_PROFILE_BASE64` | iOS | App Store provisioning profile, base64 |
| `ASC_KEY_ID` | iOS | App Store Connect API key id |
| `ASC_ISSUER_ID` | iOS | App Store Connect issuer id |
| `ASC_KEY_P8_BASE64` | iOS | The API key file (.p8), base64 |

Every job starts with a check that lists **all** missing secrets and variables
at once (in the log and the run summary) before anything is built.

### Android keystore

Create an upload key once (or reuse yours) and keep a backup of it:

```sh
keytool -genkeypair -v -keystore upload-keystore.jks -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 upload-keystore.jks        # macOS: base64 -i upload-keystore.jks
```

Paste the output into `ANDROID_KEYSTORE_BASE64`, and the passwords and alias you
chose into the other three secrets. The workflow writes the keystore to the
runner's temp folder and the `key.properties` that `android/app/build.gradle`
expects to `fastlane/metadata/envfiles/key.properties` (git ignored), and checks
the password and alias with `keytool` before building. Use Play App Signing, so
this is only the upload key and can be reset by Google if it is ever lost.

### Google Play service account

1. Play Console > Setup > API access (or Users and permissions > Invite new
   users): link or create a Google Cloud project.
2. In Google Cloud, IAM > Service accounts > Create service account, then Keys >
   Add key > JSON. Enable the *Google Play Android Developer API* in that
   project.
3. In the Play Console, invite the service account's e-mail address as a user
   and grant it access to your app with the permissions *Release to testing
   tracks* (qa) and *Release to production* (production). *View app information*
   is also needed.
4. Paste the complete json file into `PLAY_SERVICE_ACCOUNT_JSON`.

Create the app in the Play Console (with the package name from
`APP_ID_ANDROID`) and upload the first bundle by hand once; the API can't create
an app. While the app has never been released the API only accepts drafts, set
the repository variable `PLAY_RELEASE_STATUS=draft` for those first QA uploads
and remove it afterwards.

The pipeline uploads the bundle only. It never touches the store listing: the
texts and screenshots in `fastlane/metadata` describe upstream wger.

### App Store Connect API key

1. App Store Connect > Users and Access > Integrations > App Store Connect API >
   Team Keys > Generate. The *App Manager* role is enough.
2. Note the *Key ID* (`ASC_KEY_ID`) and the *Issuer ID* shown above the table
   (`ASC_ISSUER_ID`).
3. Download the `AuthKey_XXXX.p8` (only possible once) and run
   `base64 -i AuthKey_XXXX.p8 | pbcopy` (Linux: `base64 -w0`) into
   `ASC_KEY_P8_BASE64`.

Create the app record in App Store Connect first (bundle identifier from
`APP_ID_IOS`).

### Distribution certificate and provisioning profile

1. Developer portal > Certificates: create an *Apple Distribution* certificate
   (or reuse one). Install it in your Mac's Keychain Access.
2. In Keychain Access select the certificate **together with its private key**
   > Export as .p12 and choose a password (`IOS_DIST_CERT_PASSWORD`). Then
   `base64 -i Certificates.p12 | pbcopy` into `IOS_DIST_CERT_P12_BASE64`.
3. Developer portal > Identifiers: register the App ID with the bundle
   identifier from `APP_ID_IOS` and the capabilities the app uses. The app has an
   entitlements file (`ios/Runner/Runner.entitlements`): enable *HealthKit* and
   *Push Notifications* on the App ID.
4. Developer portal > Profiles: create an *App Store Connect* distribution
   profile for that App ID and certificate, download the `.mobileprovision`, and
   `base64 -i profile.mobileprovision | pbcopy` into
   `IOS_PROVISIONING_PROFILE_BASE64`.

The workflow imports the certificate into a temporary keychain, installs the
profile, checks that the profile fits the bundle identifier and is not a
development profile, builds with `flutter build ipa --export-options-plist` and
deletes the keychain at the end. Certificates and profiles expire after a year,
renew them and update the two secrets.

## Environments

Create both under Settings > Environments.

* `qa`: no protection rules needed.
* `production`: add **Required reviewers** (and optionally restrict deployment
  branches and tags). The Android and iOS jobs both wait for approval before they
  receive the production secrets. One approval in the run's *Review deployments*
  dialog releases both. Put the production secrets here, not on the repository,
  so they only exist behind that gate.

The jobs use `secrets: inherit`, so environment and repository secrets and
variables are both found.

## Triggering

### QA

* Every push to `master` (except pure documentation changes) tests the code, then
  publishes Android to the internal track and iOS to TestFlight.
* Manually: Actions > *Publish QA* > Run workflow. The branch you pick is built,
  also a feature branch.

The internal track needs the testers to be added in the Play Console, TestFlight
needs them in App Store Connect. Apple takes a few minutes to process an upload
before it is available, the workflow does not wait for it. Runs are queued, a
newer push waits for the one that is uploading.

### Production

* Actions > *Publish production* > Run workflow. Enter the branch, tag or commit,
  choose the platforms, the Play release status (`draft` or `completed`) and
  whether to submit the iOS build for review.
* Or push a tag: `git tag v2.1.0 && git push origin v2.1.0`. The tag has to match
  the version in `pubspec.yaml` (`2.1.0`), otherwise the run stops. Tag runs
  publish both platforms with the defaults: Play `draft`, no review submission.

The commit is pinned at the start, so a branch moving while the run waits for
approval does not change what is built. Tests run first, then, after approval,
the builds. With a `draft` Play release open the Play Console, check it and roll
it out. For iOS, the build appears in App Store Connect; add it to a version, fill
in the listing and submit it, or tick *ios_submit_for_review* if the version is
already prepared there. The pipeline never uploads metadata or screenshots.

Note that the upstream `make-release.yml` pushes tags without a `v` prefix
(`2.1.0`), so it does not start this workflow.

## Artifacts

Every run uploads the signed bundle (`aab-<environment>-<run number>`) and the
.ipa (`ipa-<environment>-<run number>`), kept for 30 days, so you can see exactly
what was published or install it by hand.

## Troubleshooting

* *Missing secrets / variables*: the preflight step names them, fix them in the
  right environment.
* *Version code has already been used* (Play) or *build number already used*
  (App Store Connect): raise `BUILD_NUMBER_OFFSET`.
* *Only releases with status draft may be created on draft app*: the app was
  never released, use a draft (see the service account section).
* *No profile / identity matching* on iOS: the profile's App ID, certificate
  and the bundle identifier must belong together, the log of the *Set up
  signing* step shows what was found.
* To check the identity changes without publishing, build locally as shown
  under *How the customization is injected*.
