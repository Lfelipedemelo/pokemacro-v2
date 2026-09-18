; =====================================================
; ui\config_cooldown.ahk — Config Cooldown (tema Pokémon)
; =====================================================

AbrirConfigCooldown() {
    global cfgAberta, radiosCooldown, editsCooldown
    global txtHotkeyCooldown, txtPosicaoClique, txtToggleCD

    if (cfgAberta)
        return
    cfgAberta      := true
    radiosCooldown := []
    editsCooldown  := []

    IW  := 260
    pad := 14
    W   := IW + pad * 2

    cfg := GetCfg("Cooldown")

    cfgGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    cfgGui.BackColor := T()["BG"]
    cfgGui.MarginX   := 0
    cfgGui.MarginY   := 0
    cfgGui.OnEvent("Escape", (*) => (cfgAberta := false, cfgGui.Destroy()))
    OnMessage(0x201, DragJanela)

    _CabecalhoConfig(cfgGui, W, IW, pad, "CONFIG: COOLDOWN", T()["STRIPE2"],
        (*) => ResetarCooldown(),
        (*) => (cfgAberta := false, cfgGui.Destroy()))

    y := 46

    txtHotkeyCooldown := _CampoConfig(cfgGui, pad, y, IW, "HOTKEY COOLDOWN",
        "[ " StrUpper(cfg["hotkeyCooldown"]) " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR HOTKEY",
        (*) => CapturarTecla("Cooldown", "hotkeyCooldown", txtHotkeyCooldown, "HOTKEY COOLDOWN"))

    y += 36 , _Sep(cfgGui, y, W) , y += 10

    txtPosicaoClique := _CampoConfig(cfgGui, pad, y, IW, "POSIÇÃO DO CLIQUE",
        "[ " cfg["clickX"] ", " cfg["clickY"] " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR POSIÇÃO",
        (*) => CapturarPosicaoMouse("Cooldown", txtPosicaoClique))

    y += 36 , _Sep(cfgGui, y, W) , y += 10

    ; ── Pokémon Inicial ──
    lbl := cfgGui.AddText("x" pad " y" y " w" IW " c" T()["MUTED"] "", "POKÉMON INICIAL:")
    lbl.SetFont(GF() " Bold")
    y += 22

    colW := IW // 4   ; = 65

    ; Radios primeiro (consecutivos)
    Loop 4 {
        idx  := A_Index
        radX := pad + (colW * (idx-1)) + (colW // 2) - 8
        opts := "x" radX " y" (y+20) " w16 h16"
        if (idx = 1)
            opts .= " Group"
        if (cfg["pokemonInicial"] = idx)
            opts .= " Checked"
        rad := cfgGui.AddRadio(opts)
        radiosCooldown.Push(rad)
        rad.OnEvent("Click", _GerenciarCliqueRadio)
    }
    ; Números depois
    Loop 4 {
        idx  := A_Index
        numX := pad + (colW * (idx-1))
        n := cfgGui.AddText("x" numX " y" y " w" colW " h18 Center c" T()["TEXT"] " Background" T()["BG"] "", idx)
        n.SetFont(GF() " Bold")
    }

    y += 44 , _Sep(cfgGui, y, W) , y += 10

    ; ── Tempos ──
    lbl2 := cfgGui.AddText("x" pad " y" y " w" IW " c" T()["MUTED"] "", "TEMPOS DE ESPERA (SEGUNDOS):")
    lbl2.SetFont(GF() " Bold")
    y += 22

    Loop 4 {
        idx  := A_Index
        eX   := pad + (colW * (idx-1))
        lE   := cfgGui.AddText("x" eX " y" y " w" colW " h18 Center c" T()["MUTED"] " Background" T()["BG"] "", "PKM " idx)
        lE.SetFont(GF() " Bold")
        edt  := cfgGui.AddEdit("x" (eX+2) " y" (y+20) " w" (colW-4) " h22 Center Background" T()["BG2"] " c" T()["TEXT"] " -E0x200",
            cfg["tempo" . idx])
        edt.SetFont(GF() " Bold")
        editsCooldown.Push(edt)
        edt.OnEvent("Change", ((i, ctrl, *) => SalvarCfg("Cooldown", "tempo" . i, ctrl.Value)).Bind(idx))
    }

    y += 48 , _Sep(cfgGui, y, W) , y += 10

    ; ── Full Defense ──
    fdGlobal := cfg["fullDefense"]
    lbFD := cfgGui.AddText("x" pad " y" y " w" IW " c" T()["MUTED"] "",
        "FULL DEFENSE (TECLA GLOBAL: [ " StrUpper(fdGlobal) " ])")
    lbFD.SetFont(GF() " Bold")
    y += 22

    usaFD := cfg["usarFullDefCD"] = "true"

    ; Radios consecutivos
    rFDSim := cfgGui.AddRadio("x" pad       " y" y " w16 h18 Group" (usaFD  ? " Checked" : ""))
    rFDNao := cfgGui.AddRadio("x" (pad+130) " y" y " w16 h18"       (!usaFD ? " Checked" : ""))

    ; Labels depois
    lFDSim := cfgGui.AddText("x" (pad+20)  " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"] "", "ATIVAR")
    lFDSim.SetFont(GF())
    lFDNao := cfgGui.AddText("x" (pad+150) " y" (y+1) " w100 h16 c" T()["TEXT"] " Background" T()["BG"] "", "DESATIVAR")
    lFDNao.SetFont(GF())

    rFDSim.OnEvent("Click", (*) => SalvarCfg("Cooldown", "usarFullDefCD", "true"))
    rFDNao.OnEvent("Click", (*) => SalvarCfg("Cooldown", "usarFullDefCD", "false"))

    y += 28 , _SepDest(cfgGui, y, W) , y += 10

    y := CriarRadioShowMini(cfgGui, pad, y, IW, "Cooldown")

    _Sep(cfgGui, y, W) , y += 10

    txtToggleCD := _CampoConfig(cfgGui, pad, y, IW, "HOTKEY LIGAR/DESLIGAR",
        "[ " _ComboDisplay(cfg["toggleHotkeyCooldown"]) " ]")
    y += 40
    _BtnConfig(cfgGui, pad, y, IW, "DEFINIR HOTKEY TOGGLE",
        (*) => CapturarCombo("Cooldown", "toggleHotkey", txtToggleCD, "HOTKEY TOGGLE"))

    y += 38
    cfgGui.AddText("x0 y" y " w" W " h12 Background" T()["BG"] "")
    cfgGui.Show("w" W " Center")
}

_GerenciarCliqueRadio(ctrl, *) {
    global radiosCooldown
    indice := 0
    for i, r in radiosCooldown {
        if (r = ctrl) {
            indice := i
            break
        }
    }
    SalvarCfg("Cooldown", "pokemonInicial", indice)
    for i, r in radiosCooldown
        r.Value := (i = indice ? 1 : 0)
}

ResetarCooldown() {
    _CriarGuiConfirmacao(
        "RESETAR COOLDOWN?",
        "Isso limpará hotkey, pokémon e tempos.",
        (g, *) => (ResetarSecao("Cooldown"), _LimparInterfaceCooldown(), g.Destroy(), ShowHint("COOLDOWN RESETADO!", 1000)),
        (g, *) => g.Destroy()
    )
}

_LimparInterfaceCooldown() {
    global radiosCooldown, editsCooldown, txtHotkeyCooldown, txtToggleCD
    try {
        txtHotkeyCooldown.Value := "[ N/A ]"
        txtToggleCD.Value       := "[ N/A ]"
        for i, r in radiosCooldown
            r.Value := (i = 1 ? 1 : 0)
        for edt in editsCooldown
            edt.Value := "0"
        ShowHint("INTERFACE RESETADA!", 1000)
    }
}
