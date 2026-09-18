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

; ─── CARD MODERNISTA ─────────────────────────────────
;
;  ╔══════════════════╗  ← borda 2px (azul quando ativo)
;  ║  [  ÍCONE  ]     ║  ← grande, centralizado
;  ║   NOME MACRO     ║  ← bold branco
;  ║  [ BADGE KEY ]   ║  ← tecla estilizada
;  ║  ● ATIVO / ○     ║  ← dot pulsante + texto
;  ╚══════════════════╝
CriarCard(gui, x, y, macroNome, displayNome, icone, keyHint, callback, ativo, cardW, cardH) {
    global modoCompacto

    padH    := 8
    padV    := 6
    borda   := 2     ; espessura da borda simulada
    badgeH  := 18
    badgeW  := Max(44, StrLen(keyHint) * 8 + 14)
    dotSz   := 8
    stH     := 16

    textAreaH := 20 + badgeH + 4 + stH + 6
    icoSz     := Max(32, cardH - textAreaH - padV * 2 - borda * 2)
    icoSz     := Min(cardW - (padH + borda) * 2, icoSz)

    bg0 := T()["BG2"]   ; cor inicial (inativo)

    ; ── 1. Fundo principal do card ───────────────────
    slot := gui.AddText(
        "x" x " y" y " w" cardW " h" cardH
        " Background" bg0)

    ; ── 2. Bordas simuladas (4 linhas de 2px) ────────
    bordas := []
    ; Topo
    b1 := gui.AddText("x" x         " y" y                    " w" cardW " h" borda " Background" bg0)
    ; Base
    b2 := gui.AddText("x" x         " y" (y+cardH-borda)      " w" cardW " h" borda " Background" bg0)
    ; Esquerda
    b3 := gui.AddText("x" x         " y" y                    " w" borda " h" cardH " Background" bg0)
    ; Direita
    b4 := gui.AddText("x" (x+cardW-borda) " y" y              " w" borda " h" cardH " Background" bg0)
    bordas.Push(b1, b2, b3, b4)

    if (modoCompacto) {
        nomCtrl := gui.AddText(
            "x" (x+padH) " y" (y+8) " w" (cardW-padH*2) " h18"
            " c" T()["MUTED"] " Background" bg0 " +0x200",
            displayNome)
        nomCtrl.SetFont(GF() " Bold")

        stCtrl := gui.AddText(
            "x" (x+padH) " y" (y+cardH-20) " w" (cardW-padH*2) " h14"
            " c" T()["MUTED"] " Background" bg0 " +0x200",
            ativo ? "● ATIVO" : "○ INATIVO")
        stCtrl.SetFont(GF())

        dot := gui.AddText("x" x " y" y " w1 h1 Background" bg0)

        slot.slot        := slot
        slot.bordas      := bordas
        slot.icoBG       := slot
        slot.nome_ctrl   := nomCtrl
        slot.hk_ctrl     := nomCtrl
        slot.badge       := nomCtrl
        slot.status_ctrl := stCtrl
        slot.dot         := dot
        slot.macroNome   := macroNome
        slot.parentGui   := gui
        slot._callback   := callback

        AtualizarVisual(slot, ativo)
        slot.OnEvent("Click", callback)
        nomCtrl.OnEvent("Click", callback)
        return slot
    }

    ; ── 3. Painel de fundo do ícone ───────────────────
    ; Controle Text atrás do ícone — muda cor junto com card
    iconX  := x + borda + (cardW - borda*2 - icoSz) // 2
    iconY  := y + borda + padV
    icoBG  := gui.AddText(
        "x" (iconX-2) " y" (iconY-2) " w" (icoSz+4) " h" (icoSz+4)
        " Background" bg0)

    ; ── 4. Ícone ─────────────────────────────────────
    pic := gui.AddPicture("x" iconX " y" iconY " w" icoSz " h" icoSz, icone)

    ; ── 5. Nome ──────────────────────────────────────
    nomY    := iconY + icoSz + 6
    nomCtrl := gui.AddText(
        "x" (x+borda) " y" nomY " w" (cardW-borda*2) " h20"
        " Center c" T()["MUTED"] " Background" bg0 " +0x200",
        displayNome)
    nomCtrl.SetFont(GF() " Bold")

    ; ── 6. Badge de tecla ────────────────────────────
    badgeY := nomY + 22
    badgeX := x + (cardW - badgeW) // 2
    badge  := gui.AddText(
        "x" badgeX " y" badgeY " w" badgeW " h" badgeH
        " Center Background0x1e2124 c" T()["MUTED"] " +0x200",
        keyHint != "" ? keyHint : "—")
    badge.SetFont(GF() " Bold")

    ; ── 7. Status + dot ──────────────────────────────
    stY    := badgeY + badgeH + 4
    dot    := gui.AddText(
        "x" (x + (cardW - dotSz) // 2 - 28) " y" (stY + (stH - dotSz) // 2)
        " w" dotSz " h" dotSz
        " Background" T()["MUTED"])

    stCtrl := gui.AddText(
        "x" (x+borda) " y" stY " w" (cardW-borda*2) " h" stH
        " Center c" T()["MUTED"] " Background" bg0 " +0x200",
        ativo ? "● ATIVO" : "○ INATIVO")
    stCtrl.SetFont(GF())

    ; ── Wiring ────────────────────────────────────────
    pic.slot        := slot
    pic.bordas      := bordas
    pic.icoBG       := icoBG
    pic.nome_ctrl   := nomCtrl
    pic.hk_ctrl     := badge
    pic.badge       := badge
    pic.status_ctrl := stCtrl
    pic.dot         := dot
    pic.macroNome   := macroNome
    pic.parentGui   := gui
    pic._callback   := callback

    AtualizarVisual(pic, ativo)

    ; Apenas pic e slot recebem click (CFG fica fora)
    pic.OnEvent("Click",  callback)
    slot.OnEvent("Click", callback)
    icoBG.OnEvent("Click", callback)

    return pic
}

; ─── RADIO "MOSTRAR NO MINI MENU" (compartilhado) ────
; secao: nome exato da seção do INI ("comboPrincipal", "Revive", "Cooldown" etc.)
CriarRadioShowMini(gui, x, y, w, secao) {
    lbl := gui.AddText("x" x " y" y " w" w " c" T()["MUTED"], "EXIBIR NO MINI MENU:")
    lbl.SetFont(GF() " Bold")
    y += 22

    atual := GetShowInMini(secao)

    rSim := gui.AddRadio("x" x         " y" y " w16 h18 Group" (atual  ? " Checked" : ""))
    rNao := gui.AddRadio("x" (x+130)   " y" y " w16 h18"       (!atual ? " Checked" : ""))
    lSim := gui.AddText("x" (x+20)  " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"], "SIM")
    lSim.SetFont(GF())
    lNao := gui.AddText("x" (x+150) " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"], "NÃO")
    lNao.SetFont(GF())

    rSim.OnEvent("Click", (*) => SalvarCfg(secao, "showInMini", "true"))
    rNao.OnEvent("Click", (*) => SalvarCfg(secao, "showInMini", "false"))

    return y + 28   ; retorna novo y após o bloco
}

; ─── ENGRENAGEM CFG (abaixo do card) ─────────────────
CriarBotaoCfgCard(gui, cardX, cardY, cardW, cardH, callback) {
    sz  := 28
    bx  := cardX + (cardW - sz) // 2
    by  := cardY + cardH + 3
    btn := gui.AddText(
        "x" bx " y" by " w" sz " h" sz
        " Center Background" T()["BG2"] " c" T()["MUTED"] " +0x200",
        "⚙")
    btn.SetFont("s14")
    btn.OnEvent("Click", callback)
    return btn
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

; ─── SLOT LEGACY (compatibilidade) ───────────────────
CriarSlot(gui, x, y, texto, icone, callback, ativo := false, slotW := 110, slotH := 116, keyHint := "") {
    return CriarCard(gui, x, y, texto, texto, icone, keyHint, callback, ativo, slotW, slotH)
}
