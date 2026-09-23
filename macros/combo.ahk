; =====================================================
; macros\combo.ahk — Execução dos macros de Combo
; =====================================================
;
; Lê duas configurações de [Geral] no INI:
;   sleepCombo   → tempo de espera entre cada tecla (padrão 550ms)
;   usarPrefixoF → "true"  → envia {F1}, {F2} ...
;                  "false" → envia {1},  {2}  ...

ExecutarCombo(tipo) {
    global macros, interromperCombo

    if !macros[tipo]
        return

    interromperCombo := false
    _RodarSequenciaCombo(GetCfg(tipo))
}

; Sequência de combo compartilhada pelos combos Principal/Secundário e
; pelo Combo Revive: Full Attack (opcional) → teclas de teclaInicial até
; teclaFinal → Full Defense (opcional). Para se o combo for interrompido
; (revive, macro desligado, pânico) ou se o jogo perder o foco.
_RodarSequenciaCombo(cfg) {
    sleepMs := GetSleepCombo()
    usarF   := GetUsarPrefixoF()

    try {
        numInicial := Integer(RegExReplace(cfg["teclaInicial"], "\D", ""))
        numFinal   := Integer(RegExReplace(cfg["teclaFinal"],   "\D", ""))
    } catch {
        return
    }

    if (cfg["usarFullAtk"] = "true" && cfg["fullAttack"] != "N/A") {
        SendEvent("{" cfg["fullAttack"] "}")
        if !EsperarInterrompivel(20)
            return
    }

    Loop (numFinal - numInicial + 1) {
        if !_ComboPodeContinuar()
            return

        numTecla := numInicial + A_Index - 1
        SendEvent((usarF = "true") ? "{F" numTecla "}" : "{" numTecla "}")

        if !EsperarInterrompivel(sleepMs)
            return
    }

    ; Espera interrompível: com Sleep puro, um alt-tab nesses 200ms mandava
    ; o Full Defense para a outra janela.
    if (cfg["usarFullDef"] = "true" && cfg["fullDefense"] != "N/A") {
        if !EsperarInterrompivel(200)
            return
        SendEvent("{" cfg["fullDefense"] "}")
    }
}

; false se o combo deve parar (pedido de interrupção ou jogo sem foco).
; Consome o pedido de interrupção.
_ComboPodeContinuar() {
    global interromperCombo
    if (interromperCombo) {
        interromperCombo := false
        return false
    }
    return JogoAtivo()
}

; Espera 'ms' com precisão (prazo por A_TickCount, não soma de Sleeps —
; cada Sleep arredonda para cima, e antes 550ms viravam ~640ms reais),
; checando interrupção a cada ~10ms. Devolve false se foi interrompido.
EsperarInterrompivel(ms) {
    fim := A_TickCount + ms
    Loop {
        if !_ComboPodeContinuar()
            return false
        resta := fim - A_TickCount
        if (resta <= 0)
            return true
        Sleep(Min(resta, 10))
    }
}
