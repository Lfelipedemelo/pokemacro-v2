; =====================================================
; ui\mini_menu.ahk — Mini menu flutuante de toggles
; =====================================================

global miniGui := 0

_MiniMacroList() {
    return [
        Map("nome", "comboPrincipal",  "label", "C1", "secao", "comboPrincipal"),
        Map("nome", "comboSecundario", "label", "C2", "secao", "comboSecundario"),
        Map("nome", "comboRevive",     "label", "CR", "secao", "comboRevive"),
        Map("nome", "revive",          "label", "R",  "secao", "Revive"),
        Map("nome", "cooldown",        "label", "CD", "secao", "Cooldown"),
    ]
}

_MiniMacroListVisivel() {
    visiveis := []
    for m in _MiniMacroList()
        if GetShowInMini(m["secao"])
            visiveis.Push(m)
    return visiveis
}

GetMiniOrientacao() {
    global configFile
    return IniRead(configFile, "MiniMenu", "orientacao", "horizontal")
}

AbrirMiniMenu() {
    global miniGui
    if (miniGui) {
        SalvarPosMini()
        SetTimer(_MiniVisibilidade, 0)
        miniGui.Destroy()
        miniGui := 0
        return
    }
    _ConstruirMiniMenu()
}

_ConstruirMiniMenu() {
    global miniGui

    miniGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    miniGui.BackColor := "0x121315"
    miniGui.MarginX   := 0
    miniGui.MarginY   := 0
    miniGui.OnEvent("Close", (*) => (miniGui := 0))
    OnMessage(0x201, _MiniDragHandler)

    horizontal := (GetMiniOrientacao() = "horizontal")
    macroList  := _MiniMacroListVisivel()
    nMacros    := macroList.Length

    btnSz   := 32
    gap     := 4
    padE    := 6
    oriSz   := 22
    closeSz := 18

    if (horizontal) {
        W := padE + nMacros*(btnSz+gap) + gap + oriSz + gap + closeSz + padE
        H := padE*2 + btnSz

        miniGui.AddText("x0 y0 w" W " h" H " Background0x121315")
        miniGui.AddText("x0 y0 w" W " h2 Background" T()["STRIPE1"])

        cx := padE
        cy := padE

        for m in macroList {
            _CriarBtnMini(miniGui, cx, cy, btnSz, btnSz, m["nome"], m["label"])
            cx += btnSz + gap
        }

        miniGui.AddText("x" cx " y" cy " w1 h" btnSz " Background0x333336")
        cx += gap + 1

        bOri := miniGui.AddText(
            "x" cx " y" cy " w" oriSz " h" btnSz
            " Center Background0x2a2a2d c" T()["TEXT"] " +0x200", "⇄")
        bOri.SetFont("s9 Bold")
        bOri.OnEvent("Click", (*) => _AlternarOrientacao())
        cx += oriSz + gap

        bX := miniGui.AddText(
            "x" cx " y" (cy+(btnSz-closeSz)//2) " w" closeSz " h" closeSz
            " Center Background0x121315 c0x72767d +0x200", "×")
        bX.SetFont("s11 Bold")
        bX.OnEvent("Click", (*) => (SalvarPosMini(), miniGui.Destroy(), miniGui := 0))

    } else {
        W := padE*2 + btnSz
        H := padE + nMacros*(btnSz+gap) + gap + oriSz + gap + closeSz + padE

        miniGui.AddText("x0 y0 w" W " h" H " Background0x121315")
        miniGui.AddText("x0 y0 w2 h" H " Background" T()["STRIPE1"])

        cx := padE
        cy := padE

        for m in macroList {
            _CriarBtnMini(miniGui, cx, cy, btnSz, btnSz, m["nome"], m["label"])
            cy += btnSz + gap
        }

        miniGui.AddText("x" cx " y" cy " w" btnSz " h1 Background0x333336")
        cy += gap + 1

        bOri := miniGui.AddText(
            "x" cx " y" cy " w" btnSz " h" oriSz
            " Center Background0x2a2a2d c" T()["TEXT"] " +0x200", "⇄")
        bOri.SetFont("s9 Bold")
        bOri.OnEvent("Click", (*) => _AlternarOrientacao())
        cy += oriSz + gap

        bX := miniGui.AddText(
            "x" (cx+(btnSz-closeSz)//2) " y" cy " w" closeSz " h" closeSz
            " Center Background0x121315 c0x72767d +0x200", "×")
        bX.SetFont("s11 Bold")
        bX.OnEvent("Click", (*) => (SalvarPosMini(), miniGui.Destroy(), miniGui := 0))
    }

    posStr := _CarregarPosMini()
    miniGui.Show("w" W " h" H " " posStr)

    ; Timer leve (100ms) para ocultar/mostrar conforme foco do jogo
    SetTimer(_MiniVisibilidade, 100)
}

_CriarBtnMini(gui, x, y, w, h, nome, label) {
    ativo := macros[nome]
    bg    := ativo ? "0x1E3A5F" : "0x282a2d"
    fg    := ativo ? "0xFFFFFF" : "0x72767d"

    btn := gui.AddText(
        "x" x " y" y " w" w " h" h
        " Center Background" bg " c" fg " +0x200",
        label)
    btn.SetFont("s8 Bold")
    btn.OnEvent("Click", ((n, *) => _MiniToggle(n)).Bind(nome))
    return btn
}

_MiniToggle(nome) {
    global macros, uiRefs

    macros[nome] := !macros[nome]

    if (macros[nome] && (nome = "comboPrincipal" || nome = "comboSecundario" || nome = "comboRevive")) {
        for outro in ["comboPrincipal", "comboSecundario", "comboRevive"] {
            if (outro != nome && macros[outro]) {
                macros[outro] := false
                if uiRefs.Has(outro)
                    try AtualizarVisual(uiRefs[outro], false)
            }
        }
    }

    if uiRefs.Has(nome)
        try AtualizarVisual(uiRefs[nome], macros[nome])

    AtualizarHotkeyCombo()

    SalvarPosMini()
    _RecriarMini()
}

_AlternarOrientacao() {
    global configFile
    nova := (GetMiniOrientacao() = "horizontal") ? "vertical" : "horizontal"
    IniWrite(nova, configFile, "MiniMenu", "orientacao")
    SalvarPosMini()
    _RecriarMini()
}

_RecriarMini() {
    global miniGui
    SetTimer(_MiniVisibilidade, 0)
    if miniGui {
        miniGui.Destroy()
        miniGui := 0
    }
    _ConstruirMiniMenu()
}

_MiniDragHandler(wParam, lParam, msg, hwnd) {
    global miniGui
    if (miniGui && hwnd = miniGui.Hwnd)
        PostMessage(0xA1, 2,,, "ahk_id " miniGui.Hwnd)
}

; Oculta o mini menu quando o jogo não está em foco (sem overhead)
_MiniVisibilidade() {
    global miniGui
    if !miniGui {
        SetTimer(_MiniVisibilidade, 0)
        return
    }
    try {
        ; Mantém visível se o jogo OU as janelas do próprio macro estão em foco
        hwndAtivo := WinGetID("A")
        exeAtivo  := WinGetProcessName("ahk_id " hwndAtivo)
        visivel   := (exeAtivo = "pxgme.exe" || exeAtivo = "AutoHotkey64.exe" || exeAtivo = "AutoHotkey.exe")

        if visivel
            WinShow("ahk_id " miniGui.Hwnd)
        else
            WinHide("ahk_id " miniGui.Hwnd)
    }
}

SalvarPosMini() {
    global miniGui, configFile
    if !miniGui
        return
    try {
        WinGetPos(&x, &y,,, "ahk_id " miniGui.Hwnd)
        IniWrite(x, configFile, "MiniMenu", "posX")
        IniWrite(y, configFile, "MiniMenu", "posY")
    }
}

_CarregarPosMini() {
    global configFile
    x := IniRead(configFile, "MiniMenu", "posX", "")
    y := IniRead(configFile, "MiniMenu", "posY", "")
    return (x != "" && y != "") ? "x" x " y" y : "Center"
}
