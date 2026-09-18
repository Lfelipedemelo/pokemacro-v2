; =====================================================
; lib\globals.ahk — Estado global da aplicação
; =====================================================

global configFile := "config.ini"
global myGui      := 0
global cfgAberta  := false

; GF() — retorna o tamanho de fonte atual do INI
; Usado em todos os SetFont da UI
GF() {
    global configFile
    sz := Integer(IniRead(configFile, "Geral", "tamanhoFonte", "9"))
    return "s" sz
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

; Referências de controles de UI (preenchidas em CriarInterface)
global uiRefs := Map()

; Anti-double-click
global lastClick := 0

; Controles de UI do Cooldown
global radiosCooldown    := []
global editsCooldown     := []
global txtHotkeyCooldown := 0
global txtPosicaoClique  := 0

; ─── Modo compacto ────────────────────────────────────
global modoCompacto := false

; ─── Sistema de temas ────────────────────────────────
GetTema() {
    global configFile
    return IniRead(configFile, "Geral", "tema", "Pokédex Vermelho")
}

T() {
    switch GetTema() {
        case "Night Blue":
            return Map(
                "BG",      "0x0d1117",
                "BG2",     "0x161b22",
                "BG3",     "0x1f2937",
                "ACCENT",  "0x58a6ff",
                "ACCENT2", "0x1f6feb",
                "TEXT",    "0xe6edf3",
                "MUTED",   "0x8b949e",
                "SEP",     "0x21262d",
                "DANGER",  "0xf85149",
                "STRIPE1", "0x1f6feb",
                "STRIPE2", "0x388bfd",
                "STRIPE3", "0x58a6ff",
                "BADGE",   "0x1c2128"
            )
        case "Gold":
            return Map(
                "BG",      "0x13110a",
                "BG2",     "0x1e1a0e",
                "BG3",     "0x2a2414",
                "ACCENT",  "0xffd700",
                "ACCENT2", "0xffa500",
                "TEXT",    "0xfff8dc",
                "MUTED",   "0x8b7355",
                "SEP",     "0x2a2414",
                "DANGER",  "0xdc2626",
                "STRIPE1", "0xffd700",
                "STRIPE2", "0xffa500",
                "STRIPE3", "0xff8c00",
                "BADGE",   "0x0f0d07"
            )
        case "Minimal":
            return Map(
                "BG",      "0x111111",
                "BG2",     "0x1c1c1c",
                "BG3",     "0x262626",
                "ACCENT",  "0xd4d4d4",
                "ACCENT2", "0x737373",
                "TEXT",    "0xfafafa",
                "MUTED",   "0x525252",
                "SEP",     "0x262626",
                "DANGER",  "0xef4444",
                "STRIPE1", "0x404040",
                "STRIPE2", "0x525252",
                "STRIPE3", "0x737373",
                "BADGE",   "0x0a0a0a"
            )
        default: ; "Pokédex Vermelho"
            return Map(
                "BG",      "0x1a1c1e",
                "BG2",     "0x282a2d",
                "BG3",     "0x2f3136",
                "ACCENT",  "0x57f287",
                "ACCENT2", "0x3ba55d",
                "TEXT",    "0xffffff",
                "MUTED",   "0x72767d",
                "SEP",     "0x1e1f22",
                "DANGER",  "0xed4245",
                "STRIPE1", "0xed4245",
                "STRIPE2", "0xfaa61a",
                "STRIPE3", "0x5865f2",
                "BADGE",   "0x1e2124"
            )
    }
}
