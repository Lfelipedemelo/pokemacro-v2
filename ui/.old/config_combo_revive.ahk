; =====================================================
; ui\config_combo_revive.ahk — Config Combo Revive
; =====================================================

AbrirConfigComboRevive() {
    global cfgAberta
    global txtTeclaInicialCR, txtTeclaFinalCR, txtHotkeyComboCR, txtToggleCR

    if (cfgAberta)
        return
    cfgAberta := true

    IW  := 260
    pad := 14
    W   := IW + pad * 2

    cfg := GetCfg("comboRevive")

    cfgGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    cfgGui.BackColor := T()["BG"]
    cfgGui.MarginX   := 0
    cfgGui.MarginY   := 0
    cfgGui.OnEvent("Escape", (*) => _FecharConfigCR(cfgGui))
    cfgGui.OnEvent("Close",  (*) => (cfgAberta := false))
    OnMessage(0x201, DragJanela)

    _CabecalhoConfig(cfgGui, W, IW, pad, "CONFIG: COMBO REVIVE", T()["STRIPE1"],
        (*) => ResetarConfigCR(),
        (*) => _FecharConfigCR(cfgGui))

    y := 46

    ; ── Combo ────────────────────────────────────────
    txtTeclaInicialCR := _CampoConfig(cfgGui, pad, y, IW, "BOTÃO INICIAL", "[ " cfg["teclaInicial"] " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR BOTÃO INICIAL",
        (*) => CapturarTecla("comboRevive", "teclaInicial", txtTeclaInicialCR, "BOTÃO INICIAL"))

    y += 36 , _Sep(cfgGui, y, W) , y += 10

    txtTeclaFinalCR := _CampoConfig(cfgGui, pad, y, IW, "BOTÃO FINAL", "[ " cfg["teclaFinal"] " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR BOTÃO FINAL",
        (*) => CapturarTecla("comboRevive", "teclaFinal", txtTeclaFinalCR, "BOTÃO FINAL"))

    y += 36 , _Sep(cfgGui, y, W) , y += 10

    txtHotkeyComboCR := _CampoConfig(cfgGui, pad, y, IW, "TECLA DO MACRO",
        "[ " StrUpper(cfg["teclaHotkey"]) " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR TECLA MACRO",
        (*) => CapturarTecla("comboRevive", "teclaHotkey", txtHotkeyComboCR, "TECLA MACRO"))

    y += 36 , _Sep(cfgGui, y, W) , y += 10

    ; ── Full Attack / Defense ────────────────────────
    faGlobal := cfg["fullAttack"]
    fdGlobal := cfg["fullDefense"]
    usaAtk   := cfg["usarFullAtk"] = "true"
    usaDef   := cfg["usarFullDef"] = "true"

    lbFA := cfgGui.AddText("x" pad " y" y " w" IW " c" T()["MUTED"] "",
        "FULL ATTACK (TECLA GLOBAL: [ " StrUpper(faGlobal) " ])")
    lbFA.SetFont(GF() " Bold")
    y += 22

    rAtkSim := cfgGui.AddRadio("x" pad       " y" y " w16 h18 Group" (usaAtk  ? " Checked" : ""))
    rAtkNao := cfgGui.AddRadio("x" (pad+130) " y" y " w16 h18"       (!usaAtk ? " Checked" : ""))
    lAS := cfgGui.AddText("x" (pad+20)  " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"] "", "ATIVAR")
    lAS.SetFont(GF())
    lAN := cfgGui.AddText("x" (pad+150) " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"] "", "DESATIVAR")
    lAN.SetFont(GF())
    rAtkSim.OnEvent("Click", (*) => SalvarCfg("comboRevive", "usarFullAtk", "true"))
    rAtkNao.OnEvent("Click", (*) => SalvarCfg("comboRevive", "usarFullAtk", "false"))

    y += 28 , _Sep(cfgGui, y, W) , y += 10

    lbFD := cfgGui.AddText("x" pad " y" y " w" IW " c" T()["MUTED"] "",
        "FULL DEFENSE (TECLA GLOBAL: [ " StrUpper(fdGlobal) " ])")
    lbFD.SetFont(GF() " Bold")
    y += 22

    rDefSim := cfgGui.AddRadio("x" pad       " y" y " w16 h18 Group" (usaDef  ? " Checked" : ""))
    rDefNao := cfgGui.AddRadio("x" (pad+130) " y" y " w16 h18"       (!usaDef ? " Checked" : ""))
    lDS := cfgGui.AddText("x" (pad+20)  " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"] "", "ATIVAR")
    lDS.SetFont(GF())
    lDN := cfgGui.AddText("x" (pad+150) " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"] "", "DESATIVAR")
    lDN.SetFont(GF())
    rDefSim.OnEvent("Click", (*) => SalvarCfg("comboRevive", "usarFullDef", "true"))
    rDefNao.OnEvent("Click", (*) => SalvarCfg("comboRevive", "usarFullDef", "false"))

    y += 28 , _Sep(cfgGui, y, W) , y += 10

    ; ── Delay Combo (ms) ─────────────────────────────
    lbl := cfgGui.AddText("x" pad " y" y " w" IW " h18 Center c" T()["MUTED"] " +0x200",
        "DELAY APÓS REVIVE (MS)")
    lbl.SetFont(GF() " Bold")
    y += 22

    editDelay := cfgGui.AddEdit(
        "x" pad " y" y " w" IW " h26 Center Number c" T()["TEXT"] " Background" T()["BG2"] " -E0x200",
        cfg["delayCombo"])
    editDelay.SetFont(GF() " Bold")
    editDelay.OnEvent("Change", (ctrl, *) => SalvarCfg("comboRevive", "delayCombo", ctrl.Value))

    y += 34 , _SepDest(cfgGui, y, W) , y += 10

    ; ── Toggle Hotkey ────────────────────────────────
    txtToggleCR := _CampoConfig(cfgGui, pad, y, IW, "HOTKEY LIGAR/DESLIGAR",
        "[ " _ComboDisplay(cfg["toggleHotkey"]) " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR HOTKEY TOGGLE",
        (*) => CapturarCombo("comboRevive", "toggleHotkey", txtToggleCR, "HOTKEY TOGGLE"))

    y += 38
    cfgGui.AddText("x0 y" y " w" W " h12 Background" T()["BG"] "")
    cfgGui.Show("w" W " Center")
}

_FecharConfigCR(cfgGui) {
    global cfgAberta
    cfgAberta := false
    AtualizarHotkeyCombo()
    cfgGui.Destroy()
}

ResetarConfigCR() {
    _CriarGuiConfirmacao(
        "RESETAR COMBO REVIVE?",
        "Esta ação não pode ser desfeita.",
        (g, *) => (ResetarSecao("comboRevive"), _LimparCamposCR(), g.Destroy(), ShowHint("RESETADO!", 1000)),
        (g, *) => g.Destroy()
    )
}

_LimparCamposCR() {
    global txtTeclaInicialCR, txtTeclaFinalCR, txtHotkeyComboCR, txtToggleCR
    try {
        txtTeclaInicialCR.Value := "[ N/A ]"
        txtTeclaFinalCR.Value   := "[ N/A ]"
        txtHotkeyComboCR.Value  := "[ N/A ]"
        txtToggleCR.Value       := "[ N/A ]"
    }
}
