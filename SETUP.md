# Setting up the mirror workflow

The [Mirror workflow](.github/workflows/mirror.yml) runs every night (and on
manual dispatch). It downloads the SSC archive, commits the snapshot to the
`releases` branch, and tags it with the date (for example `2026-09-24`). The
Deploy step, [peaceiris/actions-gh-pages](https://github.com/peaceiris/actions-gh-pages),
does the push, so the workflow needs a token that can **write** to the repository.

## Which token, and where

| Token | Where it comes from | What you need to do |
|-------|---------------------|---------------------|
| `GITHUB_TOKEN` (default, recommended) | GitHub creates it automatically for every workflow run. It is **not** a secret you add. | Make sure it has `contents: write` (see below). |
| Personal access token (optional) | You create it. Store it as a repository secret, e.g. `SSC_MIRROR_TOKEN`. | Only needed if `GITHUB_TOKEN` cannot be used (see [Alternative](#alternative-personal-access-token)). |

`secrets.GITHUB_TOKEN` is always there. You do not need to add it, and you
cannot. When the push fails with

```
remote: Permission to ssc-ng/archive.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/ssc-ng/archive.git/': The requested URL returned error: 403
```

the token exists but is **read-only**. Repositories and organizations created
since 2023 default to read-only workflow tokens, so moving the repository to
`ssc-ng` changed this.

## Option 1: grant write access in the workflow (already done)

The workflow file declares the permission it needs:

```yaml
permissions:
  contents: write
```

This works whatever the repository's default is, and nothing else needs to be
configured. To check the current repository default:

```bash
gh api repos/ssc-ng/archive/actions/permissions/workflow
# {"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}
```

## Option 2: change the repository default to read/write

Use this instead of, or as well as, Option 1:

```bash
gh api -X PUT repos/ssc-ng/archive/actions/permissions/workflow \
  -f default_workflow_permissions=write \
  -F can_approve_pull_request_reviews=false
```

In the web UI: *Settings → Actions → General → Workflow permissions → Read and
write permissions*.

If the option is greyed out, the organization restricts it. An org admin can
change the org-wide default:

```bash
gh auth refresh -h github.com -s admin:org   # the token needs the admin:org scope
gh api orgs/ssc-ng/actions/permissions/workflow
gh api -X PUT orgs/ssc-ng/actions/permissions/workflow \
  -f default_workflow_permissions=write \
  -F can_approve_pull_request_reviews=false
```

## Alternative: personal access token

Only use this if `GITHUB_TOKEN` cannot be given write access, or if pushes
from the mirror must trigger other workflows. Pushes made with `GITHUB_TOKEN`
do not trigger other workflows.

1. Create a fine-grained personal access token at
   <https://github.com/settings/personal-access-tokens/new>:
   - Resource owner: `ssc-ng`
   - Repository access: *Only select repositories* → `ssc-ng/archive`
   - Repository permissions: **Contents: Read and write**
   - Pick an expiration date and put a reminder in your calendar to rotate it.

   (The organization may need to approve fine-grained tokens:
   *ssc-ng → Settings → Personal access tokens*.)

2. Store it as a repository secret. `gh` prompts for the value, so it does not
   end up in your shell history:

   ```bash
   gh secret set SSC_MIRROR_TOKEN --repo ssc-ng/archive
   gh secret list --repo ssc-ng/archive
   ```

3. In [mirror.yml](.github/workflows/mirror.yml), change the Deploy step to use
   `personal_token` in place of `github_token`:

   ```yaml
       - name: Deploy
         uses: peaceiris/actions-gh-pages@v4
         with:
           personal_token: ${{ secrets.SSC_MIRROR_TOKEN }}
   ```

## Other things to check

- **Branch rules.** The `Protect main` ruleset applies only to the default
  branch. The Deploy step pushes a new commit directly to `releases` (no pull
  request) and creates tags, so do not add rules for `releases` or for tags
  unless `github-actions[bot]` (or the token owner) can bypass them:

  ```bash
  gh api repos/ssc-ng/archive/rulesets --jq '.[] | {id, name, target}'
  gh api repos/ssc-ng/archive/branches/releases/protection   # 404 = unprotected
  ```

- **Actions enabled.** Scheduled workflows are disabled after 60 days without
  repository activity, and in some cases after a repository is transferred:

  ```bash
  gh workflow list --repo ssc-ng/archive --all
  gh workflow enable mirror.yml --repo ssc-ng/archive
  ```

## Testing

Start a run by hand, with a suffix so its tag does not clash with the nightly
tag, and watch it:

```bash
gh workflow run mirror.yml --repo ssc-ng/archive -f suffix=-test
gh run watch --repo ssc-ng/archive $(gh run list --repo ssc-ng/archive --workflow mirror.yml --limit 1 --json databaseId --jq '.[0].databaseId')
gh run view --repo ssc-ng/archive --log-failed   # if it fails
```

Delete the test tag afterwards:

```bash
git push origin :refs/tags/$(date +%F)-test
```
