; =====================================================
; ui\config_revive.ahk — Config Revive (GDI+)
; =====================================================

AbrirTelaConfigRevive(tipo) {
    _GCfg_Abrir(288, 256, _DesenharConfigRevive)
}

_DesenharConfigRevive(g, w, h, hoverId) {
    boxes := []
    cfg := GetCfg("Revive")

    Gdip_SetClipRoundRect(g, 0, 0, w, h, 14)
    bodyBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG"]))
    Gdip_FillRect(g, bodyBrush, 0, 0, w, h)
    Gdip_DeleteBrush(bodyBrush)

    hH := _GCfg_Header(g, boxes, w, "CONFIG: REVIVE", T()["STRIPE1"],
        (*) => ResetarConfigRevive(),
        (*) => _GCfg_Fechar(),
        hoverId)

    pad  := 14
    colW := (w - pad*2 - 10) // 2
    col2 := pad + colW + 10
    y := hH + 10

    _GCfg_Field(g, boxes, "pos", pad, y, colW, "POSIÇÃO", "[ " cfg["x"] ", " cfg["y"] " ]",
        (*) => (CapturarPosicaoMouse("Revive", 0, "xRevive", "yRevive"), _GCfg_Redraw()), hoverId)
    _GCfg_Field(g, boxes, "hkrevive", col2, y, colW, "HOTKEY REVIVE", StrUpper(cfg["teclaInputRevive"]),
        (*) => (CapturarTecla("Revive", "teclaInputRevive", 0, "HOTKEY REVIVE"), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    y += _GCfg_Slider(g, boxes, "delay", pad, y, w - pad*2, "DELAY ENTRE CLIQUES", cfg["delayRevive"],
        10, 200, 1, "ms", (v) => SalvarCfg("Revive", "delayRevive", v), hoverId) + 8

    _GCfg_Field(g, boxes, "hkmacro", pad, y, colW, "TECLA DO MACRO", StrUpper(cfg["teclaHotkey"]),
        (*) => (CapturarTecla("Revive", "teclaHotkey", 0, "TECLA MACRO REVIVE"), _GCfg_Redraw()), hoverId)
    _GCfg_Field(g, boxes, "toggle", col2, y, colW, "LIGAR/DESLIGAR", _ComboDisplay(cfg["toggleHotkeyRevive"]),
        (*) => (CapturarCombo("Revive", "toggleHotkey", 0, "HOTKEY TOGGLE"), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    _GCfg_ShowInMini(g, boxes, pad, y, w - pad*2, "Revive", hoverId)

    Gdip_ResetClip(g)
    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, 14)
    Gdip_DeletePen(borderPen)

    return boxes
}

ResetarConfigRevive() {
    _CriarGuiConfirmacao(
        "RESETAR REVIVE?",
        "Isso limpará posição, teclas e delay.",
        (g, *) => (ResetarSecao("Revive"), g.Destroy(), _GCfg_Redraw(), ShowHint("REVIVE RESETADO!", 1000, "success")),
        (g, *) => g.Destroy()
    )
}
