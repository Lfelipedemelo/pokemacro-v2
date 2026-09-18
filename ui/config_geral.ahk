; =====================================================
; ui\config_geral.ahk — Configurações Gerais
; =====================================================

global cfgGeralAberta := false

; Tamanho base das fontes (offset aplicado ao tamanho padrão)
GetTamanhoFonte() {
    global configFile
    return Integer(IniRead(configFile, "Geral", "tamanhoFonte", "9"))
}

; Ajusta o tamanho da fonte em +1 ou -1, limita entre 7 e 14
_AjustarFonte(delta, valDisplay) {
    global configFile
    atual := GetTamanhoFonte()
    novo  := Max(7, Min(14, atual + delta))
    IniWrite(novo, configFile, "Geral", "tamanhoFonte")
    valDisplay.Value := "Aa  —  Tamanho " novo
    valDisplay.SetFont("s" novo " Bold", GF())
    _ReaplicarInterface()
}

GetSleepCombo() {
    global configFile
    return Integer(IniRead(configFile, "Geral", "sleepCombo", "92"))
}

GetUsarPrefixoF() {
    global configFile
    return IniRead(configFile, "Geral", "usarPrefixoF", "true")
}

GetModoLegado() {
    global configFile
    return IniRead(configFile, "Geral", "modoLegado", "false")
}

; Fecha e recria a interface principal com o tema/tamanho atual
_ReaplicarInterface() {
    global myGui, cfgGeralAberta
    cfgGeralAberta := false
    if (myGui) {
        SalvarPosicaoJanela()
        myGui.Destroy()
        myGui := 0
    }
    CriarInterface()
}

AbrirConfigGeral() {
    global cfgGeralAberta, configFile

    if (cfgGeralAberta)
        return
    cfgGeralAberta := true

    IW    := 260
    pad   := 14
    W     := IW + pad * 2

    g := Gui("-Caption +ToolWindow +AlwaysOnTop")
    g.BackColor := T()["BG"]
    g.MarginX   := 0
    g.MarginY   := 0
    g.OnEvent("Escape", (*) => (cfgGeralAberta := false, g.Destroy()))
    g.OnEvent("Close",  (*) => (cfgGeralAberta := false))
    OnMessage(0x201, DragJanela)

    ; ── Cabeçalho modernista ──
    btnSz  := 22
    titleH := 36
    g.AddText("x0 y0 w" W " h" titleH " Background" T()["BG2"])
    g.AddText("x0 y0 w" W " h2 Background" T()["ACCENT2"])   ; linha colorida no topo

    lblGeral := g.AddText(
        "x" pad " y0 w" (W - pad - btnSz - 8) " h" titleH
        " c" T()["TEXT"] " Background" T()["BG2"] " +0x200",
        "CONFIGURAÇÕES GERAIS")
    lblGeral.SetFont(GF() " Bold")

    bX := g.AddText(
        "x" (W - btnSz - 4) " y" ((titleH-btnSz)//2) " w" btnSz " h" btnSz
        " Center Background" T()["BG2"] " c" T()["MUTED"] " +0x200", "×")
    bX.SetFont(GF() " Bold")
    bX.OnEvent("Click", (*) => (cfgGeralAberta := false, g.Destroy()))
    g.AddText("x0 y" titleH " w" W " h1 Background" T()["SEP"])
    y := 52

    ; ── 1. Tamanho das Fontes ──
    lbl1 := g.AddText("x" pad " y" y " w" IW " c" T()["MUTED"], "TAMANHO DAS FONTES:")
    lbl1.SetFont(GF() " Bold")
    y += 24

    ; Display do tamanho atual
    tamanhoAtual := GetTamanhoFonte()
    valFonte := g.AddText(
        "x" pad " y" y " w" IW " h28 Center c" T()["TEXT"] " Background" T()["BG2"] " +0x200",
        "Aa  —  Tamanho " tamanhoAtual)
    valFonte.SetFont("s" tamanhoAtual " Bold", GF())
    y += 34

    ; Botões + e -
    btnW3 := (IW - 8) // 3

    btnMenos := g.AddText(
        "x" pad " y" y " w" btnW3 " h30 Center Background" T()["BG2"] " c" T()["TEXT"] " +0x200", "−")
    btnMenos.SetFont(GF() " Bold")
    btnMenos.OnEvent("Click", (*) => _AjustarFonte(-1, valFonte))

    valFonteSz := g.AddText(
        "x" (pad + btnW3 + 4) " y" y " w" (btnW3 - 4) " h30 Center Background" T()["BG2"] " c" T()["MUTED"] " +0x200",
        tamanhoAtual " pt")
    valFonteSz.SetFont(GF())

    btnMais := g.AddText(
        "x" (pad + btnW3*2 + 4) " y" y " w" btnW3 " h30 Center Background" T()["BG2"] " c" T()["TEXT"] " +0x200", "+")
    btnMais.SetFont(GF() " Bold")
    btnMais.OnEvent("Click", (*) => _AjustarFonte(1, valFonte))

    y += 36 , g.AddText("x0 y" y " w" W " h1 Background" T()["SEP"]) , y += 10

    ; ── 2. Tema de Cores ──
    lbl2t := g.AddText("x" pad " y" y " w" IW " c" T()["MUTED"], "TEMA DE CORES:")
    lbl2t.SetFont(GF() " Bold")
    y += 22

    temas    := ["Pokédex Vermelho", "Night Blue", "Gold", "Minimal"]
    temaAtual := GetTema()
    temaIdx  := 1
    for i, n in temas
        if (n = temaAtual)
            temaIdx := i

    ddlTema := g.AddDropDownList("x" pad " y" y " w" IW " Choose" temaIdx, temas)
    ddlTema.SetFont(GF())
    ddlTema.OnEvent("Change", (ctrl, *) => (
        _ts := ctrl.Text,
        IniWrite(_ts, configFile, "Geral", "tema"),
        g.Destroy(),
        _ReaplicarInterface()
    ))

    y += 32 , g.AddText("x0 y" y " w" W " h1 Background" T()["SEP"]) , y += 10

    ; ── 2. Sleep do combo ──
    lbl2 := g.AddText("x" pad " y" y " w" IW " c" T()["MUTED"] "", "DELAY ENTRE TECLAS DO COMBO (MS):")
    lbl2.SetFont(GF() " Bold")
    y += 22

    valSleep := g.AddText("x" pad " y" y " w" IW " h22 Center c" T()["TEXT"] " Background" T()["BG2"] " Border",
        "[ " GetSleepCombo() " MS ]")
    valSleep.SetFont(GF() " Bold")
    y += 28

    editSleep := g.AddEdit("x" pad " y" y " w" IW " h26 Center Number c" T()["TEXT"] " Background" T()["BG2"] " -E0x200",
        GetSleepCombo())
    editSleep.SetFont(GF() " Bold")
    editSleep.OnEvent("Change", (ctrl, *) => (
        IniWrite(ctrl.Value, configFile, "Geral", "sleepCombo"),
        valSleep.Value := "[ " ctrl.Value " MS ]"
    ))

    y += 34 , g.AddText("x0 y" y " w" W " h1 Background" T()["SEP"]) , y += 10

    ; ── 3. Prefixo F ──
    lbl3 := g.AddText("x" pad " y" y " w" IW " c" T()["MUTED"] "", "USAR PREFIXO [F] NAS TECLAS:")
    lbl3.SetFont(GF() " Bold")
    y += 22

    usarF := GetUsarPrefixoF()

    ; Radios consecutivos
    rSim := g.AddRadio("x" pad              " y" y " w16 h18 Group" (usarF = "true"  ? " Checked" : ""))
    rNao := g.AddRadio("x" (pad+130)        " y" y " w16 h18"       (usarF = "false" ? " Checked" : ""))

    ; Labels depois
    lSim := g.AddText("x" (pad+20)          " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"] "", "SIM  (F1..F9)")
    lSim.SetFont(GF())
    lNao := g.AddText("x" (pad+150)         " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"] "", "NÃO  (1..9)")
    lNao.SetFont(GF())

    rSim.OnEvent("Click", (*) => IniWrite("true",  configFile, "Geral", "usarPrefixoF"))
    rNao.OnEvent("Click", (*) => IniWrite("false", configFile, "Geral", "usarPrefixoF"))

    y += 32 , g.AddText("x0 y" y " w" W " h1 Background" T()["SEP"]) , y += 10

    ; ── 4. Modo Legado ──
    lbl4 := g.AddText("x" pad " y" y " w" IW " c" T()["MUTED"] "", "MODO LEGADO (REVIVE):")
    lbl4.SetFont(GF() " Bold")
    y += 16
    desc := g.AddText("x" pad " y" y " w" IW " c" T()["MUTED"] "", "Ativo: clique direito  |  Inativo: Ctrl+1")
    desc.SetFont(GF())
    y += 20

    modoLegado := GetModoLegado()

    rLegSim := g.AddRadio("x" pad       " y" y " w16 h18 Group" (modoLegado = "true"  ? " Checked" : ""))
    rLegNao := g.AddRadio("x" (pad+130) " y" y " w16 h18"       (modoLegado = "false" ? " Checked" : ""))

    lLegSim := g.AddText("x" (pad+20)  " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"] "", "ATIVO")
    lLegSim.SetFont(GF())
    lLegNao := g.AddText("x" (pad+150) " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"] "", "INATIVO")
    lLegNao.SetFont(GF())

    rLegSim.OnEvent("Click", (*) => IniWrite("true",  configFile, "Geral", "modoLegado"))
    rLegNao.OnEvent("Click", (*) => IniWrite("false", configFile, "Geral", "modoLegado"))

    y += 32 , g.AddText("x0 y" y " w" W " h1 Background" T()["SEP"]) , y += 10

    ; ── 5. Full Attack ──
    lbl5 := g.AddText("x" pad " y" y " w" IW " c" T()["MUTED"] "", "TECLA FULL ATTACK (GLOBAL):")
    lbl5.SetFont(GF() " Bold")
    y += 22

    faVal := IniRead(configFile, "Geral", "fullAttack", "N/A")
    txtFullAtkGeral := g.AddText("x" pad " y" y " w" IW " h22 Center c" T()["TEXT"] " Background" T()["BG2"] " Border",
        "[ " StrUpper(faVal) " ]")
    txtFullAtkGeral.SetFont(GF() " Bold")
    y += 28
    bFA := g.AddText("x" pad " y" y " w" IW " h30 Background" T()["BG2"] " Border Center +0x200 c" T()["ACCENT"] "",
        "▶ DEFINIR FULL ATTACK")
    bFA.SetFont(GF() " Bold")
    bFA.OnEvent("Click", (*) => CapturarTecla("Geral", "fullAttack", txtFullAtkGeral, "FULL ATTACK"))

    y += 36 , g.AddText("x0 y" y " w" W " h1 Background" T()["SEP"]) , y += 10

    ; ── 6. Full Defense ──
    lbl6 := g.AddText("x" pad " y" y " w" IW " c" T()["MUTED"] "", "TECLA FULL DEFENSE (GLOBAL):")
    lbl6.SetFont(GF() " Bold")
    y += 22

    fdVal := IniRead(configFile, "Geral", "fullDefense", "N/A")
    txtFullDefGeral := g.AddText("x" pad " y" y " w" IW " h22 Center c" T()["TEXT"] " Background" T()["BG2"] " Border",
        "[ " StrUpper(fdVal) " ]")
    txtFullDefGeral.SetFont(GF() " Bold")
    y += 28
    bFD := g.AddText("x" pad " y" y " w" IW " h30 Background" T()["BG2"] " Border Center +0x200 c" T()["ACCENT"] "",
        "▶ DEFINIR FULL DEFENSE")
    bFD.SetFont(GF() " Bold")
    bFD.OnEvent("Click", (*) => CapturarTecla("Geral", "fullDefense", txtFullDefGeral, "FULL DEFENSE"))

    y += 36
    g.AddText("x0 y" y " w" W " h16 Background" T()["BG"] "")
    g.Show("w" W " Center")
}
