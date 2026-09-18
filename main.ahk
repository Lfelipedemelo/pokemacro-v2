#Requires AutoHotkey v2.0
#MaxThreadsPerHotkey 2

; =====================================================
; ENTRY POINT — Carrega todos os módulos
; =====================================================

#Include lib\globals.ahk
#Include lib\config.ahk
#Include lib\hint.ahk
#Include lib\window.ahk
#Include lib\input.ahk

#Include ui\slot.ahk
#Include ui\gui_main.ahk
#Include ui\mini_menu.ahk
#Include ui\config_combo.ahk
#Include ui\config_revive.ahk
#Include ui\config_cooldown.ahk
#Include ui\config_combo_revive.ahk
#Include ui\config_geral.ahk

#Include macros\hotkeys.ahk
#Include macros\combo.ahk
#Include macros\revive.ahk
#Include macros\cooldown.ahk
#Include macros\combo_revive.ahk

; =====================================================
; INICIALIZAÇÃO
; =====================================================

CoordMode("Mouse",   "Screen")
CoordMode("Pixel",   "Screen")
CoordMode("ToolTip", "Screen")
SetDefaultMouseSpeed(0)

AtualizarHotkeyCombo()

; =====================================================
; HOTKEY GLOBAL — Ctrl+F12 abre/fecha a interface
; =====================================================
^F12:: {
    global myGui

    if (myGui) {
        SalvarPosicaoJanela()
        myGui.Destroy()
        myGui := 0
    } else {
        CriarInterface()
    }
}
