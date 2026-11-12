; =====================================================
; ui\config_rotacao.ahk — Config Rotação (GDI+)
; =====================================================

; Altura: 558 com 2 rotações (2x4); cada rotação a mais soma um cartão
; (124) e um passo de ITEM soma as 2 linhas do elixir/revive (104).
AbrirConfigRotacao() {
    _GCfg_Abrir(288, AlturaConfigRotacao(), _DesenharConfigRotacao)
}

AlturaConfigRotacao() {
    return 558 + (GetFormatoRotacao().rotacoes - 2) * 124 + (RotacaoTemItem() ? 104 : 0)
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
    _GCfg_Field(g, boxes, "reiniciar", pad, y, colW, "TECLA REINICIAR", _ComboDisplay(CfgLer("Rotacao", "teclaReiniciar", "N/A")),
        (*) => (CapturarCombo("Rotacao", "teclaReiniciar", 0, "REINICIAR ROTAÇÃO"), _GCfg_Redraw()), hoverId)
    ; Tecla Pokestop do jogo: global ([Geral]), a mesma da tela de
    ; Configurações Gerais — usada nos passos com STOP ligado.
    _GCfg_Field(g, boxes, "pokestop", col2, y, colW, "TECLA POKESTOP", StrUpper(GetTeclaPokestop()),
        (*) => (CapturarTecla("Geral", "teclaPokestop", 0, "POKESTOP"), _GCfg_Redraw()), hoverId)
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

    ; ── Um cartão por rotação (passos: Ctrl+1..6 ou vazio; embaixo de
    ;    cada passo, o combo solto depois da troca: —, C1 ou C2; e por
    ;    último o Pokestop do passo, liga/desliga) ──
    prox := RotacaoProxima()
    Loop fmt.rotacoes {
        rot := A_Index
        cardH := 116
        cardBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG2"]))
        Gdip_FillRoundRect(g, cardBrush, pad, y, w - pad*2, cardH, 8)
        Gdip_DeleteBrush(cardBrush)
        Gdip_DrawText(g, rot "ª ROTAÇÃO", 9, true, Gdip_Argb(255, T()["MUTED"]), pad + 8, y + 6, w - pad*2 - 16, 14, false)
        _DesenharChipAtualRotacao(g, boxes, rot, prox, w - pad - 8 - 84, y + 5, 84, hoverId)

        slotW := (w - pad*2 - 16) // fmt.passos
        Loop fmt.passos {
            passo := A_Index
            slot  := _CfgSlotRotacao(rot, passo)
            sx    := pad + 8 + slotW * (passo - 1)
            ; o passo que sai no próximo pressionamento ganha contorno na
            ; cor da Rotação (mesma do ícone na HUD)
            ehProx := (prox && prox.rot = rot && prox.passo = passo)
            ; passo de ITEM mostra o que ele faz nesta volta
            txt := (slot = ROTACAO_ITEM) ? (RotacaoVezDoElixir() ? "ELIXIR" : "REVIVE")
                : slot ? "Ctrl+" slot : "—"
            _GCfg_MiniButton(g, boxes, "r" rot "p" passo, sx + 2, y + 24, slotW - 4, passo "º", txt,
                _EscolherSlotRotacao.Bind(rot, passo, { x: sx + 2, y: y + 24 + 15, w: slotW - 4, h: 21 }), hoverId)
            if (ehProx) {
                proxPen := Gdip_Pen(Gdip_Argb(255, ROTACAO_COR), 1.5)
                Gdip_DrawRoundRect(g, proxPen, sx + 2, y + 24 + 15, slotW - 4, 21, 6)
                Gdip_DeletePen(proxPen)
            }
            ; passo vazio ou 1º passo pulado (puxado à mão) nunca é
            ; enviado pelo macro — não tem como soltar combo depois dele
            enviado := slot > 0 && !(passo = 1 && !RotacaoEnviarPrimeiro())
            _DesenharChipComboRotacao(g, boxes, rot, passo, sx + 2, y + 64, slotW - 4, enviado, hoverId)
            _DesenharChipStopRotacao(g, boxes, rot, passo, sx + 2, y + 88, slotW - 4, enviado, hoverId)
        }
        y += cardH + 8
    }

    ; ── Passo de ITEM: elixir nas voltas ímpares (na tecla do combo, no
    ;    pokémon antes do ITEM), revive nas pares (na tecla da Rotação).
    ;    Cada um MACRO ou MÃO (o macro pula aquela volta). ──
    if RotacaoTemItem() {
        ; Aceita Ctrl/Alt/Shift e botão direito (comMods): é comum o
        ; elixir estar num atalho como Ctrl + botão do mouse no jogo.
        _GCfg_Field(g, boxes, "elixir", pad, y, colW, "TECLA ELIXIR", _ComboDisplay(CfgLer("Rotacao", "teclaElixir", "N/A")),
            (*) => (CapturarTecla("Rotacao", "teclaElixir", 0, "ELIXIR DE ATAQUE", true), _GCfg_Redraw()), hoverId)
        _GCfg_Toggle(g, boxes, "elixirModo", col2, y, colW, "ELIXIR", "MACRO", "MÃO", RotacaoElixirPeloMacro(),
            (*) => SalvarCfg("Rotacao", "elixirModo", "macro"),
            (*) => SalvarCfg("Rotacao", "elixirModo", "mao"), hoverId)
        y += 44 + 8
        ; O revive usa tudo da tela do Revive (posição, hotkey, delay) —
        ; aqui só se o macro faz ou não. Muda quais passos a tecla da
        ; Rotação pula — o próximo da HUD pode mudar.
        _GCfg_Toggle(g, boxes, "reviveModo", pad, y, w - pad*2, "REVIVE (USA A CONFIG DO MACRO REVIVE)", "MACRO", "MÃO", RotacaoRevivePeloMacro(),
            (*) => (SalvarCfg("Rotacao", "reviveModo", "macro"), _HudRedraw()),
            (*) => (SalvarCfg("Rotacao", "reviveModo", "mao"), _HudRedraw()), hoverId)
        y += 44 + 8
    }

    ; Só pesa nos passos com combo marcado: tempo para o pokémon sair da
    ; pokébola antes do 1º botão do combo.
    y += _GCfg_Slider(g, boxes, "delay", pad, y, w - pad*2, "ESPERA ANTES DO COMBO", GetDelayComboRotacao(),
        0, DELAY_COMBO_ROTACAO_MAX, 10, "ms", (v) => SalvarCfg("Rotacao", "delayCombo", v), hoverId) + 8

    _GCfg_ShowInMini(g, boxes, pad, y, w - pad*2, "Rotacao", hoverId)

    Gdip_ResetClip(g)
    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, 14)
    Gdip_DeletePen(borderPen)

    return boxes
}

; Chip "combo depois da troca" sob o botão do passo: "—" (nenhum),
; "COMBO 1" ou "COMBO 2" (na cor da Rotação quando marcado). Passo que o
; macro não envia ('ativo' = false) fica com o chip apagado e sem clique.
_DesenharChipComboRotacao(g, boxes, rot, passo, x, y, w, ativo, hoverId) {
    static NOMES := ["COMBO 1", "COMBO 2"]
    h := 20
    id := "c" rot "p" passo
    combo := _CfgComboRotacao(rot, passo)
    hov := ativo && (hoverId = id)

    br := Gdip_BrushSolid(Gdip_Argb(ativo ? 255 : 110, hov ? T()["BG3"] : T()["BG"]))
    Gdip_FillRoundRect(g, br, x, y, w, h, 6)
    Gdip_DeleteBrush(br)
    if (ativo && combo) {
        pen := Gdip_Pen(Gdip_Argb(150, ROTACAO_COR), 1)
        Gdip_DrawRoundRect(g, pen, x, y, w, h, 6)
        Gdip_DeletePen(pen)
    }

    txt := combo ? NOMES[combo] : "—"
    cor := !ativo ? Gdip_Argb(90, T()["MUTED"])
        : hov ? Gdip_Argb(255, T()["ACCENT"])
        : combo ? Gdip_Argb(255, ROTACAO_COR)
        : Gdip_Argb(255, T()["MUTED"])
    Gdip_DrawText(g, txt, 8, true, cor, x, y, w, h, true)

    if (ativo)
        boxes.Push({ id: id, x: x, y: y, w: w, h: h,
            onClick: _EscolherComboRotacao.Bind(rot, passo, { x: x, y: y, w: w, h: h }) })
}

; Chip "Pokestop" sob o do combo: clicar liga/desliga. Ligado mostra
; "STOP" na cor da Rotação, com contorno; desligado, "SEM STOP" apagado.
; Passo que o macro não envia fica apagado e sem clique, como o do combo.
_DesenharChipStopRotacao(g, boxes, rot, passo, x, y, w, ativo, hoverId) {
    h := 20
    id := "s" rot "p" passo
    stop := _CfgPokestopRotacao(rot, passo)
    hov := ativo && (hoverId = id)

    br := Gdip_BrushSolid(Gdip_Argb(ativo ? 255 : 110, hov ? T()["BG3"] : T()["BG"]))
    Gdip_FillRoundRect(g, br, x, y, w, h, 6)
    Gdip_DeleteBrush(br)
    if (ativo && stop) {
        pen := Gdip_Pen(Gdip_Argb(150, ROTACAO_COR), 1)
        Gdip_DrawRoundRect(g, pen, x, y, w, h, 6)
        Gdip_DeletePen(pen)
    }

    cor := !ativo ? Gdip_Argb(90, T()["MUTED"])
        : hov ? Gdip_Argb(255, T()["ACCENT"])
        : stop ? Gdip_Argb(255, ROTACAO_COR)
        : Gdip_Argb(255, T()["MUTED"])
    Gdip_DrawText(g, stop ? "STOP" : "SEM STOP", 8, true, cor, x, y, w, h, true)

    ; Não mexe na ordem da sequência, então não reinicia a rotação.
    if (ativo)
        boxes.Push({ id: id, x: x, y: y, w: w, h: h,
            onClick: (*) => SalvarCfg("Rotacao", _ChaveSlotRotacao(rot, passo) "s", stop ? "false" : "true") })
}

; Chip no canto do cartão: a rotação do próximo aperto mostra "ATUAL" (na
; cor da Rotação, sem clique); as outras, "COMEÇAR AQUI" — leva a posição
; ao 1º passo dela (RotacaoIrPara), para quando uma rotação foi feita à
; mão. Rotação sem passo enviado fica sem chip.
; Rotação com passo de ITEM: o clique abre ELIXIR/REVIVE para escolher
; também a vez — e aí até o "ATUAL" é clicável (troca só a vez).
_DesenharChipAtualRotacao(g, boxes, rot, prox, x, y, w, hoverId) {
    static h := 16
    atual := prox && prox.rot = rot
    temPasso := false
    for e in RotacaoSequencia()
        if (e.rot = rot)
            temPasso := true
    if (!temPasso)
        return
    temItem := RotacaoTemItemNa(rot)
    clicavel := !atual || temItem
    id := "atual" rot
    hov := clicavel && hoverId = id

    br := Gdip_BrushSolid(Gdip_Argb(255, hov ? T()["BG3"] : T()["BG"]))
    Gdip_FillRoundRect(g, br, x, y, w, h, 5)
    Gdip_DeleteBrush(br)
    if (atual) {
        pen := Gdip_Pen(Gdip_Argb(150, ROTACAO_COR), 1)
        Gdip_DrawRoundRect(g, pen, x, y, w, h, 5)
        Gdip_DeletePen(pen)
    }
    cor := hov ? Gdip_Argb(255, T()["ACCENT"]) : atual ? Gdip_Argb(255, ROTACAO_COR) : Gdip_Argb(255, T()["MUTED"])
    Gdip_DrawText(g, atual ? "ATUAL" : "COMEÇAR AQUI", 7.5, true, cor, x, y, w, h, true)

    if (!clicavel)
        return
    if (temItem)
        onClick := (*) => _GCfg_AbrirSeletor({ x: x, y: y, w: w, h: h },
            atual ? "VEZ DO E/R NESTA VOLTA" : "COMEÇAR NA " rot "ª ROTAÇÃO COM",
            ["ELIXIR", "REVIVE"], RotacaoVezDoElixir() ? 1 : 2,
            _ComecarRotacaoComVez.Bind(rot, atual), 58)
    else
        onClick := (*) => (RotacaoIrPara(rot), ShowHint("ROTAÇÃO: começando na " rot "ª rotação", 1200, "info"))
    boxes.Push({ id: id, x: x, y: y, w: w, h: h, onClick: onClick })
}

; Escolha do seletor do chip (1 = ELIXIR, 2 = REVIVE). No "ATUAL" só a
; vez muda — a posição fica onde está.
_ComecarRotacaoComVez(rot, soVez, idx) {
    if (!soVez)
        RotacaoIrPara(rot)
    RotacaoDefinirVez(idx = 1)
    vez := (idx = 1) ? "ELIXIR" : "REVIVE"
    ShowHint(soVez ? "ROTAÇÃO: vez do " vez : "ROTAÇÃO: começando na " rot "ª rotação (" vez ")", 1400, "info")
}

_EscolherComboRotacao(rot, passo, ancora, *) {
    atual := _CfgComboRotacao(rot, passo)
    _GCfg_AbrirSeletor(ancora, "SOLTAR COMBO", ["—", "C1", "C2"],
        atual + 1, _DefinirComboRotacao.Bind(rot, passo))
}

; idx do seletor: 1 = nenhum, 2 = Combo 1, 3 = Combo 2. Não mexe na
; ordem da sequência, então não reinicia a rotação.
_DefinirComboRotacao(rot, passo, idx) {
    SalvarCfg("Rotacao", _ChaveSlotRotacao(rot, passo) "c", idx - 1)
}

; Clicar num passo abre o seletor (Ctrl+1..6, E/R = passo de ITEM — só do
; 2º passo em diante — ou — vazio) logo abaixo do botão; 'ancora' é o
; retângulo do botão, para o painel se posicionar.
_EscolherSlotRotacao(rot, passo, ancora, *) {
    opcoes := []
    Loop TECLA_POKEMON_MAX
        opcoes.Push(String(A_Index))
    if (passo > 1)
        opcoes.Push("E/R")
    opcoes.Push("—")
    atual := _CfgSlotRotacao(rot, passo)
    titulo := (passo > 1) ? passo "º PASSO: CTRL + N, OU E/R = ELIXIR/REVIVE" : "POKÉMON DO " passo "º PASSO (CTRL + N)"
    _GCfg_AbrirSeletor(ancora, titulo, opcoes,
        atual ? atual : opcoes.Length, _DefinirSlotRotacao.Bind(rot, passo, opcoes))
}

; Grava o escolhido: 1..6, "item" (E/R) ou 0 (o último, vazio).
; Mexer na sequência reinicia a rotação, senão a posição atual apontaria
; para um passo diferente do que o jogador tinha em mente. Ganhar ou
; perder o passo de ITEM muda a altura da tela — reabre (ver
; _TrocarFormatoRotacao).
_DefinirSlotRotacao(rot, passo, opcoes, idx) {
    tinhaItem := RotacaoTemItem()
    valor := (idx <= TECLA_POKEMON_MAX) ? idx : (opcoes[idx] = "E/R") ? "item" : 0
    SalvarCfg("Rotacao", _ChaveSlotRotacao(rot, passo), valor)
    ReiniciarRotacao()
    if (RotacaoTemItem() != tinhaItem)
        SetTimer(AbrirConfigRotacao, -1)
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
