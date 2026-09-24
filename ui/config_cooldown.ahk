; =====================================================
; ui\config_cooldown.ahk — Config Cooldown (GDI+)
; =====================================================

AbrirConfigCooldown() {
    _GCfg_Abrir(288, 474, _DesenharConfigCooldown)
}

_DesenharConfigCooldown(g, w, h, hoverId) {
    boxes := []
    cfg := GetCfg("Cooldown")

    Gdip_SetClipRoundRect(g, 0, 0, w, h, 14)
    bodyBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG"]))
    Gdip_FillRect(g, bodyBrush, 0, 0, w, h)
    Gdip_DeleteBrush(bodyBrush)

    hH := _GCfg_Header(g, boxes, w, "CONFIG: COOLDOWN", T()["STRIPE2"],
        (*) => ResetarCooldown(),
        (*) => _GCfg_Fechar(),
        hoverId)

    pad  := 14
    colW := (w - pad*2 - 10) // 2
    col2 := pad + colW + 10
    y := hH + 10

    _GCfg_Field(g, boxes, "hkcd", pad, y, colW, "HOTKEY COOLDOWN", _ComboDisplay(cfg["hotkeyCooldown"]),
        (*) => (CapturarTecla("Cooldown", "hotkeyCooldown", 0, "HOTKEY COOLDOWN"), _GCfg_Redraw()), hoverId)
    _GCfg_Field(g, boxes, "pos", col2, y, colW, "POSIÇÃO", "[ " cfg["clickX"] ", " cfg["clickY"] " ]",
        (*) => (CapturarPosicaoMouse("Cooldown", 0), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    _GCfg_Segmented(g, boxes, "pkm", pad, y, w - pad*2, "POKÉMON INICIAL", ["1", "2", "3", "4"],
        cfg["pokemonInicial"], (idx) => SalvarCfg("Cooldown", "pokemonInicial", idx), hoverId)
    y += 44 + 8

    ; ── Tempos de Espera (4 mini-sliders num só cartão) ──
    tempoH := 74
    cardBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG2"]))
    Gdip_FillRoundRect(g, cardBrush, pad, y, w - pad*2, tempoH, 8)
    Gdip_DeleteBrush(cardBrush)
    Gdip_DrawText(g, "TEMPOS DE ESPERA (S)", 9, true, Gdip_Argb(255, T()["MUTED"]), pad + 8, y + 6, w - pad*2 - 16, 14, false)

    slotW := (w - pad*2 - 16) // 4
    Loop 4 {
        idx := A_Index
        sx  := pad + 8 + slotW * (idx - 1)
        _GCfg_MiniSlider(g, boxes, "tempo" idx, sx, y + 24, slotW, "PKM " idx, cfg["tempo" idx],
            0, TEMPO_COOLDOWN_MAX, 1, "s", ((i, v) => SalvarCfg("Cooldown", "tempo" i, v)).Bind(idx), hoverId)
    }
    y += tempoH + 8

    ; ── Tecla (Ctrl+N) enviada em cada posição — permite mapear a ordem
    ; do time no jogo para as posições do Cooldown (ex.: 2º pokémon = Ctrl+4).
    teclaH := 74
    teclaBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG2"]))
    Gdip_FillRoundRect(g, teclaBrush, pad, y, w - pad*2, teclaH, 8)
    Gdip_DeleteBrush(teclaBrush)
    Gdip_DrawText(g, "TECLA CTRL+N POR POSIÇÃO", 9, true, Gdip_Argb(255, T()["MUTED"]), pad + 8, y + 6, w - pad*2 - 16, 14, false)

    teclaSlotW := (w - pad*2 - 16) // 4
    Loop 4 {
        idx := A_Index
        sx  := pad + 8 + teclaSlotW * (idx - 1)
        _GCfg_MiniButton(g, boxes, "tecla" idx, sx, y + 24, teclaSlotW, "PKM " idx, "Ctrl+" cfg["tecla" idx],
            _CiclarTeclaCooldown.Bind(idx), hoverId)
    }
    y += teclaH + 8

    usaFD := cfg["usarFullDefCD"] = "true"
    _GCfg_Toggle(g, boxes, "fd", pad, y, w - pad*2, "FULL DEFENSE (COOLDOWN)", "ATIVAR", "DESATIVAR", usaFD,
        (*) => SalvarCfg("Cooldown", "usarFullDefCD", "true"),
        (*) => SalvarCfg("Cooldown", "usarFullDefCD", "false"), hoverId)
    y += 44 + 8

    _GCfg_ShowInMini(g, boxes, pad, y, w - pad*2, "Cooldown", hoverId)
    y += 44 + 8

    _GCfg_Field(g, boxes, "toggle", pad, y, w - pad*2, "LIGAR/DESLIGAR", _ComboDisplay(cfg["toggleHotkeyCooldown"]),
        (*) => (CapturarCombo("Cooldown", "toggleHotkey", 0, "HOTKEY TOGGLE"), _GCfg_Redraw()), hoverId)

    Gdip_ResetClip(g)
    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, 14)
    Gdip_DeletePen(borderPen)

    return boxes
}

; Avança a tecla (Ctrl+N) da posição idx para o próximo número, voltando
; a 1 depois do máximo — cada clique no botão troca o valor mostrado.
_CiclarTeclaCooldown(idx, *) {
    atual := GetCfg("Cooldown")["tecla" idx]
    novo  := (atual >= TECLA_COOLDOWN_MAX) ? 1 : atual + 1
    SalvarCfg("Cooldown", "tecla" idx, novo)
}

ResetarCooldown() {
    _GCfg_Confirmar(
        "RESETAR COOLDOWN?",
        "Isso limpará hotkey, pokémon, tempos e teclas.",
        (*) => (ResetarSecao("Cooldown"), ShowHint("COOLDOWN RESETADO!", 1000, "success"))
    )
}
