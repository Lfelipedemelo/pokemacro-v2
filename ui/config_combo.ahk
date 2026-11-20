; =====================================================
; ui\config_combo.ahk — Config de Combo (GDI+)
; =====================================================

; Delay entre teclas do combo — um valor só, compartilhado por todos os
; combos (principal, secundário e combo revive). Fica em [Geral] e não
; na seção do combo para que mexer numa tela valha para todas e o
; "resetar" de um combo não apague o valor dos outros.
; Faixa SLEEP_COMBO_MIN..SLEEP_COMBO_MAX (300 a 1000 ms), padrão 450 —
; abaixo de 300 o jogo perde teclas.
GetSleepCombo() {
    return Max(SLEEP_COMBO_MIN, Min(SLEEP_COMBO_MAX, _CfgInt("Geral", "sleepCombo", SLEEP_COMBO_PADRAO)))
}

; Slider do delay entre teclas, reaproveitado pelas telas de combo.
_GCfg_SliderSleepCombo(g, boxes, x, y, w, hoverId) {
    return _GCfg_Slider(g, boxes, "sleep", x, y, w, "DELAY ENTRE TECLAS (TODOS OS COMBOS)", GetSleepCombo(),
        SLEEP_COMBO_MIN, SLEEP_COMBO_MAX, 1, "ms", (v) => SalvarCfg("Geral", "sleepCombo", v), hoverId)
}

; Fechar a tela fecha também a prévia da contagem do stun.
AbrirConfigCombo(tipo) {
    _GCfg_Abrir(288, 464, _DesenharConfigCombo.Bind(tipo), FecharPreviewContador)
}

; Botão do stun do combo como aparece no campo: "F5", ou "—" se nenhum
; (ou um que saiu da faixa do combo depois de mudar as teclas dele).
_TextoStunCombo(tipo) {
    t := Max(0, _CfgInt(tipo, "stunTecla", 0))
    for tc in TeclasDoCombo(tipo)
        if (tc = t)
            return _NomeTeclaCombo(t)
    return "—"
}

; Seletor do botão do stun: as teclas do combo, da inicial à final.
_EscolherStunCombo(tipo, ancora, *) {
    teclas := TeclasDoCombo(tipo)
    if !teclas.Length {
        ShowHint("Defina o BOTÃO INICIAL e o FINAL primeiro", 1600, "warn")
        return
    }
    opcoes := [], sel := 0
    atual := _CfgInt(tipo, "stunTecla", 0)
    for tc in teclas {
        opcoes.Push(_NomeTeclaCombo(tc))
        if (tc = atual)
            sel := A_Index
    }
    _GCfg_AbrirSeletor(ancora, "CONTAR 6s AO ENVIAR QUAL BOTÃO", opcoes, sel,
        (idx) => SalvarCfg(tipo, "stunTecla", teclas[idx]), 30)
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

    ; ── Contagem do stun (6 s) ao enviar um botão do combo pela hotkey
    ;    (na Rotação vale o chip STUN de cada passo). Ligar/desligar e o
    ;    botão são deste combo; tamanho e posição da contagem são os
    ;    mesmos nos dois combos. ──
    stunLigado := CfgLer(tipo, "stunAtivo", "false") = "true"
    _GCfg_Toggle(g, boxes, "stun", pad, y, colW, "CONTAR STUN (6s)", "SIM", "NÃO", stunLigado,
        (*) => SalvarCfg(tipo, "stunAtivo", "true"),
        (*) => SalvarCfg(tipo, "stunAtivo", "false"), hoverId)
    ancoraStun := { x: col2, y: y, w: colW, h: 44 }
    _GCfg_Field(g, boxes, "stunTecla", col2, y, colW, "BOTÃO DO STUN", _TextoStunCombo(tipo),
        _EscolherStunCombo.Bind(tipo, ancoraStun), hoverId)
    y += 44 + 8

    n0 := boxes.Length, yStun := y
    _GCfg_Toggle(g, boxes, "stunTam", pad, y, colW, "CONTAGEM DO STUN", "NORMAL", "COMPACTA",
        CfgLer("Geral", "stunCompacta", "false") != "true",
        (*) => (SalvarCfg("Geral", "stunCompacta", "false"), _ContadorPrevDesenhar()),
        (*) => (SalvarCfg("Geral", "stunCompacta", "true"), _ContadorPrevDesenhar()), hoverId)
    _GCfg_Field(g, boxes, "stunPos", col2, y, colW, "POSIÇÃO", ContadorPosTexto("stun"),
        (*) => AlternarPreviewContador("stun"), hoverId)
    y += 44 + 8
    _GCfg_Field(g, boxes, "stunCopiar", pad, y, w - pad*2, "POSIÇÃO DA CONTAGEM DA PAUSA (ROTAÇÃO)", "USAR A MESMA NO STUN",
        (*) => (CopiarContador("pausa", "stun"), ShowHint("STUN: mesma posição e tamanho da pausa", 1400, "success")), hoverId)
    y += 44 + 8
    if !stunLigado
        _GCfg_Apagar(g, boxes, n0, pad, yStun, w - pad*2, y - 8 - yStun)

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
