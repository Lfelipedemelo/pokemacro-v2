; =====================================================
; lib\globals.ahk — Estado global da aplicação
; =====================================================

global configFile := "config.ini"

; GF() — retorna o tamanho de fonte atual do INI
; Usado em todos os SetFont da UI
GF() {
    global configFile
    sz := Integer(IniRead(configFile, "Geral", "tamanhoFonte", "9"))
    return "s" sz
}

; ─── Escala da interface (HUD + telas de configuração) ───────────────
; "pequeno" | "normal" | "grande" — "normal" preserva exatamente o
; tamanho de hoje; os outros multiplicam por um fator fixo e modesto
; (não exagerado) pra não pesar o redesenho da HUD, que roda a até 60fps
; durante hover/expandir (lib\gdip_config.ahk e ui\mini_menu.ahk usam
; esse fator de formas diferentes — ver comentário em cada um).
GetEscalaInterface() {
    global configFile
    return IniRead(configFile, "Geral", "escalaInterface", "normal")
}

EscalaFator(nome := "") {
    static fatores := Map("pequeno", 0.85, "normal", 1.0, "grande", 1.2)
    if (nome = "")
        nome := GetEscalaInterface()
    return fatores.Has(nome) ? fatores[nome] : 1.0
}

; Estado de execução dos macros
global interromperCombo    := false
global executandoCooldown  := false

; Mapa de macros ativos (nome => bool)
global macros := Map(
    "comboPrincipal",  false,
    "comboSecundario", false,
    "revive",          false,
    "cooldown",        false,
    "comboRevive",     false
)

; Mapa de ícones usados na interface principal
global icons := Map(
    "comboPrincipal",  "icons\combo_principal.png",
    "comboSecundario", "icons\combo_secundario.png",
    "revive",          "icons\revive.png",
    "cooldown",        "icons\cooldown.png",
    "comboRevive",     "icons\combo_revive.png"
)

; Referências de controles de UI
global uiRefs := Map()

; Anti-double-click
global lastClick := 0

; ─── Tema fixo (Pokédex Azul) ────────────────────
T() {
    return Map(
        "BG",      "0x14181f",
        "BG2",     "0x1e2530",
        "BG3",     "0x262e3b",
        "ACCENT",  "0x2f6fed",
        "ACCENT2", "0x5b9bff",
        "TEXT",    "0xffffff",
        "MUTED",   "0xa9b4c4",
        "SEP",     "0x1a2028",
        "DANGER",  "0xee1515",
        "STRIPE1", "0x2f6fed",
        "STRIPE2", "0xffcb05",
        "STRIPE3", "0xee1515",
        "BADGE",   "0x1a2028"
    )
}
