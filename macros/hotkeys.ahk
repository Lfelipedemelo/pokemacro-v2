; =====================================================
; macros\hotkeys.ahk — Registro de hotkeys e dispatch
; =====================================================

global _macroExecutando := false

_MontarChaveHk(tecla) {
    if (tecla = "N/A" || tecla = "")
        return ""
    prefixo := (tecla ~= "i)Button") ? "$*" : "$"
    return prefixo . tecla
}

AtualizarHotkeyCombo() {
    global macros, _macroExecutando
    static hotkeysRegistradas := Map()

    for hk, _ in hotkeysRegistradas {
        try Hotkey(hk, "Off")
        try Hotkey(hk, "Delete")
    }
    hotkeysRegistradas.Clear()

    JanelaAtiva()   => WinActive("ahk_exe pxgme.exe")
    PodeExecutar()  => JanelaAtiva() && !_macroExecutando

    ; ── Registra hotkey de execução (requer janela ativa e macro ligado) ──
    ; interrompivel=true: ignora _macroExecutando (permite interromper combo)
    RegistrarExecucao(chave, nomeMacro, interrompivel := false) {
        if (chave = "")
            return
        try {
            if (interrompivel)
                HotIf(((n, *) => JanelaAtiva() && macros[n]).Bind(nomeMacro))
            else
                HotIf(((n, *) => PodeExecutar() && macros[n]).Bind(nomeMacro))
            Hotkey(chave, ProcessarPressionamento, "On")
            hotkeysRegistradas[chave] := true
        }
    }

    ; ── Registra hotkey de toggle (restrita à janela do jogo) ──
    RegistrarToggle(chave, nomeMacro) {
        if (chave = "")
            return
        try {
            HotIf((*) => JanelaAtiva())
            Hotkey(chave, ((n, *) => ToggleMacroPorHotkey(n)).Bind(nomeMacro), "On")
            hotkeysRegistradas[chave] := true
        }
    }

    ; ── Combos Principal e Secundário ──
    for tipo in ["comboPrincipal", "comboSecundario"] {
        cfg := GetCfg(tipo)
        RegistrarExecucao(_MontarChaveHk(cfg["teclaHotkey"]),  tipo)
        RegistrarToggle(  _MontarChaveHk(cfg["toggleHotkey"]), tipo)
    }

    ; ── Revive ── (interrompível: funciona mesmo durante combo)
    cfgR := GetCfg("Revive")
    RegistrarExecucao(_MontarChaveHk(cfgR["teclaHotkey"]),        "revive", true)
    RegistrarToggle(  _MontarChaveHk(cfgR["toggleHotkeyRevive"]), "revive")

    ; ── Combo Revive ── (interrompível: funciona mesmo durante combo)
    cfgCR := GetCfg("comboRevive")
    RegistrarExecucao(_MontarChaveHk(cfgCR["teclaHotkey"]),  "comboRevive", true)
    RegistrarToggle(  _MontarChaveHk(cfgCR["toggleHotkey"]), "comboRevive")

    ; ── Cooldown ── (interrompível: a mesma hotkey cancela durante execução)
    cfgC := GetCfg("Cooldown")
    RegistrarExecucao(_MontarChaveHk(cfgC["hotkeyCooldown"]),       "cooldown", true)
    RegistrarToggle(  _MontarChaveHk(cfgC["toggleHotkeyCooldown"]), "cooldown")

    HotIf()
}

; ─── Toggle via hotkey ────────────────────────────────────
ToggleMacroPorHotkey(nome) {
    global macros, uiRefs

    macros[nome] := !macros[nome]

    ; Exclusividade entre os três combos
    if (macros[nome] && (nome = "comboPrincipal" || nome = "comboSecundario" || nome = "comboRevive")) {
        for outro in ["comboPrincipal", "comboSecundario", "comboRevive"] {
            if (outro != nome && macros[outro]) {
                macros[outro] := false
                if (uiRefs.Has(outro))
                    AtualizarVisual(uiRefs[outro], false)
            }
        }
    }

    if (uiRefs.Has(nome)) {
        try AtualizarVisual(uiRefs[nome], macros[nome])
    }

    ShowHint(StrUpper(nome) ": " (macros[nome] ? "LIGADO" : "DESLIGADO"), 1200)
    AtualizarHotkeyCombo()
}

; ─── Despachante central ─────────────────────────────────
ProcessarPressionamento(thisHotkey) {
    global macros, executandoCooldown, _macroExecutando

    ; Remove prefixos para obter a tecla pura
    teclaPura := thisHotkey
    for p in ["$", "~", "*"]
        teclaPura := StrReplace(teclaPura, p, "")

    ; Identifica qual macro esta tecla deve disparar
    ehRevive      := macros["revive"]     && GetCfg("Revive")["teclaHotkey"]         = teclaPura
    ehComboRevive := macros["comboRevive"] && GetCfg("comboRevive")["teclaHotkey"]   = teclaPura
    ehCooldown    := macros["cooldown"]   && GetCfg("Cooldown")["hotkeyCooldown"]    = teclaPura

    ; Revive, ComboRevive e Cooldown (cancelamento) não são bloqueados pela flag
    ehInterrompivel := ehRevive || ehComboRevive || ehCooldown

    if (!ehInterrompivel) {
        if (_macroExecutando)
            return
    }

    if (!ehInterrompivel)
        _macroExecutando := true

    if      (macros["comboPrincipal"]  && GetCfg("comboPrincipal")["teclaHotkey"]  = teclaPura)
        ExecutarCombo("comboPrincipal")
    else if (macros["comboSecundario"] && GetCfg("comboSecundario")["teclaHotkey"] = teclaPura)
        ExecutarCombo("comboSecundario")
    else if (ehComboRevive)
        ExecutarComboRevive()
    else if (ehRevive)
        ExecutarRevive()
    else if (ehCooldown) {
        if (executandoCooldown) {
            executandoCooldown := false
            ShowHint("CANCELADO", 1000)
        } else {
            ExecutarMacroCooldown()
        }
    }

    if (!ehInterrompivel)
        _macroExecutando := false
}
