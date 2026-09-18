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

    delay := IsNumber(cfgRev["delayRevive"]) ? Integer(cfgRev["delayRevive"]) : 40

    Critical("On")
    try {
        MouseGetPos(&xAtual, &yAtual)
        MouseMove(cfgRev["x"], cfgRev["y"], 0)

        if (modoLegado = "true") {
            ; Modo Legado: clique direito no alvo
            Click("Right")
            Sleep(delay)
            if (cfgRev["teclaInputRevive"] != "N/A") {
                SendEvent("{" cfgRev["teclaInputRevive"] " down}")
                SendEvent("{" cfgRev["teclaInputRevive"] " up}")
            }
            Click("Right")
        } else {
            ; Modo Normal: Ctrl+1
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
    } finally {
        Critical("Off")
    }

    return true
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

    cfg        := GetCfg("revive")
    modoLegado := GetModoLegado()

    _reviveOcupado := true
    try {
        if !_EnviarSequenciaRevive(cfg, modoLegado)
            ShowHint("Erro: Defina a posição primeiro!", 1500, "danger")
    } finally {
        _reviveOcupado := false
    }
}
