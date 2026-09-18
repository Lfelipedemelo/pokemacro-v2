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

; Orientação da barra de ícones da HUD — "horizontal" (padrão, ícones
; lado a lado) ou "vertical" (ícones empilhados numa coluna). Lida em
; tempo real por _HudRedraw (ui\mini_menu.ahk), sem cache.
GetHudOrientacao() {
    global configFile
    return IniRead(configFile, "Geral", "hudOrientacao", "horizontal")
}

AbrirConfigGeral() {
    _GCfg_Abrir(288, 528, _DesenharConfigGeral)
}

; ── Tamanho da interface (HUD + telas de config) ──
; Mapeamento simples índice (pílula de 3 opções) <-> nome salvo no INI.
_ConfigGeral_EscalaIdx(nome) {
    switch nome {
        case "pequeno": return 1
        case "grande":  return 3
        default:        return 2
    }
}

_ConfigGeral_EscalaNome(idx) {
    switch idx {
        case 1:  return "pequeno"
        case 3:  return "grande"
        default: return "normal"
    }
}

; ── Macros que podem ser exibidos/ocultados na HUD (Ctrl+F12) ──
; Mesma seção/chave "showInMini" usada pelo toggle "EXIBIR NO MINI MENU"
; de cada tela de macro (_GCfg_ShowInMini em lib\gdip_config.ahk) — este
; painel só dá um lugar único para ver e mexer nos 5 de uma vez.
_ConfigGeral_MacrosVisiveis() {
    return [
        Map("secao", "comboPrincipal",  "label", "COMBO PRINCIPAL"),
        Map("secao", "comboSecundario", "label", "COMBO SECUNDÁRIO"),
        Map("secao", "Revive",          "label", "REVIVER"),
        Map("secao", "comboRevive",     "label", "COMBO REVIVE"),
        Map("secao", "Cooldown",        "label", "COOLDOWN"),
    ]
}

; Cartão de alternância "exibir na HUD" para um macro específico. idBase
; inclui a seção para não colidir com o hover dos outros cartões da
; lista (todos usariam "showmini" se reaproveitassem _GCfg_ShowInMini).
_GCfg_VisibilidadeItem(g, boxes, x, y, w, secao, label, hoverId) {
    atual := GetShowInMini(secao)
    return _GCfg_Toggle(g, boxes, "vis_" secao, x, y, w, label, "SIM", "NÃO", atual,
        (*) => (SalvarCfg(secao, "showInMini", "true"),  _RecriarMini(), _GCfg_Redraw()),
        (*) => (SalvarCfg(secao, "showInMini", "false"), _RecriarMini(), _GCfg_Redraw()), hoverId)
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

    ; "Normal" é o tamanho de sempre da HUD e das telas de config — ver
    ; AplicarEscalaInterface (lib\gdip_config.ahk) e _HUD_SCALE (ui\mini_menu.ahk).
    _GCfg_Segmented(g, boxes, "escala", pad, y, w - pad*2, "TAMANHO DA INTERFACE",
        ["PEQUENO", "NORMAL", "GRANDE"], _ConfigGeral_EscalaIdx(GetEscalaInterface()),
        (idx) => AplicarEscalaInterface(_ConfigGeral_EscalaNome(idx)), hoverId)
    y += 44 + 8

    orientVertical := GetHudOrientacao() = "vertical"
    _GCfg_Toggle(g, boxes, "orient", pad, y, w - pad*2, "ORIENTAÇÃO DOS ÍCONES (HUD)", "HORIZONTAL", "VERTICAL", !orientVertical,
        (*) => (IniWrite("horizontal", configFile, "Geral", "hudOrientacao"), _RecriarMini()),
        (*) => (IniWrite("vertical",   configFile, "Geral", "hudOrientacao"), _RecriarMini()), hoverId)
    y += 44 + 8

    faVal := IniRead(configFile, "Geral", "fullAttack", "N/A")
    _GCfg_Field(g, boxes, "fa", pad, y, colW, "FULL ATTACK", StrUpper(faVal),
        (*) => (CapturarTecla("Geral", "fullAttack", 0, "FULL ATTACK"), _GCfg_Redraw()), hoverId)

    fdVal := IniRead(configFile, "Geral", "fullDefense", "N/A")
    _GCfg_Field(g, boxes, "fd", col2, y, colW, "FULL DEFENSE", StrUpper(fdVal),
        (*) => (CapturarTecla("Geral", "fullDefense", 0, "FULL DEFENSE"), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    Gdip_DrawText(g, "MACROS EXIBIDOS NA INTERFACE", 9, true, Gdip_Argb(255, T()["MUTED"]), pad, y, w - pad*2, 14, false)
    y += 20

    itens := _ConfigGeral_MacrosVisiveis()
    _GCfg_VisibilidadeItem(g, boxes, pad,  y, colW, itens[1]["secao"], itens[1]["label"], hoverId)
    _GCfg_VisibilidadeItem(g, boxes, col2, y, colW, itens[2]["secao"], itens[2]["label"], hoverId)
    y += 44 + 8

    _GCfg_VisibilidadeItem(g, boxes, pad,  y, colW, itens[3]["secao"], itens[3]["label"], hoverId)
    _GCfg_VisibilidadeItem(g, boxes, col2, y, colW, itens[4]["secao"], itens[4]["label"], hoverId)
    y += 44 + 8

    _GCfg_VisibilidadeItem(g, boxes, pad, y, w - pad*2, itens[5]["secao"], itens[5]["label"], hoverId)
    y += 44

    Gdip_ResetClip(g)
    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, 14)
    Gdip_DeletePen(borderPen)

    return boxes
}
