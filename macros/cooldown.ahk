; =====================================================
; macros\cooldown.ahk — Execução do macro de Cooldown
; =====================================================

ExecutarMacroCooldown() {
    global executandoCooldown

    executandoCooldown := true
    cfg     := GetCfg("Cooldown")
    idAtual := cfg["pokemonInicial"]

    MouseGetPos(&xOriginal, &yOriginal)

    if (cfg["usarFullDefCD"] = "true" && cfg["fullDefense"] != "N/A")
        SendEvent("{" cfg["fullDefense"] "}")

    Loop {
        if (!executandoCooldown || idAtual < 1)
            break

        MouseMove(cfg["clickX"], cfg["clickY"], 0)
        Click()

        if (!executandoCooldown)
            break

        SendEvent("^" . idAtual)
        Sleep(50)
        MouseMove(xOriginal, yOriginal, 0)

        tempoEspera := cfg["tempo" . idAtual]
        Loop (tempoEspera * 10) {
            if (!executandoCooldown)
                break 2
            Sleep(100)
        }

        idAtual--
    }

    executandoCooldown := false
    MouseMove(xOriginal, yOriginal, 0)
}
