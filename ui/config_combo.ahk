; =====================================================
; ui\config_combo.ahk — Config de Combo (GDI+)
; =====================================================

; Delay entre teclas do combo — um valor só, compartilhado por todos os
; combos (principal, secundário e combo revive). Fica em [Geral] e não
; na seção do combo para que mexer numa tela valha para todas e o
; "resetar" de um combo não apague o valor dos outros.
GetSleepCombo() {
    return _CfgInt("Geral", "sleepCombo", 550)
}

; Slider do delay entre teclas, reaproveitado pelas telas de combo.
_GCfg_SliderSleepCombo(g, boxes, x, y, w, hoverId) {
    return _GCfg_Slider(g, boxes, "sleep", x, y, w, "DELAY ENTRE TECLAS (TODOS OS COMBOS)", GetSleepCombo(),
        300, 800, 1, "ms", (v) => SalvarCfg("Geral", "sleepCombo", v), hoverId)
}

AbrirConfigCombo(tipo) {
    _GCfg_Abrir(288, 308, _DesenharConfigCombo.Bind(tipo))
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
        (*) => _GCfg_Fechar(),
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

    _GCfg_Field(g, boxes, "hkmacro", pad, y, colW, "TECLA DO MACRO", _ComboDisplay(cfg["teclaHotkey"]),
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

    y += _GCfg_SliderSleepCombo(g, boxes, pad, y, w - pad*2, hoverId) + 8

    _GCfg_ShowInMini(g, boxes, pad, y, w - pad*2, tipo, hoverId)

    Gdip_ResetClip(g)
    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, 14)
    Gdip_DeletePen(borderPen)

    return boxes
}

ResetarConfiguracoes(tipo) {
    _GCfg_Confirmar(
        "RESETAR " StrUpper(tipo) "?",
        "Esta ação não pode ser desfeita.",
        (*) => (ResetarSecao(tipo), ShowHint("RESETADO!", 1000, "success"))
    )
}
