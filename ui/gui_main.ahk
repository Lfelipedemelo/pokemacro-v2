; =====================================================
; ui\gui_main.ahk — Interface principal modernista
; =====================================================

_KeyHint(tipo) {
    cfg := GetCfg(tipo)
    hk  := cfg["teclaHotkey"]
    return (hk != "N/A" && hk != "") ? StrUpper(hk) : ""
}

_KeyHintCooldown() {
    cfg := GetCfg("Cooldown")
    hk  := cfg["hotkeyCooldown"]
    return (hk != "N/A" && hk != "") ? StrUpper(hk) : ""
}

CriarInterface() {
    global myGui, macros, icons, uiRefs, modoCompacto
    global _indicadoresAtivos, _indicadorTimer

    _indicadoresAtivos := Map()
    SetTimer(_PulsarIndicadores, 0)
    _indicadorTimer := 0
    uiRefs := Map()

    myGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    myGui.BackColor := T()["BG"]
    myGui.MarginX   := 0
    myGui.MarginY   := 0

    myGui.OnEvent("Escape", (*) => (SalvarPosicaoJanela(), myGui.Destroy(), myGui := 0))
    myGui.OnEvent("Close",  (*) => (SalvarPosicaoJanela(), myGui := 0))
    OnMessage(0x201, DragJanela)

    ; ── Dimensões ──────────────────────────────────────
    pad    := 10
    cardW  := modoCompacto ? 100 : 130   ; largura de cada card
    cardH  := modoCompacto ? 44  : 160   ; altura — ícone grande
    cfgSz  := 28                          ; tamanho do botão ⚙
    cardGX := 8                           ; gap horizontal entre cards
    cardGY := 4                           ; gap vertical
    hdrH   := 20
    titleH := 36

    ; Grupos
    grupos := [
        Map("header", "COMBOS", "macros", [
            Map("nome", "comboPrincipal",  "label", "PRINCIPAL",    "icon", icons["comboPrincipal"],  "cfg", (*) => AbrirConfigCombo("comboPrincipal")),
            Map("nome", "comboSecundario", "label", "SECUNDÁRIO",   "icon", icons["comboSecundario"], "cfg", (*) => AbrirConfigCombo("comboSecundario")),
        ]),
        Map("header", "SUPORTE", "macros", [
            Map("nome", "revive",      "label", "REVIVER",      "icon", icons["revive"],      "cfg", (*) => AbrirTelaConfigRevive("revive")),
            Map("nome", "comboRevive", "label", "CMB REVIVE",   "icon", icons["comboRevive"], "cfg", (*) => AbrirConfigComboRevive()),
        ]),
        Map("header", "COOLDOWN", "macros", [
            Map("nome", "cooldown", "label", "COOLDOWN", "icon", icons["cooldown"], "cfg", (*) => AbrirConfigCooldown()),
        ]),
    ]

    ; Largura baseada no grupo com mais cards
    maxCards := 0
    for g in grupos
        maxCards := Max(maxCards, g["macros"].Length)

    innerW := maxCards * cardW + (maxCards - 1) * cardGX
    W      := pad * 2 + innerW

    ; ── Faixa de título ───────────────────────────────
    myGui.AddText("x0 y0 w" W " h" titleH " Background" T()["BG"])
    myGui.AddText("x0 y0 w" W " h2 Background" T()["STRIPE1"])

    btnSz := 22
    btnY  := (titleH - btnSz) // 2

    titulo := myGui.AddText(
        "x" pad " y0 w" (W - pad - (btnSz+4)*4) " h" titleH
        " c" T()["TEXT"] " Background" T()["BG"] " +0x200",
        "POKÉMACRO")
    titulo.SetFont(GF() " Bold")

    bx := W - (btnSz+4)*4

    btnMini := myGui.AddText(
        "x" bx " y" btnY " w" btnSz " h" btnSz
        " Center Background" T()["BG2"] " c" T()["MUTED"] " +0x200", "◉")
    btnMini.SetFont(GF())
    btnMini.OnEvent("Click", (*) => AbrirMiniMenu())
    bx += btnSz + 4

    btnCompact := myGui.AddText(
        "x" bx " y" btnY " w" btnSz " h" btnSz
        " Center Background" T()["BG2"] " c" T()["MUTED"] " +0x200",
        modoCompacto ? "↓" : "↑")
    btnCompact.SetFont(GF())
    btnCompact.OnEvent("Click", (*) => _ToggleCompacto())
    bx += btnSz + 4

    btnGear := myGui.AddText(
        "x" bx " y" btnY " w" btnSz " h" btnSz
        " Center Background" T()["BG2"] " c" T()["MUTED"] " +0x200", "⚙")
    btnGear.SetFont(GF())
    btnGear.OnEvent("Click", (*) => AbrirConfigGeral())
    bx += btnSz + 4

    btnClose := myGui.AddText(
        "x" bx " y" btnY " w" btnSz " h" btnSz
        " Center Background0x3d1f1f c0xE05252 +0x200", "×")
    btnClose.SetFont(GF() " Bold")
    btnClose.OnEvent("Click", (*) => (SalvarPosicaoJanela(), myGui.Destroy(), myGui := 0))

    myGui.AddText("x0 y" titleH " w" W " h1 Background" T()["SEP"])
    y := titleH + 8

    ; ── Grupos ─────────────────────────────────────────
    for g in grupos {
        nCards := g["macros"].Length

        ; Header
        myGui.AddText("x" pad " y" y " w" innerW " h1 Background" T()["SEP"])
        y += 5
        hdr := myGui.AddText(
            "x" pad " y" y " w" innerW " h" hdrH
            " c" T()["MUTED"] " Background" T()["BG"] " +0x200",
            "  " g["header"])
        hdr.SetFont(GF() " Bold")
        y += hdrH + 4

        ; Cards
        cx := pad
        for m in g["macros"] {
            nome    := m["nome"]
            keyHint := (nome = "cooldown") ? _KeyHintCooldown() : _KeyHint(nome)

            uiRefs[nome] := CriarCard(
                myGui, cx, y,
                nome, m["label"], m["icon"],
                keyHint,
                ((n, ctrl, *) => ToggleMacro(n, uiRefs[n])).Bind(nome),
                macros[nome],
                cardW, cardH)

            ; ⚙ abaixo do card — separado, sem interferir no clique do card
            CriarBotaoCfgCard(myGui, cx, y, cardW, cardH, m["cfg"])

            cx += cardW + cardGX
        }

        y += cardH + cfgSz + 8 + cardGY
    }

    ; Separador + rodapé
    myGui.AddText("x0 y" y " w" W " h1 Background" T()["SEP"])
    y += 6

    if (!modoCompacto) {
        rodape := myGui.AddText(
            "x0 y" y " w" W " h20 Center c" T()["MUTED"] " Background" T()["BG"] " +0x200",
            "CTRL+F12  FECHAR")
        rodape.SetFont(GF())
        y += 20
    }

    pos := CarregarPosicaoJanela()
    myGui.Show("w" W " " pos)
}

_ToggleCompacto() {
    global modoCompacto, myGui
    SalvarPosicaoJanela()
    modoCompacto := !modoCompacto
    if (myGui) {
        myGui.Destroy()
        myGui := 0
    }
    CriarInterface()
}
