# Bulletin Board

A drag-and-drop sticky-note board built with React. Hit **+** to pin a new note to the
board, drag notes anywhere, and hover a note to reveal its **EDIT** and **X** buttons.
Notes start out asking "What's in your mind?" and land at a random spot, so the board
fills up the way a real one does.

Notes live in memory only — reloading the page clears the board.

Bootstrapped with [Create React App](https://github.com/facebook/create-react-app).

## Running with Docker

The quickest way to start, and it needs nothing installed but Docker:

```bash
docker compose up
```

Then open <http://localhost:3000>. Source is bind-mounted, so edits on your host
hot-reload inside the container.

```bash
# run the tests
docker compose run --rm -e CI=true app npm test -- --watchAll=false

# production build, served by nginx on http://localhost:8080
docker compose --profile prod up
```

## Running locally

Requires **Node 12.x**, the version this project targets. Node 17 and newer will not
build it — see [Node version](#node-version) below.

```bash
npm ci
npm start
```

### Available scripts

| Command | What it does |
| --- | --- |
| `npm start` | Dev server on <http://localhost:3000>, reloads on edit |
| `npm test` | Jest in interactive watch mode |
| `npm test -- --watchAll=false` | Single test run, for CI |
| `npm run build` | Production bundle into `build/` |
| `npm run eject` | Copies CRA's config into the project — **one-way, cannot be undone** |

Lint rules come from the `react-app` ESLint preset bundled with `react-scripts`; there is
no separate lint command, and warnings appear in the `npm start` and `npm run build` output.

## How it works

```
src/
  index.js              mounts <App> into #react-container
  App.js                page shell
  App.css               all styling, keyed off .board / .note selectors
  components/Board.jsx  owns the notes array, and add/edit/delete
  components/Note.jsx   owns one note's position and edit mode
```

`Board` holds the note data — an array of `{ id, note }` — and passes its `update` and
`remove` handlers down to each `Note`.

Each `Note` owns its own appearance: whether it is being edited, and where it sits. Its
starting position is a random `top`/`right` picked once when the note is created, and
[react-draggable](https://github.com/react-grid-layout/react-draggable) layers dragging on
top of that. Because neither the random origin nor the drag offset is reported back up to
`Board`, positions are not saved anywhere.

Editing a note swaps its display for a textarea, and the new text only reaches `Board`
when **SAVE** is clicked.

## Notes on dependencies

Dependencies are intentionally pinned to the versions this project was written against —
React 16.9 and `react-scripts` 3.1.1. Please don't upgrade them as a drive-by change.

### Node version

`react-scripts` 3.1.1 builds with webpack 4, which fails on Node 17 and newer with:

```
error:0308010C:digital envelope routines::unsupported
```

Use Node 12 (the LTS this project targets), or sidestep the problem entirely by using the
Docker setup, which pins `node:12-alpine`.

### One patched lockfile entry

`es-abstract@1.14.0`, a transitive dependency of `react-scripts`, was later unpublished
from the npm registry. That made the original lockfile impossible to install — `npm ci`
failed with a 404. Its entry is now pinned to `1.14.2`: the nearest available patch, with
an identical dependency set, satisfying every version range that asks for it.

It is the only such entry; every other pinned version in the lockfile still resolves.
Don't repair this with `npm install`, which would quietly float the whole transitive tree.
