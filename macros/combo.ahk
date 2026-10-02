; =====================================================
; macros\combo.ahk — Execução dos macros de Combo
; =====================================================
;
; Lê duas configurações de [Geral] no INI:
;   sleepCombo   → tempo de espera entre cada tecla (padrão 550ms)
;   usarPrefixoF → "true"  → envia {F1}, {F2} ...
;                  "false" → envia {1},  {2}  ...

ExecutarCombo(tipo) {
    global macros

    if !macros[tipo]
        return

    _RodarSequenciaCombo(GetCfg(tipo), InterromperCombo())
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
_RodarSequenciaCombo(cfg, gen) {
    sleepMs := GetSleepCombo()
    usarF   := GetUsarPrefixoF()

    try {
        numInicial := Integer(RegExReplace(cfg["teclaInicial"], "\D", ""))
        numFinal   := Integer(RegExReplace(cfg["teclaFinal"],   "\D", ""))
    } catch {
        return false
    }

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

        if !EsperarInterrompivel(sleepMs, gen)
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
