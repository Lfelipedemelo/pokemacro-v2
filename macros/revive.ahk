; =====================================================
; macros\revive.ahk — Execução do macro de Revive
; =====================================================

; Trava de reentrância: impede que duas execuções da sequência de
; revive (via Revive ou Combo Revive) rodem ao mesmo tempo.
global _reviveOcupado := false

; Envia a sequência de uso do item de revive (clique direito no modo
; legado, ou Ctrl+1 no modo normal). Roda em modo Critical para que
; nenhuma outra hotkey (outro revive, combo, cooldown...) consiga
; intercalar teclas no meio do caminho — sem isso, uma segunda thread
; podia soltar o Ctrl antes da hora (ex.: repeat automático do Windows
; ao segurar a tecla), fazendo o clique/target funcionar mas o item
; não ser usado.
_EnviarSequenciaRevive(cfgRev, modoLegado) {
    if (cfgRev["x"] = "N/A" || cfgRev["y"] = "N/A")
        return false

    delay := IsNumber(cfgRev["delayRevive"]) ? Integer(cfgRev["delayRevive"]) : 50

    Critical("On")
    try {
        ; Só recolhe o pokémon se ele estiver fora: guardado ou morto, o
        ; primeiro Ctrl+1/clique o soltaria e a sequência sairia invertida.
        ; Sem detecção calibrada (-1), mantém o comportamento antigo.
        estado := EstadoPokemonFora()

        MouseGetPos(&xAtual, &yAtual)
        MouseMove(cfgRev["x"], cfgRev["y"], 0)

        if (estado != 0) {
            _AlternarPokebola(modoLegado)
            ; Com detecção, espera o jogo de fato recolher antes do item —
            ; o delay sozinho, se muito baixo, atropelava o jogo.
            if (estado = 1)
                EsperarDedoSumir(500)
            Sleep(delay)
        }
        if (cfgRev["teclaInputRevive"] != "N/A") {
            SendEvent("{" cfgRev["teclaInputRevive"] " down}")
            SendEvent("{" cfgRev["teclaInputRevive"] " up}")
        }
        _AlternarPokebola(modoLegado)

        MouseMove(xAtual, yAtual, 0)
    } finally {
        Critical("Off")
    }

    return true
}

; Recolhe/solta o pokémon: clique direito no alvo (modo legado) ou Ctrl+1.
_AlternarPokebola(modoLegado) {
    if (modoLegado = "true") {
        Click("Right")
    } else {
        SendEvent("{Ctrl down}{1 down}")
        SendEvent("{1 up}{Ctrl up}")
    }
}

ExecutarRevive() {
    global macros, interromperCombo, _reviveOcupado

    if !macros["revive"]
        return

    ; Sempre interrompe um combo em andamento, mesmo que esta
    ; execução do revive acabe sendo ignorada por reentrância abaixo.
    interromperCombo := true

    if (_reviveOcupado)
        return

    cfg        := GetCfg("Revive")
    modoLegado := GetModoLegado()

    _reviveOcupado := true
    try {
        if !_EnviarSequenciaRevive(cfg, modoLegado)
            ShowHint("Erro: Defina a posição primeiro!", 1500, "danger")
    } finally {
        _reviveOcupado := false
    }
}
