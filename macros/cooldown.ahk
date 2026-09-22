; =====================================================
; macros\cooldown.ahk — Execução do macro de Cooldown
; =====================================================

ExecutarMacroCooldown() {
    global executandoCooldown

    ; Sem posição configurada, o clique iria para o canto (0, 0) da tela.
    if (CfgLer("Cooldown", "clickX", "") = "" || CfgLer("Cooldown", "clickY", "") = "") {
        ShowHint("COOLDOWN: Defina a posição primeiro!", 1800, "danger")
        return
    }

    executandoCooldown := true
    cfg     := GetCfg("Cooldown")
    idAtual := cfg["pokemonInicial"]

    MouseGetPos(&xOriginal, &yOriginal)

    if (cfg["usarFullDefCD"] = "true" && cfg["fullDefense"] != "N/A")
        SendEvent("{" cfg["fullDefense"] "}")

    Loop {
        if (!executandoCooldown || idAtual < 1 || !cfg.Has("tempo" idAtual))
            break
        ; Nunca clica fora do jogo: se o jogador deu alt-tab durante a
        ; espera, segura o próximo clique até o jogo voltar ao foco.
        while (executandoCooldown && !JogoAtivo())
            Sleep(100)
        if (!executandoCooldown)
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
