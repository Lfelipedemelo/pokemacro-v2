; =====================================================
; ui\config_rotacao.ahk — Config Rotação (GDI+)
; =====================================================

; Altura: 422 com 2 rotações (2x4); cada rotação a mais soma um cartão (82).
AbrirConfigRotacao() {
    _GCfg_Abrir(288, AlturaConfigRotacao(), _DesenharConfigRotacao)
}

AlturaConfigRotacao() {
    return 422 + (GetFormatoRotacao().rotacoes - 2) * 82
}

_DesenharConfigRotacao(g, w, h, hoverId) {
    boxes := []

    Gdip_SetClipRoundRect(g, 0, 0, w, h, 14)
    bodyBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG"]))
    Gdip_FillRect(g, bodyBrush, 0, 0, w, h)
    Gdip_DeleteBrush(bodyBrush)

    hH := _GCfg_Header(g, boxes, w, "CONFIG: ROTAÇÃO", ROTACAO_COR,
        (*) => ResetarRotacao(),
        (*) => _GCfg_Fechar(),
        hoverId)

    pad  := 14
    colW := (w - pad*2 - 10) // 2
    col2 := pad + colW + 10
    y := hH + 10

    _GCfg_Field(g, boxes, "hkmacro", pad, y, colW, "TECLA MACRO", _ComboDisplay(CfgLer("Rotacao", "teclaHotkey", "N/A")),
        (*) => (CapturarTecla("Rotacao", "teclaHotkey", 0, "TECLA ROTAÇÃO"), _GCfg_Redraw()), hoverId)
    _GCfg_Field(g, boxes, "toggle", col2, y, colW, "LIGAR/DESLIGAR", _ComboDisplay(CfgLer("Rotacao", "toggleHotkey", "N/A")),
        (*) => (CapturarCombo("Rotacao", "toggleHotkey", 0, "HOTKEY TOGGLE"), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    ; Volta ao início da rotação no meio do jogo (ex.: se a ordem real
    ; dos pokémons saiu do compasso da HUD).
    _GCfg_Field(g, boxes, "reiniciar", pad, y, w - pad*2, "TECLA REINICIAR ROTAÇÃO", _ComboDisplay(CfgLer("Rotacao", "teclaReiniciar", "N/A")),
        (*) => (CapturarCombo("Rotacao", "teclaReiniciar", 0, "REINICIAR ROTAÇÃO"), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    ; Formato: 2 rotações de 4 pokémons ou 3 de 3. Muda a quantidade de
    ; cartões — a janela é reaberta com a altura nova (ver
    ; _TrocarFormatoRotacao).
    fmt := GetFormatoRotacao()
    _GCfg_Toggle(g, boxes, "formato", pad, y, colW, "ROTAÇÕES", "2 × 4", "3 × 3", fmt.modo = "2x4",
        (*) => _TrocarFormatoRotacao("2x4"),
        (*) => _TrocarFormatoRotacao("3x3"), hoverId)

    ; O 1º pokémon de cada rotação normalmente é puxado à mão — por
    ; padrão o 1º passo de todas as rotações fica fora da sequência (ver
    ; RotacaoSequencia).
    _GCfg_Toggle(g, boxes, "primeiro", col2, y, colW, "1º POKÉMON", "PULAR", "SOLTAR",
        !RotacaoEnviarPrimeiro(),
        (*) => (SalvarCfg("Rotacao", "enviarPrimeiro", "false"), ReiniciarRotacao()),
        (*) => (SalvarCfg("Rotacao", "enviarPrimeiro", "true"),  ReiniciarRotacao()), hoverId)
    y += 44 + 8

    ; ── Um cartão por rotação (passos: Ctrl+1..6 ou vazio) ──
    prox := RotacaoProxima()
    Loop fmt.rotacoes {
        rot := A_Index
        cardH := 74
        cardBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG2"]))
        Gdip_FillRoundRect(g, cardBrush, pad, y, w - pad*2, cardH, 8)
        Gdip_DeleteBrush(cardBrush)
        Gdip_DrawText(g, rot "ª ROTAÇÃO", 9, true, Gdip_Argb(255, T()["MUTED"]), pad + 8, y + 6, w - pad*2 - 16, 14, false)

        slotW := (w - pad*2 - 16) // fmt.passos
        Loop fmt.passos {
            passo := A_Index
            slot  := _CfgSlotRotacao(rot, passo)
            sx    := pad + 8 + slotW * (passo - 1)
            ; o passo que sai no próximo pressionamento ganha contorno na
            ; cor da Rotação (mesma do ícone na HUD)
            ehProx := (prox && prox.rot = rot && prox.passo = passo)
            _GCfg_MiniButton(g, boxes, "r" rot "p" passo, sx + 2, y + 24, slotW - 4, passo "º",
                slot ? "Ctrl+" slot : "—",
                _EscolherSlotRotacao.Bind(rot, passo, { x: sx + 2, y: y + 24 + 15, w: slotW - 4, h: 21 }), hoverId)
            if (ehProx) {
                proxPen := Gdip_Pen(Gdip_Argb(255, ROTACAO_COR), 1.5)
                Gdip_DrawRoundRect(g, proxPen, sx + 2, y + 24 + 15, slotW - 4, 21, 6)
                Gdip_DeletePen(proxPen)
            }
        }
        y += cardH + 8
    }

    _GCfg_ShowInMini(g, boxes, pad, y, w - pad*2, "Rotacao", hoverId)

    Gdip_ResetClip(g)
    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, 14)
    Gdip_DeletePen(borderPen)

    return boxes
}

; Clicar num passo abre o seletor (Ctrl+1..6 ou — vazio) logo abaixo do
; botão; 'ancora' é o retângulo do botão, para o painel se posicionar.
_EscolherSlotRotacao(rot, passo, ancora, *) {
    opcoes := []
    Loop TECLA_POKEMON_MAX
        opcoes.Push(String(A_Index))
    opcoes.Push("—")
    atual := _CfgSlotRotacao(rot, passo)
    _GCfg_AbrirSeletor(ancora, "POKÉMON DO " passo "º PASSO (CTRL + N)", opcoes,
        atual ? atual : opcoes.Length, _DefinirSlotRotacao.Bind(rot, passo))
}

; Grava o pokémon escolhido (o último item do seletor é o vazio, 0).
; Mexer na sequência reinicia a rotação, senão a posição atual apontaria
; para um passo diferente do que o jogador tinha em mente.
_DefinirSlotRotacao(rot, passo, idx) {
    SalvarCfg("Rotacao", _ChaveSlotRotacao(rot, passo), (idx > TECLA_POKEMON_MAX) ? 0 : idx)
    ReiniciarRotacao()
}

; Troca o formato e reabre a tela: a altura depende do nº de rotações.
; Reaberta fora do handler do clique (SetTimer) — destruir a janela de
; dentro do próprio despacho de mensagens dela dá erro de reentrância.
_TrocarFormatoRotacao(modo) {
    if (GetFormatoRotacao().modo = modo)
        return
    SalvarCfg("Rotacao", "formato", modo)
    ReiniciarRotacao()
    SetTimer(AbrirConfigRotacao, -1)
}

ResetarRotacao() {
    _GCfg_Confirmar(
        "RESETAR ROTAÇÃO?",
        "Isso limpará as teclas e voltará às rotações padrão.",
        ; o reset volta ao formato 2x4 — reabre para a altura acompanhar
        (*) => (ResetarSecao("Rotacao"), ReiniciarRotacao(), SetTimer(AbrirConfigRotacao, -1), ShowHint("ROTAÇÃO RESETADA!", 1000, "success"))
    )
}
