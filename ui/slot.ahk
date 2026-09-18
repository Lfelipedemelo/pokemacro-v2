; =====================================================
; ui\slot.ahk — Card system modernista dark
; =====================================================
;
; Estado ATIVO:
;   - Fundo do card: azul escuro  0x1E3A5F
;   - Borda visível:  azul médio  0x2D6AB8  (4 linhas de 2px)
;   - Badge, nome, hotkey: branco brilhante
;   - Status: verde neon pulsante
;   - Ícone: painel de fundo azul escuro (sincronizado)
;
; Estado INATIVO:
;   - Fundo: T()["BG2"]  (~0x282a2d)
;   - Sem borda extra
;   - Textos em MUTED

global _indicadorTimer    := 0
global _indicadorState    := false
global _indicadoresAtivos := Map()

; ── Paleta fixa de estados (independente do tema) ────
_CardAtivoBG()     => "0x1E3A5F"   ; azul escuro
_CardAtivoBORDA()  => "0x2D6AB8"   ; azul médio (borda)
_CardAtivoTEXT()   => "0xFFFFFF"   ; branco brilhante
_CardAtivoBADGE()  => "0x0D2440"   ; badge escuro sobre azul
_CardAtivoGREEN()  => "0x57F287"   ; verde neon
_CardAtivoGREEN2() => "0x2d4a35"   ; verde apagado (pulso)

; ─── ANIMAÇÃO PULSANTE ───────────────────────────────
_PulsarIndicadores() {
    global _indicadorState, _indicadoresAtivos
    _indicadorState := !_indicadorState
    cor := _indicadorState ? _CardAtivoGREEN() : _CardAtivoGREEN2()
    for nome, ctrl in _indicadoresAtivos
        try ctrl.Opt("Background" cor)
}

_IniciarAnimacao() {
    global _indicadorTimer
    if (!_indicadorTimer) {
        _indicadorTimer := 1
        SetTimer(_PulsarIndicadores, 550)
    }
}

_PararAnimacao() {
    global _indicadorTimer, _indicadoresAtivos
    if (_indicadoresAtivos.Count = 0) {
        SetTimer(_PulsarIndicadores, 0)
        _indicadorTimer := 0
    }
}

AtualizarVisual(ctrl, ativo) {
    global _indicadoresAtivos

    if !ctrl
        return

    try {
        if (ativo) {
            bg      := _CardAtivoBG()
            borda   := _CardAtivoBORDA()
            fg      := _CardAtivoTEXT()
            fgSt    := _CardAtivoGREEN()
            bgBadge := _CardAtivoBADGE()
            stTxt   := "● ATIVO"
        } else {
            bg      := T()["BG2"]
            borda   := T()["BG2"]
            fg      := T()["MUTED"]
            fgSt    := T()["MUTED"]
            bgBadge := "0x1e2124"
            stTxt   := "○ INATIVO"
        }

        try ctrl.slot.Opt("Background" bg)

        if ctrl.HasProp("bordas")
            for b in ctrl.bordas
                try b.Opt("Background" borda)

        if ctrl.HasProp("icoBG")
            try ctrl.icoBG.Opt("Background" bg)

        try ctrl.nome_ctrl.Opt("c" fg " Background" bg)
        try ctrl.hk_ctrl.Opt("c" fg " Background" bg)
        try ctrl.badge.Opt("c" fg " Background" bgBadge)

        try {
            if ctrl.HasProp("status_ctrl") {
                ctrl.status_ctrl.Opt("c" fgSt " Background" bg)
                if ctrl.HasProp("nome_ctrl") &&
                    ctrl.status_ctrl.Hwnd != ctrl.nome_ctrl.Hwnd
                    ctrl.status_ctrl.Value := stTxt
            }
        }

        ; Dot pulsante
        if (ativo) {
            try ctrl.dot.Opt("Background" _CardAtivoGREEN())
            if ctrl.HasProp("macroNome") {
                _indicadoresAtivos[ctrl.macroNome] := ctrl.dot
                _IniciarAnimacao()
            }
        } else {
            try ctrl.dot.Opt("Background" T()["MUTED"])
            if ctrl.HasProp("macroNome") && _indicadoresAtivos.Has(ctrl.macroNome) {
                _indicadoresAtivos.Delete(ctrl.macroNome)
                _PararAnimacao()
            }
        }

        ; Força repaint via WM_SETREDRAW na janela pai
        if ctrl.HasProp("slot") {
            try {
                parentHwnd := DllCall("GetParent", "Ptr", ctrl.slot.Hwnd, "Ptr")
                DllCall("SendMessage", "Ptr", parentHwnd, "UInt", 0x000B, "Ptr", 0, "Ptr", 0)
                DllCall("SendMessage", "Ptr", parentHwnd, "UInt", 0x000B, "Ptr", 1, "Ptr", 0)
                DllCall("RedrawWindow", "Ptr", parentHwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0085)
            }
        }
    }
}

; ─── TOGGLE ──────────────────────────────────────────
ToggleMacro(nome, controle) {
    global macros, lastClick, uiRefs

    if (A_TickCount - lastClick < 150)
        return
    lastClick := A_TickCount

    macros[nome] := !macros[nome]

    ; Exclusividade entre combos — desativa os outros visualmente também
    if (macros[nome] && (nome = "comboPrincipal" || nome = "comboSecundario" || nome = "comboRevive")) {
        for outro in ["comboPrincipal", "comboSecundario", "comboRevive"] {
            if (outro != nome && macros[outro]) {
                macros[outro] := false
                if uiRefs.Has(outro)
                    try AtualizarVisual(uiRefs[outro], false)
            }
        }
    }

    AtualizarVisual(controle, macros[nome])
    AtualizarHotkeyCombo()

    ; Sincroniza o mini menu se estiver aberto
    if (miniGui)
        _RecriarMini()
}

; ─── HEADER DE GRUPO ─────────────────────────────────
CriarHeaderGrupo(gui, x, y, w, texto) {
    lbl := gui.AddText(
        "x" x " y" y " w" w " h16"
        " c" T()["MUTED"] " Background" T()["BG"] " +0x200",
        texto)
    lbl.SetFont(GF() " Bold")
    return lbl
}

; ─── BOTÃO DE CONFIG (telas de configuração) ─────────
CriarBotaoConfig(gui, x, y, texto, callback) {
    btn := gui.AddText(
        "x" x " y" y " w220 h30 Background" T()["BG2"] " Border Center +0x200 c" T()["ACCENT"],
        "▶ " texto)
    btn.SetFont(GF() " Bold")
    btn.OnEvent("Click", callback)
    return btn
}

; ─── BOTÃO LATERAL (compatibilidade) ─────────────────
CriarBotaoLateral(gui, x, y, texto, callback, cfgW := 52, slotH := 116) {
    btn := gui.AddText(
        "x" x " y" y " w" cfgW " h" slotH
        " Background" T()["BG2"] " Center +0x200 c" T()["MUTED"],
        texto)
    btn.SetFont(GF() " Bold")
    btn.OnEvent("Click", callback)
    return btn
}

