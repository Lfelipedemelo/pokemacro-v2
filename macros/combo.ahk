; =====================================================
; macros\combo.ahk — Execução dos macros de Combo
; =====================================================
;
; Lê duas configurações de [Geral] no INI:
;   sleepCombo   → tempo de espera entre cada tecla (padrão 92ms)
;   usarPrefixoF → "true"  → envia {F1}, {F2} ...
;                  "false" → envia {1},  {2}  ...

ExecutarCombo(tipo) {
    global macros, interromperCombo

    if !macros[tipo]
        return

    interromperCombo := false
    cfg := GetCfg(tipo)

    sleepMs := GetSleepCombo()
    usarF   := GetUsarPrefixoF()

    try {
        numInicial := Integer(RegExReplace(cfg["teclaInicial"], "\D", ""))
        numFinal   := Integer(RegExReplace(cfg["teclaFinal"],   "\D", ""))
    } catch {
        return
    }

    quantidade := numFinal - numInicial + 1

    if (cfg["usarFullAtk"] = "true" && cfg["fullAttack"] != "N/A")
        SendEvent("{" cfg["fullAttack"] "}")

    Loop quantidade {
        if (interromperCombo) {
            interromperCombo := false
            break
        }

        Sleep(20)

        numTecla := numInicial + A_Index - 1
        tecla    := (usarF = "true") ? "{F" numTecla "}" : "{" numTecla "}"
        SendEvent(tecla)

        fatia := Max(1, sleepMs // 10)
        Loop 10 {
            if (interromperCombo)
                break 2
            Sleep(fatia)
        }
    }

    if (cfg["usarFullDef"] = "true" && cfg["fullDefense"] != "N/A") {
        Sleep(200)
        SendEvent("{" cfg["fullDefense"] "}")
    }
}
