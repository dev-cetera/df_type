# Release workflow

This package ships through a two-stage GitHub Actions pipeline:

```
push to prod  ──►  prod.yml  ──►  pushes tag v{version}  ──►  publish.yml  ──►  pub.dev
                   (test, bump, tag)                          (re-test, publish)
```

Splitting test-and-tag from publish lets pub.dev's "tag pattern" automated
publishing config stay in charge of who can actually ship — only a tagged
commit ever triggers a publish.

## Workflows

### `prod.yml` — runs on push to `prod`

1. `dart format --set-exit-if-changed`
2. `dart analyze --fatal-infos`
3. `dart test`
4. **Decides the next version.**
   - If the `version:` in `pubspec.yaml` is **not** yet tagged on the
     remote, the workflow assumes you already bumped it manually and uses
     it as-is.
   - Otherwise it inspects the latest commit subject:
     - Contains `BREAKING CHANGE`, starts with `breaking:`, or uses the
       conventional `feat!:` / `fix!:` syntax → **major** bump.
     - Starts with `feat` (`feat:`, `feat(scope):`, `feat ...`) → **minor**.
     - Anything else → **patch**.
5. **Applies the bump.** `pubspec.yaml` is updated; `CHANGELOG.md` gets a
   new `## [version]` section assembled from the commit subject + any
   `- bullet` body lines, but only if no entry for that version exists yet.
6. **Commits the bump** back to `prod` as `ci: release v{version}`.
   The bot's commit-author email is used to filter out self-triggers so
   the workflow does not re-run on its own push.
7. **Pushes the `v{version}` tag.**

If any step before 5 fails, the tag is **not** pushed and the publish never
happens.

### `publish.yml` — runs on push of a `v*` tag

1. `dart analyze --fatal-infos` and `dart test` (defensive — guards against
   hand-tagged commits).
2. Confirms the tag version matches `pubspec.yaml`.
3. `dart pub publish --force` over OIDC.

## How to ship a release

The fast path:

1. Make changes on a branch.
2. Merge to `prod`. That's it.
3. The workflow bumps patch (or minor/major if your commit message says so),
   writes a CHANGELOG entry, tags, and publishes.

The deliberate path — when you want full control:

1. Bump `version:` in `pubspec.yaml` yourself.
2. Use the `/changelog` Claude command (`.claude/commands/changelog.md`) to
   draft `CHANGELOG.md` from your diff.
3. Merge to `prod`. The workflow notices the version is already untagged,
   skips the auto-bump, and just tags + publishes.

## Commit-message conventions for auto-bump

| Want                | Commit subject example                  | Bump  |
| ------------------- | --------------------------------------- | ----- |
| Major (breaking)    | `breaking: drop deprecated API`         | major |
| Major (conv. style) | `feat!: rewrite token loop`             | major |
| Major (with body)   | `feat: new API` + `BREAKING CHANGE: …`  | major |
| Minor (new feature) | `feat: add letDurationOrNull`           | minor |
| Patch (anything)    | `fix: handle NaN in letIntOrNull`       | patch |
| Patch (default)     | `tweak imports`                         | patch |

## One-time setup

### 1. pub.dev automated publishing

For `publish.yml` to authenticate against pub.dev:

- pub.dev → package page → **Admin** tab.
- Under **Automated publishing**, enable **Publishing from GitHub Actions**.
- Repository: `<owner>/<repo>` (this package's repo).
- Tag pattern: `v{{version}}`.

See https://dart.dev/tools/pub/automated-publishing for details.

### 2. `RELEASE_PAT` repository secret

`prod.yml` needs a Personal Access Token to push the version tag back to
the repo. **This cannot be the default `GITHUB_TOKEN`** — tags pushed by
GITHUB_TOKEN do not trigger downstream workflows by design, so
`publish.yml` would never fire on its own.

Create the token at <https://github.com/settings/personal-access-tokens>:

- **Token name**: anything descriptive.
- **Expiration**: 1 year is a good default; the workflow will start failing
  with a clear `git push` auth error when it expires, prompting a rotation.
- **Repository access**: Only select repositories → this package's repo.
- **Repository permissions** → **Contents**: Read and write.
- Everything else: No access.

Store it on the repo:

- Repo **Settings** → **Secrets and variables** → **Actions** → **New
  repository secret**.
- **Name**: `RELEASE_PAT`. **Secret**: paste the token.

Without `RELEASE_PAT`, `prod.yml` fails at the checkout step with a clear
"required secret missing" error so you can't silently push without it.
