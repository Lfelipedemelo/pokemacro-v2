; =====================================================
; macros\combo_revive.ahk — Macro Combo Revive
; =====================================================
;
; Executa o revive usando as configs de [Revive],
; aguarda delayCombo ms, depois executa o combo
; usando as configs de [comboRevive].

ExecutarComboRevive() {
    global macros, interromperCombo

    if !macros["comboRevive"]
        return

    cfg        := GetCfg("comboRevive")
    modoLegado := GetModoLegado()

    ; ── 1. Executa o Revive ──────────────────────────
    interromperCombo := false

    cfgRev := GetCfg("Revive")

    if (cfgRev["x"] = "N/A" || cfgRev["y"] = "N/A") {
        ShowHint("COMBO REVIVE: Defina a posição do Revive primeiro!", 1800)
        return
    }

    delay := IsNumber(cfgRev["delayRevive"]) ? Integer(cfgRev["delayRevive"]) : 40

    MouseGetPos(&xAtual, &yAtual)
    MouseMove(cfgRev["x"], cfgRev["y"], 0)

    if (modoLegado = "true") {
        Click("Right")
        Sleep(delay)
        if (cfgRev["teclaInputRevive"] != "N/A") {
            SendEvent("{" cfgRev["teclaInputRevive"] " down}")
            SendEvent("{" cfgRev["teclaInputRevive"] " up}")
        }
        Click("Right")
    } else {
        SendEvent("{Ctrl down}{1 down}")
        SendEvent("{1 up}{Ctrl up}")
        Sleep(delay)
        if (cfgRev["teclaInputRevive"] != "N/A") {
            SendEvent("{" cfgRev["teclaInputRevive"] " down}")
            SendEvent("{" cfgRev["teclaInputRevive"] " up}")
        }
        SendEvent("{Ctrl down}{1 down}")
        SendEvent("{1 up}{Ctrl up}")
    }

    MouseMove(xAtual, yAtual, 0)

    ; ── 2. Aguarda o delay entre revive e combo ──────
    Sleep(cfg["delayCombo"])

    ; ── 3. Executa o Combo ───────────────────────────
    if !macros["comboRevive"]   ; pode ter sido desligado durante o delay
        return

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
