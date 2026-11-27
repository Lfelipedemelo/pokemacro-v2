; =====================================================
; macros\combo.ahk — Execução dos macros de Combo
; =====================================================
;
; Lê duas configurações de [Geral] no INI:
;   sleepCombo   → tempo de espera entre cada tecla (padrão 450ms, de 300 a 1000ms)
;   usarPrefixoF → "true"  → envia {F1}, {F2} ...
;                  "false" → envia {1},  {2}  ...

ExecutarCombo(tipo) {
    global macros

    if !macros[tipo]
        return

    ; Na vez do elixir da Rotação (passo de ITEM), usa o elixir antes das
    ; skills — ver RotacaoUsarElixir.
    gen := InterromperCombo()
    if RotacaoUsarElixir(gen)
        if !_RodarSequenciaCombo(GetCfg(tipo), gen, 0, _CfgStunCombo(tipo))   ; stun da tela do combo
            AvisarBotoesCombo(tipo)
}

; Combo sem Botão Inicial/Final utilizável (vazio, sem número, ou o
; inicial depois do final): sem o aviso, a tecla do combo simplesmente
; não fazia nada.
AvisarBotoesCombo(secao) {
    global MACROS_INFO
    ShowHint(MACROS_INFO[secao].label ": configure os botões INICIAL e FINAL", 1800, "danger")
}

; ─── Interrupção de combo por "geração" ──────────────────
; Cada combo guarda a geração em que começou e para assim que ela muda.
; InterromperCombo() avança a geração (para o combo em andamento) e
; devolve a nova, que o chamador usa se for rodar o próprio combo.
;
; Antes era uma flag booleana consumida por quem a lesse — quebrava
; quando quem interrompe também roda um combo (Rotação): a thread nova
; do AHK suspende a antiga até terminar, então a nova zerava a flag ao
; começar e, ao acabar, o combo antigo voltava e soltava o resto das
; teclas. Com a geração, o antigo vê que ficou para trás e para.
global _comboGeracao := 0

InterromperCombo() {
    global _comboGeracao
    return ++_comboGeracao
}

; Sequência de combo compartilhada pelos combos Principal/Secundário,
; pelo Combo Revive e pela Rotação: Full Attack (opcional) → teclas de
; teclaInicial até teclaFinal → Full Defense (opcional). Para se o combo
; for interrompido (revive, rotação, macro desligado, pânico) ou se o
; jogo perder o foco. 'gen' é a geração devolvida por InterromperCombo()
; ao começar. Devolve false se o combo não tem botões configurados.
; 'pausa' ({ tecla, ms }, só no combo pós-troca da Rotação — ver
; _CfgPausaRotacao): depois da tecla 'tecla', em vez do delay normal
; espera 'ms' com a contagem na tela (_EsperarPausaCombo). Ignorada se a
; tecla não estiver entre a inicial e a penúltima do combo.
; 'stun' (nº da tecla, 0 = nenhuma): ao enviar essa tecla, começa (ou
; recomeça) a contagem do stun — ver StunIniciar.
_RodarSequenciaCombo(cfg, gen, pausa := 0, stun := 0) {
    sleepMs := GetSleepCombo()
    usarF   := GetUsarPrefixoF()

    try {
        numInicial := Integer(RegExReplace(cfg["teclaInicial"], "\D", ""))
        numFinal   := Integer(RegExReplace(cfg["teclaFinal"],   "\D", ""))
    } catch {
        return false
    }
    ; Inicial depois da final: o loop não soltaria nenhuma tecla — conta
    ; como combo sem botões (quem chama avisa), sem soltar o Full Attack.
    if (numFinal < numInicial)
        return false

    if (cfg["usarFullAtk"] = "true" && cfg["fullAttack"] != "N/A") {
        SendEvent("{" cfg["fullAttack"] "}")
        if !EsperarInterrompivel(20, gen)
            return true
    }

    Loop (numFinal - numInicial + 1) {
        if !_ComboPodeContinuar(gen)
            return true

        numTecla := numInicial + A_Index - 1
        SendEvent((usarF = "true") ? "{F" numTecla "}" : "{" numTecla "}")
        if (stun && stun = numTecla)
            StunIniciar()

        ; A pausa substitui o delay: o tempo da skill responder já está
        ; dentro dela, e assim o configurado é o tempo para mover.
        if (pausa && pausa.tecla = numTecla && numTecla < numFinal) {
            if !_EsperarPausaCombo(pausa.ms, gen)
                return true
        } else if !EsperarInterrompivel(sleepMs, gen)
            return true
    }

    ; Espera interrompível: com Sleep puro, um alt-tab nesses 200ms mandava
    ; o Full Defense para a outra janela.
    if (cfg["usarFullDef"] = "true" && cfg["fullDefense"] != "N/A") {
        if !EsperarInterrompivel(200, gen)
            return true
        SendEvent("{" cfg["fullDefense"] "}")
    }
    return true
}

; Pausa no meio do combo: espera 'ms' como EsperarInterrompivel, mas com
; a contagem "pausa" mostrando o tempo que falta ("1,4s") — no lugar e no
; tamanho escolhidos na tela da Rotação —, atualizada a cada ~100ms.
; Interrompida (Rotação apertada de novo, pânico, jogo sem foco) ou no
; fim, a contagem some. Devolve false se foi interrompida.
_EsperarPausaCombo(ms, gen) {
    fim := A_TickCount + ms
    seq := 0
    try {
        Loop {
            resta := fim - A_TickCount
            if (resta <= 0)
                return true
            seq := MostrarContador("pausa", resta, resta + 500)
            if !EsperarInterrompivel(Min(resta, 100), gen)
                return false
        }
    } finally {
        if (seq)
            FecharContador("pausa", seq)
    }
}

; ─── Contagem do stun ────────────────────────────────────
; Ao enviar a tecla de stun do combo (ver _CfgStunCombo/_CfgStunRotacao),
; conta STUN_MS na tela (contagem "stun", vermelha nos últimos 2 s) — o
; tempo que o alvo fica parado para o jogador trocar de pokémon e agir.
; Roda num timer, à parte do combo: continua com o combo interrompido, a
; troca de pokémon ou o jogo sem foco. Enviar a tecla de novo (qualquer
; combo) recomeça; só a tecla de pânico para antes do fim (StunParar).
global STUN_MS := 6000
global _stunFim := 0

StunIniciar() {
    global _stunFim
    _stunFim := A_TickCount + STUN_MS
    _StunTick()
    SetTimer(_StunTick, 100)
}

_StunTick() {
    global _stunFim
    resta := _stunFim - A_TickCount
    if (resta <= 0) {
        StunParar()
        return
    }
    MostrarContador("stun", resta, resta + 500, resta <= 2000)
}

StunParar() {
    global _stunFim
    SetTimer(_StunTick, 0)
    _stunFim := 0
    FecharContador("stun")
}

; false se o combo da geração 'gen' deve parar (foi interrompido — a
; geração avançou — ou o jogo perdeu o foco).
_ComboPodeContinuar(gen) {
    global _comboGeracao
    return (gen = _comboGeracao) && JogoAtivo()
}

; Espera 'ms' com precisão (prazo por A_TickCount, não soma de Sleeps —
; cada Sleep arredonda para cima, e antes 550ms viravam ~640ms reais),
; checando interrupção a cada ~10ms. Devolve false se foi interrompido.
EsperarInterrompivel(ms, gen) {
    fim := A_TickCount + ms
    Loop {
        if !_ComboPodeContinuar(gen)
            return false
        resta := fim - A_TickCount
        if (resta <= 0)
            return true
        Sleep(Min(resta, 10))
    }
}
