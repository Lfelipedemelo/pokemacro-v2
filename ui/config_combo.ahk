; =====================================================
; ui\config_combo.ahk — Config de Combo (tema Pokémon)
; =====================================================

AbrirConfigCombo(tipo) {
    global cfgAberta
    global txtTeclaInicial, txtTeclaFinal, txtHotkeyCombo, txtToggleCombo

    if (cfgAberta)
        return
    cfgAberta := true

    ; W  = largura do conteúdo (sem bordas)
    ; A janela é criada sem bordas (-Border) então W = área cliente exata
    IW  := 260   ; largura interna dos campos/botões
    pad := 14    ; margem lateral
    W   := IW + pad * 2   ; largura total da janela = 288

    cfg := GetCfg(tipo)

    cfgGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    cfgGui.BackColor := T()["BG"]
    cfgGui.MarginX   := 0
    cfgGui.MarginY   := 0
    cfgGui.OnEvent("Escape", (*) => _FecharConfigCombo(cfgGui))
    cfgGui.OnEvent("Close",  (*) => (cfgAberta := false))
    OnMessage(0x201, DragJanela)

    _CabecalhoConfig(cfgGui, W, IW, pad, "CONFIG: " StrUpper(tipo), T()["STRIPE3"],
        (*) => ResetarConfiguracoes(tipo),
        (*) => _FecharConfigCombo(cfgGui))

    y := 46

    ; ── Campos ─────────────────────────────────────────
    txtTeclaInicial := _CampoConfig(cfgGui, pad, y, IW, "BOTÃO INICIAL", "[ " cfg["teclaInicial"] " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR BOTÃO INICIAL",
        (*) => CapturarTecla(tipo, "teclaInicial", txtTeclaInicial, "BOTÃO INICIAL"))

    y += 36 , _Sep(cfgGui, y, W) , y += 10

    txtTeclaFinal := _CampoConfig(cfgGui, pad, y, IW, "BOTÃO FINAL", "[ " cfg["teclaFinal"] " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR BOTÃO FINAL",
        (*) => CapturarTecla(tipo, "teclaFinal", txtTeclaFinal, "BOTÃO FINAL"))

    y += 36 , _Sep(cfgGui, y, W) , y += 10

    txtHotkeyCombo := _CampoConfig(cfgGui, pad, y, IW, "TECLA DO MACRO", "[ " StrUpper(cfg["teclaHotkey"]) " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR TECLA MACRO",
        (*) => CapturarTecla(tipo, "teclaHotkey", txtHotkeyCombo, "TECLA MACRO"))

    y += 36 , _Sep(cfgGui, y, W) , y += 10

    ; ── Full Attack / Defense — ativação por combo ──────
    ; As teclas são globais (config geral). Aqui só se ativa/desativa por combo.
    faGlobal := cfg["fullAttack"]
    fdGlobal := cfg["fullDefense"]

    lbFA := cfgGui.AddText("x" pad " y" y " w" IW " c" T()["MUTED"], "FULL ATTACK (TECLA GLOBAL: [ " StrUpper(faGlobal) " ])")
    lbFA.SetFont(GF() " Bold")
    y += 22

    ; Checkbox ativo/inativo lado a lado
    halfW  := (IW - 8) // 2
    usaAtk := cfg["usarFullAtk"] = "true"
    usaDef := cfg["usarFullDef"] = "true"

    ; Radios Full Attack — consecutivos
    rAtkSim := cfgGui.AddRadio("x" pad              " y" y " w16 h18 Group" (usaAtk ? " Checked" : ""))
    rAtkNao := cfgGui.AddRadio("x" (pad+130)        " y" y " w16 h18"       (!usaAtk ? " Checked" : ""))
    lAtkSim := cfgGui.AddText("x" (pad+20)   " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"], "ATIVAR")
    lAtkSim.SetFont(GF())
    lAtkNao := cfgGui.AddText("x" (pad+150)  " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"], "DESATIVAR")
    lAtkNao.SetFont(GF())
    rAtkSim.OnEvent("Click", (*) => SalvarCfg(tipo, "usarFullAtk", "true"))
    rAtkNao.OnEvent("Click", (*) => SalvarCfg(tipo, "usarFullAtk", "false"))

    y += 28 , _Sep(cfgGui, y, W) , y += 10

    lbFD := cfgGui.AddText("x" pad " y" y " w" IW " c" T()["MUTED"], "FULL DEFENSE (TECLA GLOBAL: [ " StrUpper(fdGlobal) " ])")
    lbFD.SetFont(GF() " Bold")
    y += 22

    ; Radios Full Defense — consecutivos
    rDefSim := cfgGui.AddRadio("x" pad              " y" y " w16 h18 Group" (usaDef ? " Checked" : ""))
    rDefNao := cfgGui.AddRadio("x" (pad+130)        " y" y " w16 h18"       (!usaDef ? " Checked" : ""))
    lDefSim := cfgGui.AddText("x" (pad+20)   " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"], "ATIVAR")
    lDefSim.SetFont(GF())
    lDefNao := cfgGui.AddText("x" (pad+150)  " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"], "DESATIVAR")
    lDefNao.SetFont(GF())
    rDefSim.OnEvent("Click", (*) => SalvarCfg(tipo, "usarFullDef", "true"))
    rDefNao.OnEvent("Click", (*) => SalvarCfg(tipo, "usarFullDef", "false"))

    y += 36 , _SepDest(cfgGui, y, W) , y += 10

    y := CriarRadioShowMini(cfgGui, pad, y, IW, tipo)

    _Sep(cfgGui, y, W) , y += 10

    txtToggleCombo := _CampoConfig(cfgGui, pad, y, IW, "HOTKEY LIGAR/DESLIGAR",
        "[ " _ComboDisplay(cfg["toggleHotkey"]) " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR HOTKEY TOGGLE",
        (*) => CapturarCombo(tipo, "toggleHotkey", txtToggleCombo, "HOTKEY TOGGLE"))

    y += 38
    ; Sentinela: garante que AutoSize inclui espaço abaixo do último botão
    cfgGui.AddText("x0 y" y " w" W " h12 Background" T()["BG"])
    cfgGui.Show("w" W " Center")
}

_FecharConfigCombo(cfgGui) {
    global cfgAberta
    cfgAberta := false
    AtualizarHotkeyCombo()
    cfgGui.Destroy()
}

ResetarConfiguracoes(tipo) {
    _CriarGuiConfirmacao(
        "RESETAR " StrUpper(tipo) "?",
        "Esta ação não pode ser desfeita.",
        (g, *) => (ResetarSecao(tipo), _LimparCamposCombo(), g.Destroy(), ShowHint("RESETADO!", 1000)),
        (g, *) => g.Destroy()
    )
}

_LimparCamposCombo() {
    global txtTeclaInicial, txtTeclaFinal, txtHotkeyCombo, txtToggleCombo
    try {
        txtTeclaInicial.Value := "[ N/A ]"
        txtTeclaFinal.Value   := "[ N/A ]"
        txtHotkeyCombo.Value  := "[ N/A ]"
        txtToggleCombo.Value  := "[ N/A ]"
    }
}

; ── Helpers compartilhados de layout ────────────────
; (definidos aqui, usados por todos os módulos de config)

_CabecalhoConfig(g, W, IW, pad, titulo, corFaixa, cbReset, cbFechar) {
    btnSz  := 22
    titleH := 36

    ; Fundo do cabeçalho
    g.AddText("x0 y0 w" W " h" titleH " Background" T()["BG2"])

    ; Linha colorida no topo (fina, elegante)
    g.AddText("x0 y0 w" W " h2 Background" corFaixa)

    ; Título
    lblTitulo := g.AddText(
        "x" pad " y0 w" (W - pad - (btnSz+4)*2 - pad) " h" titleH
        " c" T()["TEXT"] " Background" T()["BG2"] " +0x200",
        titulo)
    lblTitulo.SetFont(GF() " Bold")

    ; Botão R
    bR := g.AddText(
        "x" (W - (btnSz+4)*2) " y" ((titleH-btnSz)//2) " w" btnSz " h" btnSz
        " Center Background0x3d1f1f c0xE05252 +0x200", "↺")
    bR.SetFont(GF() " Bold")
    bR.OnEvent("Click", cbReset)

    ; Botão X
    bX := g.AddText(
        "x" (W - btnSz - 4) " y" ((titleH-btnSz)//2) " w" btnSz " h" btnSz
        " Center Background" T()["BG2"] " c" T()["MUTED"] " +0x200", "×")
    bX.SetFont(GF() " Bold")
    bX.OnEvent("Click", cbFechar)

    ; Separador
    g.AddText("x0 y" titleH " w" W " h1 Background" T()["SEP"])
}

_CampoConfig(g, x, y, w, label, valor) {
    lbl := g.AddText("x" x " y" y " w" w " c" T()["MUTED"], label)
    lbl.SetFont(GF() " Bold")
    val := g.AddText("x" x " y" (y+20) " w" w " h22 Center c" T()["TEXT"] " Background" T()["BG2"] " Border", valor)
    val.SetFont(GF() " Bold")
    return val
}

_BtnConfig(g, x, y, w, texto, callback) {
    btn := g.AddText("x" x " y" y " w" w " h30 Background" T()["BG2"] " Border Center +0x200 c" T()["ACCENT"],
        "▶ " texto)
    btn.SetFont(GF() " Bold")
    btn.OnEvent("Click", callback)
    return btn
}

_Sep(g, y, W) {
    g.AddText("x0 y" y " w" W " h1 Background" T()["SEP"])
}

_SepDest(g, y, W) {
    g.AddText("x0 y" y " w" W " h1 Background" T()["ACCENT2"])
}

_CriarGuiConfirmacao(titulo, subtitulo, cbSim, cbNao) {
    g := Gui("-Caption +ToolWindow +AlwaysOnTop")
    g.BackColor := T()["BG"]
    g.MarginX   := 0
    g.MarginY   := 0

    g.AddText("x0 y0 w320 h8 Background" T()["DANGER"])
    lblTitulo := g.AddText("x10 y16 w300 h28 Center c" T()["ACCENT"] " +0x200", titulo)
    lblTitulo.SetFont(GF() " Bold")
    lblSub := g.AddText("x10 y50 w300 h20 Center c" T()["MUTED"] " +0x200", subtitulo)
    lblSub.SetFont(GF())
    g.AddText("x0 y76 w320 h1 Background" T()["SEP"])

    bS := g.AddText("x15 y86 w135 h32 Center Background0x550000 Border c" T()["ACCENT"] " +0x200", "▶ SIM, RESETAR")
    bS.SetFont(GF() " Bold")
    bS.OnEvent("Click", (ctrl, *) => cbSim(g))

    bN := g.AddText("x170 y86 w135 h32 Center Background" T()["BG2"] " Border c" T()["MUTED"] " +0x200", "✖ NÃO")
    bN.SetFont(GF() " Bold")
    bN.OnEvent("Click", (ctrl, *) => cbNao(g))

    g.Show("w320 Center")
    return g
}
