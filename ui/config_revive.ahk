; =====================================================
; ui\config_revive.ahk — Config Revive (tema Pokémon)
; =====================================================

AbrirTelaConfigRevive(tipo) {
    global cfgAberta
    global txtTeclaHotkeyRevive, txtPosRevive, txtTeclaInputRevive, editDelay, txtToggleRevive

    if (cfgAberta)
        return
    cfgAberta := true

    IW  := 260
    pad := 14
    W   := IW + pad * 2

    cfg := GetCfg(tipo)

    cfgGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    cfgGui.BackColor := T()["BG"]
    cfgGui.MarginX   := 0
    cfgGui.MarginY   := 0
    cfgGui.OnEvent("Escape", (*) => (cfgAberta := false, cfgGui.Destroy()))
    cfgGui.OnEvent("Close",  (*) => (cfgAberta := false))
    OnMessage(0x201, DragJanela)

    _CabecalhoConfig(cfgGui, W, IW, pad, "CONFIG: " StrUpper(tipo), T()["STRIPE1"],
        (*) => ResetarConfigRevive(),
        (*) => (cfgAberta := false, cfgGui.Destroy()))

    y := 46

    txtPosRevive := _CampoConfig(cfgGui, pad, y, IW, "POSIÇÃO DO CLIQUE", "[ " cfg["x"] ", " cfg["y"] " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR POSIÇÃO",
        (*) => CapturarPosicaoMouse("Revive", txtPosRevive, "xRevive", "yRevive"))

    y += 36 , _Sep(cfgGui, y, W) , y += 10

    txtTeclaInputRevive := _CampoConfig(cfgGui, pad, y, IW, "HOTKEY REVIVE",
        "[ " StrUpper(cfg["teclaInputRevive"]) " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR HOTKEY",
        (*) => CapturarTecla("Revive", "teclaInputRevive", txtTeclaInputRevive, "HOTKEY REVIVE"))

    y += 36 , _Sep(cfgGui, y, W) , y += 10

    txtTeclaHotkeyRevive := _CampoConfig(cfgGui, pad, y, IW, "TECLA DO MACRO",
        "[ " StrUpper(cfg["teclaHotkey"]) " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR TECLA MACRO",
        (*) => CapturarTecla("Revive", "teclaHotkey", txtTeclaHotkeyRevive, "TECLA MACRO REVIVE"))

    y += 36 , _Sep(cfgGui, y, W) , y += 10

    ; ── Delay ──
    lbl := cfgGui.AddText("x" pad " y" y " w" IW " h18 Center c" T()["MUTED"] " +0x200", "DELAY ENTRE CLIQUES (MS)")
    lbl.SetFont(GF() " Bold")
    y += 22
    editDelay := cfgGui.AddEdit(
        "x" pad " y" y " w" IW " h26 Center Number c" T()["TEXT"] " Background" T()["BG2"] " -E0x200",
        cfg["delayRevive"])
    editDelay.SetFont(GF() " Bold")
    editDelay.OnEvent("Change", (ctrl, *) => SalvarCfg("Revive", "delayRevive", ctrl.Value))

    y += 34 , _SepDest(cfgGui, y, W) , y += 10

    y := CriarRadioShowMini(cfgGui, pad, y, IW, "Revive")

    _Sep(cfgGui, y, W) , y += 10

    txtToggleRevive := _CampoConfig(cfgGui, pad, y, IW, "HOTKEY LIGAR/DESLIGAR",
        "[ " _ComboDisplay(cfg["toggleHotkeyRevive"]) " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR HOTKEY TOGGLE",
        (*) => CapturarCombo("Revive", "toggleHotkey", txtToggleRevive, "HOTKEY TOGGLE"))

    y += 38
    cfgGui.AddText("x0 y" y " w" W " h12 Background" T()["BG"] "")
    cfgGui.Show("w" W " Center")
}

ResetarConfigRevive() {
    _CriarGuiConfirmacao(
        "RESETAR REVIVE?",
        "Isso limpará posição, teclas e delay.",
        (g, *) => (ResetarSecao("Revive"), _LimparCamposRevive(), g.Destroy(), ShowHint("REVIVE RESETADO!", 1000)),
        (g, *) => g.Destroy()
    )
}

_LimparCamposRevive() {
    global txtPosRevive, txtTeclaHotkeyRevive, txtTeclaInputRevive, editDelay, txtToggleRevive
    try {
        txtPosRevive.Value         := "[ N/A, N/A ]"
        txtTeclaHotkeyRevive.Value := "[ N/A ]"
        txtTeclaInputRevive.Value  := "[ N/A ]"
        editDelay.Value            := "100"
        txtToggleRevive.Value      := "[ N/A ]"
    }
}
