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

    ; Reentrância: se já existe uma sequência de revive em andamento
    ; (deste Combo Revive ou do Revive avulso), ignora esta chamada em
    ; vez de disparar uma segunda sequência por cima da primeira.
    if (_reviveOcupado)
        return

    cfg := GetCfg("comboRevive")
    interromperCombo := false

    ; ── 1. Executa o Revive ──────────────────────────
    _reviveOcupado := true
    try {
        sucesso := _EnviarSequenciaRevive(GetCfg("Revive"), GetModoLegado())
    } finally {
        _reviveOcupado := false
    }

    if !sucesso {
        ShowHint("COMBO REVIVE: Defina a posição do Revive primeiro!", 1800, "danger")
        return
    }

    ; ── 2. Aguarda o delay entre revive e combo (interrompível) ──
    if !EsperarInterrompivel(cfg["delayCombo"])
        return

    ; ── 3. Executa o Combo ───────────────────────────
    if !macros["comboRevive"]   ; pode ter sido desligado durante o delay
        return

    _RodarSequenciaCombo(cfg)
}
