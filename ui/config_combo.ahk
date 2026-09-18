; =====================================================
; ui\config_combo.ahk — Config de Combo (GDI+)
; =====================================================

AbrirConfigCombo(tipo) {
    _GCfg_Abrir(288, 256, _DesenharConfigCombo.Bind(tipo))
}

_DesenharConfigCombo(tipo, g, w, h, hoverId) {
    boxes := []
    cfg := GetCfg(tipo)

    Gdip_SetClipRoundRect(g, 0, 0, w, h, 14)
    bodyBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG"]))
    Gdip_FillRect(g, bodyBrush, 0, 0, w, h)
    Gdip_DeleteBrush(bodyBrush)

    hH := _GCfg_Header(g, boxes, w, "CONFIG: " StrUpper(tipo), T()["STRIPE3"],
        (*) => ResetarConfiguracoes(tipo),
        (*) => _FecharConfigCombo(),
        hoverId)

    pad  := 14
    colW := (w - pad*2 - 10) // 2
    col2 := pad + colW + 10
    y := hH + 10

    _GCfg_Field(g, boxes, "inicial", pad, y, colW, "BOTÃO INICIAL", cfg["teclaInicial"],
        (*) => (CapturarTecla(tipo, "teclaInicial", 0, "BOTÃO INICIAL"), _GCfg_Redraw()), hoverId)
    _GCfg_Field(g, boxes, "final", col2, y, colW, "BOTÃO FINAL", cfg["teclaFinal"],
        (*) => (CapturarTecla(tipo, "teclaFinal", 0, "BOTÃO FINAL"), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    _GCfg_Field(g, boxes, "hkmacro", pad, y, colW, "TECLA DO MACRO", StrUpper(cfg["teclaHotkey"]),
        (*) => (CapturarTecla(tipo, "teclaHotkey", 0, "TECLA MACRO"), _GCfg_Redraw()), hoverId)
    _GCfg_Field(g, boxes, "toggle", col2, y, colW, "LIGAR/DESLIGAR", _ComboDisplay(cfg["toggleHotkey"]),
        (*) => (CapturarCombo(tipo, "toggleHotkey", 0, "HOTKEY TOGGLE"), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    usaAtk := cfg["usarFullAtk"] = "true"
    usaDef := cfg["usarFullDef"] = "true"
    _GCfg_Toggle(g, boxes, "atk", pad, y, colW, "FULL ATTACK", "ATIVAR", "DESATIVAR", usaAtk,
        (*) => SalvarCfg(tipo, "usarFullAtk", "true"),
        (*) => SalvarCfg(tipo, "usarFullAtk", "false"), hoverId)
    _GCfg_Toggle(g, boxes, "def", col2, y, colW, "FULL DEFENSE", "ATIVAR", "DESATIVAR", usaDef,
        (*) => SalvarCfg(tipo, "usarFullDef", "true"),
        (*) => SalvarCfg(tipo, "usarFullDef", "false"), hoverId)
    y += 44 + 8

    _GCfg_ShowInMini(g, boxes, pad, y, w - pad*2, tipo, hoverId)

    Gdip_ResetClip(g)
    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, 14)
    Gdip_DeletePen(borderPen)

    return boxes
}

_FecharConfigCombo() {
    AtualizarHotkeyCombo()
    _GCfg_Fechar()
}

ResetarConfiguracoes(tipo) {
    _CriarGuiConfirmacao(
        "RESETAR " StrUpper(tipo) "?",
        "Esta ação não pode ser desfeita.",
        (g, *) => (ResetarSecao(tipo), g.Destroy(), _GCfg_Redraw(), ShowHint("RESETADO!", 1000, "success")),
        (g, *) => g.Destroy()
    )
}

; ── Helpers compartilhados de confirmação (ainda nativos) ────────────
; Continua com controles Win32 normais — é um popup pequeno e raro,
; não precisa do tratamento GDI+ das telas principais.
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
