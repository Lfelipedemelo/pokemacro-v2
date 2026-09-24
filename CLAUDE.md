# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

PokéMacro — a macro toolkit for the Pokémon MMO **PokéXGames** (game process `pxgme.exe`, constant `JOGO_EXE` in `lib/window.ahk`), written in **AutoHotkey v2.0** (not v1.x — syntax is incompatible). The entire UI (HUD + config screens) is hand-drawn with GDI+ in layered windows; there are no native Win32 controls. README.md (in Portuguese) is the end-user documentation — code comments are also in Portuguese.

Entry point: `pokemacro.ahk`, which just `#Include`s every module in dependency order and starts the app. There is no build step — AutoHotkey scripts run directly.

## Running / verifying changes

There is no test suite. To check a change:

- **Run it for real**: double-click `pokemacro.ahk` (or run it via AutoHotkey v2) and exercise the HUD/macro in question. `Ctrl+F12` opens/closes the HUD.
- **Syntax-only check** (no test suite exists): AutoHotkey v2 is at `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`. `/validate` does not work on this install; instead do a load-only run redirecting stderr, e.g. via PowerShell `Start-Process` with `/ErrorStdOut=UTF-8 /iLib <out> <file>`. For catching undefined-variable typos, wrap the target in a throwaway file with `#Warn VarUnset, StdOut` plus the relevant `#Include`s.
- **Logic smoke test**: write a small harness that `#Include`s the modules under test and points `configFile` (see `lib/globals.ahk`) at a temp copy of `config.ini` so real user config isn't touched.
- `config.ini` is gitignored and holds the live user's key bindings/positions — never commit it, and don't treat its current contents as canonical when reasoning about defaults (see `GetCfg` in `lib/config.ahk` for actual defaults).

**Never bulk-edit `.ahk`/`.md` files with PowerShell `Get-Content`/`Set-Content` text pipelines** — it mis-decodes this repo's UTF-8 (no BOM) files and mojibakes accented Portuguese characters, and can add a stray BOM. Use the Edit tool for text changes; if raw bytes must be touched (e.g. stripping a BOM), use `ReadAllBytes`/`WriteAllBytes`, never decoded-text pipelines.

## Architecture

### Module layout (loaded in this order by `pokemacro.ahk`)

- `lib/globals.ahk` — global state (`macros` map of on/off flags, `MACROS_INFO` metadata per macro, `COMBOS_EXCLUSIVOS`, UI scale helpers, the fixed color theme `T()`).
- `lib/config.ahk` — **the only** path to `config.ini`. `CfgLer(secao, chave, padrao)` reads (cached in memory — `IniRead` is file I/O and used to be called 100+ times per keypress), `SalvarCfg(secao, chave, valor)` writes and updates the cache, `ResetarSecao(secao)` deletes a whole INI section and re-registers hotkeys. `GetCfg(tipo)` assembles the full config Map a macro needs. **Never call `IniRead`/`IniWrite` directly anywhere else.**
- `lib/gdip.ahk` — low-level GDI+ wrapper (layered-window canvas, brushes, text, image tinting/scaling/caching).
- `lib/gdip_config.ahk` — shared framework for **config screens**: `_GCfg_Abrir(w, h, drawFn)` opens a layered window and calls `drawFn(g, w, h, hoverId)` on every redraw to draw widgets and return hit-test boxes; mouse routing, dragging, slider editing, and the in-window confirm overlay (`_GCfg_Confirmar`, replaces native MsgBox dialogs) all live here. Only one config screen is open at a time — opening another closes the previous one. Reusable widgets: `_GCfg_Field`, `_GCfg_Toggle`, `_GCfg_Segmented`, `_GCfg_Slider`, `_GCfg_MiniSlider`, `_GCfg_MiniButton`, `_GCfg_ShowInMini`, `_GCfg_Header`.
- `lib/hint.ahk` — `ShowHint(text, time, kind)` floating notification banner (kind: info/success/warn/danger), same GDI+ layered-window technique.
- `lib/window.ahk` — window helpers shared by the HUD and config screens: `JogoAtivo()` (is the game focused), `DragJanela`, `Win_MostrarSemAtivar`, `Win_ArmarMouseLeave`, `Win_DecodeXY`, and elevation detection (`VerificarElevacaoJogo` — if the game runs as admin but the script doesn't, Windows silently blocks sent keys/hotkeys; the script detects this and offers to relaunch itself elevated).
- `lib/input.ahk` — key/position capture used by config screens: `CapturarTecla` (single key, used for keys the macro *sends to the game*), `CapturarCombo` (key + optional Ctrl/Alt/Shift, used for hotkeys), `CapturarPosicaoMouse`. Both capture flows route through `_SalvarTeclaCapturada`, which checks `ConflitoDeTecla` before saving. `LButton`/`RButton` are always rejected as macro keys (they'd stop reaching the game).
- `ui/mini_menu.ahk` — the HUD, the app's main interface (`Ctrl+F12` toggles it). Floating bar of macro icons; hovering reveals a ⚙ per macro (opens that macro's config screen) plus a global ⚙ and ✕. Runs its own 60fps redraw loop during hover/animation, so it scales layout constants before drawing rather than transforming the whole `Graphics` (unlike `gdip_config.ahk`, which redraws only on interaction and can afford a transform-based scale).
- `ui/config_*.ahk` — one file per config screen (combo, revive, combo_revive, cooldown, geral), each built from the `_GCfg_*` widgets above.
- `macros/hotkeys.ahk` — macro on/off state and the hotkey system. `DefinirMacro`/`AlternarMacro`/`DesligarTodosMacros` are the **only** way to change `macros[]` — they own combo-exclusivity logic and trigger the HUD redraw. `AtualizarHotkeyCombo()` re-registers all AHK hotkeys from the INI; it reuses static `HotIf` criterion objects (AHK identifies a hotkey variant by its criterion object, so recreating closures breaks `Hotkey(..., "Off")`) and must be called whenever a *key* changes — not on every toggle, since criteria re-check `macros[]` live at keypress time. `ProcessarPressionamento` is the central dispatcher for macro-execution hotkeys.
- `macros/combo.ahk`, `macros/revive.ahk`, `macros/combo_revive.ahk`, `macros/cooldown.ahk` — macro execution logic (see below).

### Macro system

- Five macros, tracked in `macros` (bool map) and described in `MACROS_INFO` (globals.ahk): `comboPrincipal`, `comboSecundario`, `comboRevive`, `revive`, `cooldown`. Each maps to an INI section and an "exec" key (the hotkey that runs it); the toggle key is always `toggleHotkey` in that same section.
- `comboPrincipal`/`comboSecundario`/`comboRevive` are **mutually exclusive** (`COMBOS_EXCLUSIVOS`) — turning one on turns the others off via `DefinirMacro`.
- `interrompivel` (in `MACROS_INFO`) controls both whether a macro's hotkey fires while another macro is mid-execution, and whether pressing it interrupts a running combo (`revive`, `comboRevive`, `cooldown` are interruptible; the two plain combos are not, guarded by `_macroExecutando` in `ProcessarPressionamento`).
- Combo sequencing (`_RodarSequenciaCombo` in `combo.ahk`) is shared by `comboPrincipal`/`comboSecundario`/`comboRevive`: optional Full Attack key → sequential keys from `teclaInicial` to `teclaFinal` (as `F<n>` or `<n>` depending on the global `usarPrefixoF` setting) → optional Full Defense key. All waits go through `EsperarInterrompivel(ms)`, which polls `_ComboPodeContinuar()` (checks the `interromperCombo` flag and `JogoAtivo()`) every ~10ms using a deadline computed from `A_TickCount` — plain `Sleep` accumulation was found to drift under Windows' ~15.6ms timer granularity.
- `revive.ahk`'s `_EnviarSequenciaRevive` runs in `Critical` mode so another hotkey thread can't interleave key-up/down events mid-sequence; `_reviveOcupado` is a re-entrancy lock shared between `revive` and `comboRevive` (both ultimately call this same function). Behavior branches on the global `modoLegado` setting (right-click targeting vs. `Ctrl+1` slot select).
- `cooldown.ahk` walks Pokémon slots from `pokemonInicial` down to 1, clicking a configured screen position and sending `Ctrl+<mapped key>` per slot (the mapped key lets slot order differ from team order), waiting a per-slot configured number of seconds between each. Auto re-focuses the game window mid-wait if it lost focus, and bails out if the game process disappears entirely.
- All macro key/hotkey capture and conflict checking goes through `lib/input.ahk` + `ConflitoDeTecla`/`HotkeySlotExiste` in `macros/hotkeys.ahk` — don't hand-roll new `Hotkey()` registrations elsewhere.

### Established conventions (do not deviate without reason)

- No per-profile indirection — profiles were deliberately removed; all config sections are plain names.
- Config screens never use native `MsgBox`/Gui dialogs for confirmation — use the in-window GDI+ overlay (`_GCfg_Confirmar`).
- To retarget the whole app at a different game, the only required edit is `JanelaAtiva()`/`JogoAtivo()`'s `WinActive("ahk_exe pxgme.exe")` check.
