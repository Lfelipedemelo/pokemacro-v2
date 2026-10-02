; =====================================================
; macros\rotacao.ahk — Execução do macro de Rotação
; =====================================================
;
; Uma tecla só que vai trocando de pokémon numa ordem salva: cada
; pressionamento envia o Ctrl+N do passo atual e avança para o próximo.
; A sequência é uma rotação após a outra (passos vazios são pulados) e
; volta ao começo depois do último passo — ex.: 1-2-3-4 | 1-2-5-6 (2x4)
; ou 1-2-3 | 1-4-5 | 1-—-6 (3x3).
; A HUD mostra no ícone qual Ctrl+N sai no próximo pressionamento.
; Cada pressionamento também interrompe o combo em andamento e, se o
; passo tiver um combo marcado (Combo 1/2), solta esse combo logo depois
; da troca.

global _rotacaoPos := 1   ; índice, na sequência, do próximo passo a enviar
global _rotacaoComboPendente := 0   ; { combo, gen } a soltar pelo timer (ver _RodarComboRotacao) ou 0

; Sequência completa (todas as rotações, em ordem), sem os passos vazios.
; Formato 2x4 (2 rotações de 4) ou 3x3 (3 de 3) — ver GetFormatoRotacao.
; Cada item: { slot: N do Ctrl+N, rot: 1..3, passo: 1..4, combo: 0..2 }.
; Com "1º POKÉMON = PULAR" (padrão) o 1º passo de CADA rotação
; fica de fora: o jogador puxa esse pokémon à mão no começo de toda
; rotação, então o macro só chama do 2º em diante — ex.: 2-3-4 | 2-5-6.
RotacaoSequencia() {
    pularPrimeiro := !RotacaoEnviarPrimeiro()
    fmt := GetFormatoRotacao()
    seq := []
    Loop fmt.rotacoes {
        rot := A_Index
        Loop fmt.passos {
            if (pularPrimeiro && A_Index = 1)
                continue
            slot := _CfgSlotRotacao(rot, A_Index)
            if (slot > 0)
                seq.Push({ slot: slot, rot: rot, passo: A_Index, combo: _CfgComboRotacao(rot, A_Index) })
        }
    }
    return seq
}

RotacaoEnviarPrimeiro() {
    return CfgLer("Rotacao", "enviarPrimeiro", "false") = "true"
}

; Próximo passo que será enviado, ou 0 se não houver nenhum configurado.
; A sequência pode ter encolhido desde o último envio (config editada),
; então a posição é reduzida à faixa válida aqui em vez de confiar nela.
RotacaoProxima() {
    global _rotacaoPos
    seq := RotacaoSequencia()
    if !seq.Length
        return 0
    if (_rotacaoPos > seq.Length || _rotacaoPos < 1)
        _rotacaoPos := 1
    return seq[_rotacaoPos]
}

ExecutarRotacao() {
    global _rotacaoPos, _rotacaoComboPendente
    prox := RotacaoProxima()
    if !prox {
        ShowHint("ROTAÇÃO: nenhum pokémon configurado", 1600, "danger")
        return
    }
    ; Para o combo que estiver rodando (inclusive o pós-troca de um
    ; aperto anterior): sem isso as skills restantes — e o Full Defense —
    ; sairiam no pokémon que acabou de entrar.
    gen := InterromperCombo()
    SendEvent("^" prox.slot)
    _rotacaoPos := Mod(_rotacaoPos, RotacaoSequencia().Length) + 1
    _HudRedraw()

    ; O combo pós-troca roda num timer, não nesta thread de hotkey: com
    ; #MaxThreadsPerHotkey 2, apertos rápidos durante o combo seriam
    ; descartados. Um timer ainda rodando (suspenso por esta thread) vê a
    ; geração mudar, sai, e o timer dispara de novo com o pendente novo.
    _rotacaoComboPendente := prox.combo ? { combo: prox.combo, gen: gen } : 0
    if prox.combo
        SetTimer(_RodarComboRotacao, -1)
}

; Espera o pokémon sair (GetDelayComboRotacao) e solta o Combo 1
; (Principal) ou 2 (Secundário) com os botões configurados nele — não
; precisa que aquele combo esteja ligado na HUD.
; Conta como combo em andamento (_macroExecutando): as teclas dos combos
; Principal/Secundário são ignoradas enquanto ele roda, como em qualquer
; combo; a da Rotação (interrompível) continua valendo.
_RodarComboRotacao() {
    global _rotacaoComboPendente, COMBOS_ROTACAO, MACROS_INFO, _macroExecutando
    p := _rotacaoComboPendente
    _rotacaoComboPendente := 0
    if !p
        return
    _macroExecutando := true
    try {
        if !EsperarInterrompivel(GetDelayComboRotacao(), p.gen)
            return
        secao := COMBOS_ROTACAO[p.combo]
        if !_RodarSequenciaCombo(GetCfg(secao), p.gen)
            ShowHint("ROTAÇÃO: configure os botões do " MACROS_INFO[secao].label, 1800, "danger")
    } finally {
        _macroExecutando := false
    }
}

; Volta ao início da rotação. Chamado ao ligar o macro, pela tecla de
; reiniciar e quando a config é editada.
ReiniciarRotacao(avisar := false) {
    global _rotacaoPos
    _rotacaoPos := 1
    _HudRedraw()
    if (avisar && (prox := RotacaoProxima()))
        ShowHint("ROTAÇÃO REINICIADA — próximo: Ctrl+" prox.slot, 1200, "info")
}
