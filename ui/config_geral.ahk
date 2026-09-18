; =====================================================
; ui\config_geral.ahk — Configurações Gerais (GDI+)
; =====================================================

GetSleepCombo() {
    global configFile
    return Integer(IniRead(configFile, "Geral", "sleepCombo", "550"))
}

GetUsarPrefixoF() {
    global configFile
    return IniRead(configFile, "Geral", "usarPrefixoF", "true")
}

GetModoLegado() {
    global configFile
    return IniRead(configFile, "Geral", "modoLegado", "false")
}

AbrirConfigGeral() {
    _GCfg_Abrir(288, 204, _DesenharConfigGeral)
}

_DesenharConfigGeral(g, w, h, hoverId) {
    global configFile
    boxes := []

    Gdip_SetClipRoundRect(g, 0, 0, w, h, 14)
    bodyBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG"]))
    Gdip_FillRect(g, bodyBrush, 0, 0, w, h)
    Gdip_DeleteBrush(bodyBrush)

    hH := _GCfg_Header(g, boxes, w, "CONFIGURAÇÕES GERAIS", T()["ACCENT2"], 0, (*) => _GCfg_Fechar(), hoverId)

    pad  := 14
    colW := (w - pad*2 - 10) // 2
    col2 := pad + colW + 10
    y := hH + 10

    y += _GCfg_Slider(g, boxes, "sleep", pad, y, w - pad*2, "DELAY ENTRE TECLAS DO COMBO", GetSleepCombo(),
        300, 800, 1, "ms", (v) => IniWrite(v, configFile, "Geral", "sleepCombo"), hoverId) + 8

    usarF := GetUsarPrefixoF()
    _GCfg_Toggle(g, boxes, "prefF", pad, y, colW, "PREFIXO [F]", "F1..F9", "1..9", usarF = "true",
        (*) => IniWrite("true",  configFile, "Geral", "usarPrefixoF"),
        (*) => IniWrite("false", configFile, "Geral", "usarPrefixoF"), hoverId)

    modoLegado := GetModoLegado()
    _GCfg_Toggle(g, boxes, "legado", col2, y, colW, "MODO LEGADO", "ATIVO", "INATIVO", modoLegado = "true",
        (*) => IniWrite("true",  configFile, "Geral", "modoLegado"),
        (*) => IniWrite("false", configFile, "Geral", "modoLegado"), hoverId)
    y += 44 + 8

    faVal := IniRead(configFile, "Geral", "fullAttack", "N/A")
    _GCfg_Field(g, boxes, "fa", pad, y, colW, "FULL ATTACK", StrUpper(faVal),
        (*) => (CapturarTecla("Geral", "fullAttack", 0, "FULL ATTACK"), _GCfg_Redraw()), hoverId)

    fdVal := IniRead(configFile, "Geral", "fullDefense", "N/A")
    _GCfg_Field(g, boxes, "fd", col2, y, colW, "FULL DEFENSE", StrUpper(fdVal),
        (*) => (CapturarTecla("Geral", "fullDefense", 0, "FULL DEFENSE"), _GCfg_Redraw()), hoverId)

    Gdip_ResetClip(g)
    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, 14)
    Gdip_DeletePen(borderPen)

    return boxes
}
