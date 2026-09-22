; =====================================================
; lib\globals.ahk — Estado global da aplicação
; =====================================================

; Caminho absoluto: o script pode ser iniciado com outro diretório de
; trabalho (atalho, reinício como administrador via *RunAs etc.), e um
; caminho relativo faria o app ler/criar um config.ini em outro lugar.
global configFile := A_ScriptDir "\config.ini"

; ─── Escala da interface (HUD + telas de configuração) ───────────────
; "pequeno" | "normal" | "grande" — "normal" preserva exatamente o
; tamanho de hoje; os outros multiplicam por um fator fixo e modesto
; (não exagerado) pra não pesar o redesenho da HUD, que roda a até 60fps
; durante hover/expandir (lib\gdip_config.ahk e ui\mini_menu.ahk usam
; esse fator de formas diferentes — ver comentário em cada um).
GetEscalaInterface() {
    return CfgLer("Geral", "escalaInterface", "normal")
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

; Metadados de cada macro: seção do INI, chave da tecla que executa,
; rótulo exibido e se a execução "interrompe" (roda mesmo com outro
; macro em andamento). A tecla de ligar/desligar é sempre "toggleHotkey"
; dentro da mesma seção. Usado pelo registro de hotkeys, pelo despachante
; e pela checagem de conflito de teclas (macros\hotkeys.ahk).
global MACROS_INFO := Map(
    "comboPrincipal",  { secao: "comboPrincipal",  exec: "teclaHotkey",    label: "COMBO PRINCIPAL",  interrompivel: false },
    "comboSecundario", { secao: "comboSecundario", exec: "teclaHotkey",    label: "COMBO SECUNDÁRIO", interrompivel: false },
    "comboRevive",     { secao: "comboRevive",     exec: "teclaHotkey",    label: "COMBO REVIVE",     interrompivel: true  },
    "revive",          { secao: "Revive",          exec: "teclaHotkey",    label: "REVIVE",           interrompivel: true  },
    "cooldown",        { secao: "Cooldown",        exec: "hotkeyCooldown", label: "COOLDOWN",         interrompivel: true  }
)

; Ordem de prioridade do despachante quando a mesma tecla serve a mais
; de um macro ligado (ver ProcessarPressionamento).
global MACROS_ORDEM := ["comboPrincipal", "comboSecundario", "comboRevive", "revive", "cooldown"]

; Os três combos são mutuamente exclusivos (ligar um desliga os outros).
global COMBOS_EXCLUSIVOS := ["comboPrincipal", "comboSecundario", "comboRevive"]

; Mapa de ícones usados na interface principal
global icons := Map(
    "comboPrincipal",  "icons\combo_principal.png",
    "comboSecundario", "icons\combo_secundario.png",
    "revive",          "icons\revive.png",
    "cooldown",        "icons\cooldown.png",
    "comboRevive",     "icons\combo_revive.png"
)

; ─── Tema fixo (Pokédex Azul) ────────────────────
; Map estático: é consultado várias vezes por frame da HUD, e montar um
; Map novo a cada chamada era desperdício. Ninguém deve alterá-lo.
T() {
    static tema := Map(
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
    return tema
}
