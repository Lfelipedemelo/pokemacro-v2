; =====================================================
; macros\combo_revive.ahk — Macro Combo Revive
; =====================================================
;
; Executa o revive usando as configs de [Revive],
; aguarda delayCombo ms, depois executa o combo
; usando as configs de [comboRevive].

ExecutarComboRevive() {
    global macros, interromperCombo, _reviveOcupado

    if !macros["comboRevive"]
        return

    cfg        := GetCfg("comboRevive")
    modoLegado := GetModoLegado()

    ; ── 1. Executa o Revive ──────────────────────────
    interromperCombo := false

    ; Reentrância: se já existe uma sequência de revive em andamento
    ; (deste Combo Revive ou do Revive avulso), ignora esta chamada em
    ; vez de disparar uma segunda sequência por cima da primeira.
    if (_reviveOcupado)
        return

    cfgRev := GetCfg("Revive")

    _reviveOcupado := true
    try {
        sucesso := _EnviarSequenciaRevive(cfgRev, modoLegado)
    } finally {
        _reviveOcupado := false
    }

    if !sucesso {
        ShowHint("COMBO REVIVE: Defina a posição do Revive primeiro!", 1800, "danger")
        return
    }

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
        if !WinActive("ahk_exe pxgme.exe")
            break

        Sleep(20)

        numTecla := numInicial + A_Index - 1
        tecla    := (usarF = "true") ? "{F" numTecla "}" : "{" numTecla "}"
        SendEvent(tecla)

        fatia := Max(1, sleepMs // 10)
        Loop 10 {
            if (interromperCombo) {
                interromperCombo := false
                break 2
            }
            if !WinActive("ahk_exe pxgme.exe")
                break 2
            Sleep(fatia)
        }
    }

    if (cfg["usarFullDef"] = "true" && cfg["fullDefense"] != "N/A") {
        Sleep(200)
        SendEvent("{" cfg["fullDefense"] "}")
    }
}
