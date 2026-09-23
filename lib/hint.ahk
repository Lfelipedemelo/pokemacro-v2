; =====================================================
; lib\hint.ahk — Banner de notificação (GDI+, tema do app)
; =====================================================
;
; Mesma técnica da HUD/telas de configuração (ui\mini_menu.ahk,
; lib\gdip_config.ahk): janela em camadas desenhada do zero a cada
; chamada com GDI+ — cantos arredondados de verdade e paleta igual
; ao resto do app (lib\globals.ahk → T()), em vez da antiga caixa
; com Gui nativa (cantos quadrados, cores fixas fora do tema atual).
;
; API pública:
;   ShowHint(text, time := 1200, kind := "info")
;     kind define a cor de destaque e o ícone:
;       "info"    — azul   (T().STRIPE3) — instruções/estado neutro
;       "success" — verde  (T().ACCENT)  — algo foi salvo/ativado
;       "warn"    — amarelo(T().STRIPE2) — cancelado/nada capturado
;       "danger"  — vermelho(T().DANGER) — erro/pré-requisito faltando

global _hintGui := 0
global _hintTmr := 0

_HintPaleta(kind) {
    switch kind {
        case "success": return Map("cor", T()["ACCENT"],  "glifo", "✓")
        case "warn":    return Map("cor", T()["STRIPE2"], "glifo", "!")
        case "danger":  return Map("cor", T()["DANGER"],  "glifo", "✕")
        default:        return Map("cor", T()["STRIPE3"], "glifo", "i")
    }
}

ShowHint(text, time := 1200, kind := "info") {
    global _hintGui, _hintTmr

    if (_hintTmr) {
        SetTimer(_hintTmr, 0)
        _hintTmr := 0
    }
    if IsObject(_hintGui) {
        try _hintGui.Destroy()
        _hintGui := 0
    }
    if (text = "")
        return

    Gdip_EnsureStarted()
    pal := _HintPaleta(kind)

    PAD := 24, ICON_D := 44, GAP := 18
    fontSz := 15
    radius := 16

    sz   := Gdip_MeasureText(text, fontSz, true, 720)
    txtW := Ceil(sz[1]) + 2
    txtH := Ceil(sz[2])

    h := PAD + Max(ICON_D, txtH) + PAD
    w := PAD + ICON_D + GAP + txtW + PAD

    x := (A_ScreenWidth  - w) // 2
    y := (A_ScreenHeight - h) // 2

    ; E0x20 (transparente ao mouse) + E0x08000000 (não ativa): o aviso
    ; aparece no meio da tela durante o jogo — não pode tirar o foco dele
    ; nem engolir cliques.
    _hintGui := Gui("-Caption +ToolWindow +AlwaysOnTop +E0x80000 +E0x20 +E0x08000000")
    _hintGui.Show("x" x " y" y " w10 h10 NoActivate Hide")
    Win_MostrarSemAtivar(_hintGui.Hwnd)

    canvas := Gdip_NewLayeredCanvas(w, h)
    g := canvas.pGraphics

    ; fundo + borda (mesma receita do painel da HUD/config)
    bgBrush := Gdip_BrushSolid(Gdip_Argb(245, T()["BG"]))
    Gdip_FillRoundRect(g, bgBrush, 0, 0, w, h, radius)
    Gdip_DeleteBrush(bgBrush)

    ; faixa colorida no topo, recortada aos cantos arredondados —
    ; mesma ideia da faixa do cabeçalho das telas de config.
    Gdip_SetClipRoundRect(g, 0, 0, w, h, radius)
    stripeBrush := Gdip_BrushSolid(Gdip_Argb(255, pal["cor"]))
    Gdip_FillRect(g, stripeBrush, 0, 0, w, 4)
    Gdip_DeleteBrush(stripeBrush)
    Gdip_ResetClip(g)

    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1.4)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, radius)
    Gdip_DeletePen(borderPen)

    ; ícone (badge circular colorido por tipo)
    icCx := PAD + ICON_D / 2
    icCy := h / 2

    icBg := Gdip_BrushSolid(Gdip_Argb(46, pal["cor"]))
    Gdip_FillEllipse(g, icBg, icCx - ICON_D / 2, icCy - ICON_D / 2, ICON_D, ICON_D)
    Gdip_DeleteBrush(icBg)

    icRing := Gdip_Pen(Gdip_Argb(255, pal["cor"]), 1.8)
    Gdip_DrawEllipse(g, icRing, icCx - ICON_D / 2, icCy - ICON_D / 2, ICON_D, ICON_D)
    Gdip_DeletePen(icRing)

    Gdip_DrawText(g, pal["glifo"], 18, true, Gdip_Argb(255, pal["cor"]),
        icCx - ICON_D / 2, icCy - ICON_D / 2, ICON_D, ICON_D, true)

    ; texto
    txtX := PAD + ICON_D + GAP
    Gdip_DrawText(g, text, fontSz, true, Gdip_Argb(255, T()["TEXT"]), txtX, 0, txtW, h, false)

    Gdip_PresentLayeredCanvas(canvas, _hintGui.Hwnd, x, y)
    Gdip_DestroyLayeredCanvas(canvas)

    janela := _hintGui
    _hintTmr := _HintFechar.Bind(janela)
    SetTimer(_hintTmr, -time)
}

_HintFechar(janela) {
    global _hintGui, _hintTmr
    if (_hintGui = janela) {
        try _hintGui.Destroy()
        _hintGui := 0
    }
    _hintTmr := 0
}
