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
                ; Jogo fechado: não fica tentando ativar uma janela que não existe.
                if !ProcessExist(JOGO_EXE) {
                    ShowHint("COOLDOWN: jogo não encontrado, cancelado", 1800, "danger")
                    break 2
                }
                try WinActivate("ahk_exe " JOGO_EXE)
                WinWaitActive("ahk_exe " JOGO_EXE,, 1)
            }
            Sleep(50)  ; dá tempo do cliente processar o foco antes da tecla
        }
        if (!executandoCooldown)
            break

        SendEvent("^" . cfg["tecla" . idAtual])

        ; Prazo por A_TickCount (igual ao EsperarInterrompivel do combo):
        ; somar Sleep(100) acumulava o arredondamento do timer do Windows
        ; (~15,6ms) e 60s viravam ~65s reais.
        fim := A_TickCount + cfg["tempo" . idAtual] * 1000
        while ((resta := fim - A_TickCount) > 0) {
            if (!executandoCooldown)
                break 2
            Sleep(Min(resta, 100))
        }

        idAtual--
    }

    executandoCooldown := false
}
