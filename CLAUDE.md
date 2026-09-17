# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

Create React App (`react-scripts` 3.1.1) project; no extra tooling configured.

```bash
npm start                      # dev server on http://localhost:3000
npm run build                  # production bundle to build/
npm test                       # Jest in interactive watch mode
npm test -- --watchAll=false   # single run (CI)
npm test -- -t "renders"       # run one test by name
```

Linting comes from the `react-app` ESLint preset via `react-scripts`; there is no standalone lint script — warnings surface in the `npm start` / `npm run build` output.

### Docker

```bash
docker compose up                              # dev server + hot reload on :3000
docker compose run --rm -e CI=true app npm test -- --watchAll=false
docker compose --profile prod up               # nginx-served production build on :8080
```

[Dockerfile](Dockerfile) is multi-stage: a shared `deps` stage runs `npm ci`, then `dev` (CRA dev server) and `builder` → `prod` (build copied into `nginx:1.27-alpine`).

Two pins in that setup are load-bearing and must not be "modernized":

- **`node:12-alpine`.** webpack 4 (via `react-scripts` 3.1.1) dies on Node >= 17 with `error:0308010C:digital envelope routines::unsupported`. Node 12 also bundles npm 6, which keeps `package-lock.json` at `lockfileVersion 1` instead of rewriting it.
- **The `node_modules` volume in [docker-compose.yml](docker-compose.yml).** The bind mount `.:/app` would otherwise shadow the image's `node_modules` with the (gitignored, usually absent) host directory. `CHOKIDAR_USEPOLLING=true` is what makes file watching work across that mount.

## Architecture

A single-screen sticky-note board. Three files carry all the behavior: [src/App.js](src/App.js), [src/components/Board.jsx](src/components/Board.jsx), [src/components/Note.jsx](src/components/Note.jsx).

**State ownership is split between Board and Note, and that split matters:**

- [Board.jsx](src/components/Board.jsx) owns the note *data* — `state.notes` is an array of `{ id, note }`. It exposes `add` / `remove` / `update` and passes `update`/`remove` down as `onChange`/`onRemove`. IDs come from `nextId()`, an instance counter (`this.uniqueId`) rather than state, so ids restart at 1 on every mount.
- [Note.jsx](src/components/Note.jsx) owns its *presentation* — the `editing` flag and its own position. Position is a random `right`/`top` computed **once in the constructor** from `window.innerWidth/innerHeight` and applied as an inline style; `<Draggable>` (react-draggable v3) then layers a CSS transform on top. Neither the random origin nor the drag offset is reported back to Board, so positions are lost on re-render-from-scratch and on reload.
- There is no persistence layer and no router. Reloading the page clears the board.

**Editing flow:** `edit()` flips `editing`, `render()` swaps `renderDisplay()` for `renderForm()`, and `componentDidUpdate` focuses/selects the textarea. Text reaches Board only when SAVE is clicked (`save()` → `props.onChange(text, id)`); typing does nothing until then. Both render paths emit a `div.note` with the same inline style, which is what keeps the Draggable wrapper's transform stable across the mode switch.

**Conventions in this code (pre-hooks React 16):** class components, class-property arrow methods for handlers, and **legacy string refs** (`ref="newText"` / `this.refs.newText`). Keep new code consistent with the surrounding component unless converting a component wholesale.

**DOM mount point is `#react-container`, not CRA's default `#root`** — [src/index.js](src/index.js) and [public/index.html](public/index.html) must stay in agreement. The service worker is registered-but-unregistered by default in [src/index.js](src/index.js).

**CSS:** all styling lives in [src/App.css](src/App.css), keyed off the `div.board` / `div.note` element+class selectors — renaming those classes or changing the element tags will silently break layout. Note that `App.js` wraps `Board` in a `div.board` and `Board` renders another `div.board` inside it; the nesting is intentional-by-accident, and `.board > button` (the `+` button) is positioned relative to the inner one.

## Lockfile caveat

`es-abstract@1.14.0` — a transitive dependency of `react-scripts` — was unpublished from the npm registry, so the original lockfile could no longer be installed at all (`npm ci` fails with a 404). Its lockfile entry is pinned to **1.14.2** instead: the nearest available patch, same dependency set, satisfies every range that requires it (`^1.5.1`, `^1.7.0`, `^1.11.0`, `^1.12.0`). It is the only such pin — the other 1307 name@version pairs in the lockfile all still resolve. Don't "fix" this by running `npm install`, which would float the whole transitive tree.

## Other agent configs

An OpenAI Codex config exists at `~/.codex/config.toml`. Reply `/import` to scan and list what's importable (MCP servers, slash commands, subagents, skills, instructions), then `/import --yes=<digest>` with the digest from the scan output to apply the user-level items.
