; =====================================================
; macros\revive.ahk — Execução do macro de Revive
; =====================================================

ExecutarRevive() {
    global macros, interromperCombo

    if !macros["revive"]
        return

    interromperCombo := true
    cfg        := GetCfg("revive")
    modoLegado := GetModoLegado()

    if (cfg["x"] = "N/A" || cfg["y"] = "N/A") {
        ShowHint("Erro: Defina a posição primeiro!", 1500)
        return
    }

    delay := IsNumber(cfg["delayRevive"]) ? Integer(cfg["delayRevive"]) : 40

    MouseGetPos(&xAtual, &yAtual)
    MouseMove(cfg["x"], cfg["y"], 0)

    if (modoLegado = "true") {
        ; Modo Legado: clique direito no alvo
        Click("Right")
        Sleep(delay)
        if (cfg["teclaInputRevive"] != "N/A") {
            SendEvent("{" cfg["teclaInputRevive"] " down}")
            SendEvent("{" cfg["teclaInputRevive"] " up}")
        }
        Click("Right")
    } else {
        ; Modo Normal: Ctrl+1
        SendEvent("{Ctrl down}{1 down}")
        SendEvent("{1 up}{Ctrl up}")
        Sleep(delay)
        if (cfg["teclaInputRevive"] != "N/A") {
            SendEvent("{" cfg["teclaInputRevive"] " down}")
            SendEvent("{" cfg["teclaInputRevive"] " up}")
        }
        SendEvent("{Ctrl down}{1 down}")
        SendEvent("{1 up}{Ctrl up}")
    }

    MouseMove(xAtual, yAtual, 0)
}
