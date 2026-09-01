# Git Puller

A small native macOS app that pulls every repository you've added, in one click.

![icon](icon/GitPuller.iconset/icon_128x128.png)

## Using it

Open **Git Puller** from Applications (or Spotlight). Press **Pull All** — or ⌘R —
and every repo in the list is pulled at once. Each row shows its branch, a status
icon, and a one-line result; hover a row for git's full output.

- **+** adds a repository (pick one or more folders)
- **−** removes the selected one
- Right-click a row to reveal it in Finder, copy its path, or remove it

Your list is saved automatically to
`~/Library/Application Support/GitPuller/repos.json`.

## Behaviour notes

Pulls use `git pull --ff-only`, so a repo with diverging local commits reports a
failure rather than creating a surprise merge. Repos are pulled concurrently, so
one slow remote doesn't hold up the others. Authentication comes from your
existing git credential helper / keychain; the app never prompts for a password
(`GIT_TERMINAL_PROMPT=0`), so a repo needing fresh credentials fails visibly
instead of hanging.

## Building from source

```sh
./build.sh
```

Produces `build/Git Puller.app` — a universal (arm64 + x86_64) ad-hoc-signed
bundle. Copy it to `/Applications` to install.

Requires the Xcode command line tools. No third-party dependencies.

## Layout

```
Sources/GitPuller/
  GitPullerApp.swift   app entry point, menu commands
  ContentView.swift    the window: header, repo list, footer
  AppModel.swift       state, concurrent pull orchestration
  Git.swift            process wrapper around the git binary
  Models.swift         Repo / status types, JSON persistence
icon/
  RenderIcon.swift     draws the icon with Core Graphics
build.sh               renders icon, compiles, assembles, signs
```

The icon is generated, not a checked-in binary: `RenderIcon.swift` draws it at
all ten sizes and `iconutil` packs them into `.icns`.
