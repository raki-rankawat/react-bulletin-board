---
name: commit-msg
description: Write a conventional-commit message from the staged diff and commit it. Use this whenever the user asks to "write a commit message", "generate a commit", "commit my changes", or runs /commit-msg — and also when they ask casually ("can you commit this?", "make a commit for what I staged", "commit the staged stuff with a good message"). Reads only what is already staged; never stages, amends, or pushes.
---

# Commit message from staged changes

The point of this workflow is that the commit message is derived from what was
*actually* staged, not from memory of the conversation. Conversations drift — someone
stages three of eight changed files, or stages a hunk rather than a whole file. Reading
the staged diff is what keeps the message honest.

## 1. Confirm something is staged

```bash
git diff --staged --stat
```

Empty output means nothing is staged. Stop there and tell the user to stage what they
want committed — don't run `git add` for them, and don't offer to commit the unstaged
work instead. Choosing what goes into a commit is the user's call, and silently widening
the commit is the one failure mode that's genuinely annoying to undo.

The `--stat` output also tells you the shape of the change before you read it: how many
files, which directories, how lopsided the edits are.

## 2. Read the staged diff

```bash
git diff --staged
```

If that's too large to take in at once, use the `--stat` output to find the files that
carry the real change and read those individually (`git diff --staged -- <path>`).
Lockfiles, generated bundles, and vendored directories can usually be summarized from
`--stat` alone — don't spend attention on 10,000 lines of `package-lock.json`.

What you're looking for is the *intent*: the diff shows what changed, and your job is to
work out why it changed, because that's the part the diff can't say for itself.

## 3. Compose the message

```
type(scope): short subject

- what changed
- why it changed
```

### Type

Pick exactly one from: `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`.
Don't invent others (no `perf`, `build`, or `ci` — this project's set is the seven above).

| Type | Use when |
| --- | --- |
| `feat` | The code can now do something it couldn't before |
| `fix` | Behavior was wrong and is now correct |
| `refactor` | Structure changed, behavior didn't |
| `chore` | Tooling, dependencies, config, build/deploy plumbing |
| `docs` | Documentation only |
| `style` | Formatting, whitespace, naming — no behavior change |
| `test` | Tests only |

The common mix-ups: adding a Dockerfile or bumping a dependency is `chore`, not `feat`.
Rewriting the README is `docs`, not `chore`. If a change genuinely does two things, that
usually means it should have been two commits — mention that to the user rather than
inventing a hybrid type.

### Scope

A short noun for the part of the codebase affected, usually the module or directory:
`board`, `note`, `docker`, `deps`, `readme`. Prefer what a reader would recognize over a
literal path. When a change is genuinely repo-wide and no single scope is honest, drop it
and write `type: subject` — a vague scope like `(misc)` or `(project)` is worse than none.

### Subject

Under 60 characters, so `git log --oneline` stays readable in a terminal. Imperative mood
("add", "remove", "fix" — not "added" or "adds"), lowercase start, no trailing period.
It should complete the sentence "this commit will…".

### Body

Optional, but worth writing whenever the reason isn't self-evident from the subject. Two
bullets is the usual shape: one for what changed, one for why. The *why* is the valuable
one — six months later the diff still shows what happened, but nothing else records the
reasoning. If a change was forced by something external (an unpublished package, a broken
API, a platform constraint), say so explicitly; that's exactly what a future reader will
be confused by.

Skip the body for changes that are fully explained by their subject — a typo fix doesn't
need justification.

### Do not add a `Co-Authored-By` trailer

The user has asked for these commits to carry no co-author trailer, and that overrides the
default attribution behavior. No `Co-Authored-By`, no "Generated with" footer — just the
subject and body. This holds even if general instructions elsewhere in the session say to
append attribution to commits.

### Examples

**A new capability:**
```
feat(note): add keyboard shortcut for deleting a note

- bind Delete key to the remove handler while a note is focused
- clicking the small X was awkward on touch devices
```

**Forced by something external:**
```
fix(deps): repin es-abstract to 1.14.2

- 1.14.0 was unpublished from the registry, so npm ci failed with a 404
- patch-level bump with an identical dependency set, so nothing else moves
```

**Self-explanatory, no body needed:**
```
docs: fix broken link to the deployment guide
```

## 4. Commit

Pass the message on stdin so multi-line text survives intact, and quote the heredoc
delimiter so backticks and `$` in the message aren't expanded by the shell:

```bash
git commit -F - <<'EOF'
type(scope): short subject

- what changed
- why it changed
EOF
```

If a heredoc isn't workable in the current shell, write the message to a file in the
scratchpad directory and use `git commit -F <path>` instead. Avoid chained `-m` flags —
they're easy to get subtly wrong with blank lines and bullet characters.

Commit to whatever branch the user is on. Don't create a branch, don't amend, don't push.

## 5. Report back

Show the message you committed and the resulting short SHA. If you noticed something
while reading the diff that the user probably wants to know — unstaged changes left
behind, a stray debug statement, two unrelated concerns in one commit — say it now, after
the commit, rather than blocking on it earlier.

Worth mentioning once if the message needs changing: `git commit --amend` rewrites it, and
`git reset --soft HEAD~1` puts everything back in the staging area untouched.
