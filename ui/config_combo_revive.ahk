; =====================================================
; ui\config_combo_revive.ahk — Config Combo Revive (GDI+)
; =====================================================

AbrirConfigComboRevive() {
    _GCfg_Abrir(288, 360, _DesenharConfigComboRevive)
}

_DesenharConfigComboRevive(g, w, h, hoverId) {
    boxes := []
    cfg := GetCfg("comboRevive")

    Gdip_SetClipRoundRect(g, 0, 0, w, h, 14)
    bodyBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG"]))
    Gdip_FillRect(g, bodyBrush, 0, 0, w, h)
    Gdip_DeleteBrush(bodyBrush)

    hH := _GCfg_Header(g, boxes, w, "CONFIG: COMBO REVIVE", T()["STRIPE1"],
        (*) => ResetarConfigCR(),
        (*) => _GCfg_Fechar(),
        hoverId)

    pad  := 14
    colW := (w - pad*2 - 10) // 2
    col2 := pad + colW + 10
    y := hH + 10

    _GCfg_Field(g, boxes, "inicial", pad, y, colW, "BOTÃO INICIAL", cfg["teclaInicial"],
        (*) => (CapturarTecla("comboRevive", "teclaInicial", 0, "BOTÃO INICIAL"), _GCfg_Redraw()), hoverId)
    _GCfg_Field(g, boxes, "final", col2, y, colW, "BOTÃO FINAL", cfg["teclaFinal"],
        (*) => (CapturarTecla("comboRevive", "teclaFinal", 0, "BOTÃO FINAL"), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    _GCfg_Field(g, boxes, "hkmacro", pad, y, colW, "TECLA DO MACRO", _ComboDisplay(cfg["teclaHotkey"]),
        (*) => (CapturarTecla("comboRevive", "teclaHotkey", 0, "TECLA MACRO"), _GCfg_Redraw()), hoverId)
    _GCfg_Field(g, boxes, "toggle", col2, y, colW, "LIGAR/DESLIGAR", _ComboDisplay(cfg["toggleHotkey"]),
        (*) => (CapturarCombo("comboRevive", "toggleHotkey", 0, "HOTKEY TOGGLE"), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    usaAtk := cfg["usarFullAtk"] = "true"
    usaDef := cfg["usarFullDef"] = "true"
    _GCfg_Toggle(g, boxes, "atk", pad, y, colW, "FULL ATTACK", "ATIVAR", "DESATIVAR", usaAtk,
        (*) => SalvarCfg("comboRevive", "usarFullAtk", "true"),
        (*) => SalvarCfg("comboRevive", "usarFullAtk", "false"), hoverId)
    _GCfg_Toggle(g, boxes, "def", col2, y, colW, "FULL DEFENSE", "ATIVAR", "DESATIVAR", usaDef,
        (*) => SalvarCfg("comboRevive", "usarFullDef", "true"),
        (*) => SalvarCfg("comboRevive", "usarFullDef", "false"), hoverId)
    y += 44 + 8

    y += _GCfg_Slider(g, boxes, "delay", pad, y, w - pad*2, "DELAY APÓS REVIVE", cfg["delayCombo"],
        100, 2000, 10, "ms", (v) => SalvarCfg("comboRevive", "delayCombo", v), hoverId) + 8

    y += _GCfg_SliderSleepCombo(g, boxes, pad, y, w - pad*2, hoverId) + 8

    _GCfg_ShowInMini(g, boxes, pad, y, w - pad*2, "comboRevive", hoverId)

    Gdip_ResetClip(g)
    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, 14)
    Gdip_DeletePen(borderPen)

    return boxes
}

ResetarConfigCR() {
    _GCfg_Confirmar(
        "RESETAR COMBO REVIVE?",
        "Esta ação não pode ser desfeita.",
        (*) => (ResetarSecao("comboRevive"), ShowHint("RESETADO!", 1000, "success"))
    )
}
