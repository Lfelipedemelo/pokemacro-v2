; =====================================================
; macros\cooldown.ahk — Execução do macro de Cooldown
; =====================================================

ExecutarMacroCooldown() {
    global executandoCooldown

    executandoCooldown := true
    cfg     := GetCfg("Cooldown")
    idAtual := cfg["pokemonInicial"]

    if (cfg["usarFullDefCD"] = "true" && cfg["fullDefense"] != "N/A")
        SendEvent("{" cfg["fullDefense"] "}")

    Loop {
        if (!executandoCooldown || idAtual < 1 || !cfg.Has("tempo" idAtual))
            break
        ; Se o jogador está em outra janela/tela durante a espera, traz o
        ; jogo para frente antes de trocar o pokémon — sem mexer no mouse.
        if (!JogoAtivo()) {
            while (executandoCooldown && !JogoAtivo()) {
                try WinActivate("ahk_exe " JOGO_EXE)
                WinWaitActive("ahk_exe " JOGO_EXE,, 1)
            }
            Sleep(50)  ; dá tempo do cliente processar o foco antes da tecla
        }
        if (!executandoCooldown)
            break

        SendEvent("^" . idAtual)

        tempoEspera := cfg["tempo" . idAtual]
        Loop (tempoEspera * 10) {
            if (!executandoCooldown)
                break 2
            Sleep(100)
        }

        idAtual--
    }

    executandoCooldown := false
}
