#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 2

SetWorkingDir(A_ScriptDir)
TraySetIcon(A_ScriptDir "\icons\logo.png")

; =====================================================
; ENTRY POINT — Carrega todos os módulos
; =====================================================

#Include lib\globals.ahk
#Include lib\config.ahk
#Include lib\gdip.ahk
#Include lib\gdip_config.ahk
#Include lib\hint.ahk
#Include lib\window.ahk
#Include lib\input.ahk

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
AbrirMiniMenu()
VerificarElevacaoJogo()

; =====================================================
; HOTKEY GLOBAL — Ctrl+F12 abre/fecha a interface (HUD)
; =====================================================
^F12:: AbrirMiniMenu()
