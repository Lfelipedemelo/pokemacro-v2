; =====================================================
; macros\hotkeys.ahk — Estado dos macros, registro de hotkeys e dispatch
; =====================================================

global _macroExecutando := false

; ─── Estado dos macros (único lugar que liga/desliga) ─────
; HUD, hotkeys de toggle e tecla de pânico passam todos por aqui, então
; a regra de exclusividade entre combos e o redesenho da HUD valem igual
; para qualquer origem.
DefinirMacro(nome, ligado) {
    global macros, interromperCombo, executandoCooldown, COMBOS_EXCLUSIVOS

    macros[nome] := ligado

    if (ligado && _EhComboExclusivo(nome)) {
        for outro in COMBOS_EXCLUSIVOS {
            if (outro != nome && macros[outro]) {
                macros[outro] := false
                interromperCombo := true   ; para o combo do outro, se estiver rodando
            }
        }
    }

    ; Desligar também para o que estiver rodando daquele macro.
    if (!ligado) {
        if _EhComboExclusivo(nome)
            interromperCombo := true
        if (nome = "cooldown")
            executandoCooldown := false
    }

    _HudRedraw()
}

AlternarMacro(nome) {
    global macros
    DefinirMacro(nome, !macros[nome])
    return macros[nome]
}

_EhComboExclusivo(nome) {
    global COMBOS_EXCLUSIVOS
    for c in COMBOS_EXCLUSIVOS
        if (c = nome)
            return true
    return false
}

; ─── Tecla de pânico: desliga tudo e para o que estiver rodando ──
DesligarTodosMacros() {
    global macros, interromperCombo, executandoCooldown
    for nome in macros
        macros[nome] := false
    interromperCombo   := true
    executandoCooldown := false
    _HudRedraw()
    ShowHint("TODOS OS MACROS DESLIGADOS", 1400, "warn")
}

; ─── Hotkeys configuráveis ────────────────────────────────
; Lista de todas as teclas que viram hotkey, com rótulo para mensagens de
; conflito. tipo: "exec" (executa o macro), "toggle" ou "panico".
_HotkeySlots() {
    global MACROS_INFO
    slots := []
    for nome, info in MACROS_INFO {
        slots.Push({ secao: info.secao, chave: info.exec,         tipo: "exec",   macro: nome, label: info.label })
        slots.Push({ secao: info.secao, chave: "toggleHotkey",    tipo: "toggle", macro: nome, label: info.label " (LIGAR/DESLIGAR)" })
    }
    slots.Push({ secao: "Geral", chave: "teclaPanico", tipo: "panico", macro: "", label: "TECLA DE PÂNICO" })
    return slots
}

HotkeySlotExiste(secao, chave) {
    for s in _HotkeySlots()
        if (s.secao = secao && s.chave = chave)
            return true
    return false
}

; Devolve o rótulo da hotkey que já usa 'tecla', ou "" se estiver livre.
; Única exceção permitida: a tecla de executar dos três combos pode ser a
; mesma, já que só um deles fica ligado por vez (o despachante sabe qual).
ConflitoDeTecla(secao, chave, tecla) {
    atual := 0
    for s in _HotkeySlots()
        if (s.secao = secao && s.chave = chave)
            atual := s
    if !atual
        return ""

    for s in _HotkeySlots() {
        if (s.secao = atual.secao && s.chave = atual.chave)
            continue
        if (CfgLer(s.secao, s.chave, "") != tecla)
            continue
        if (s.tipo = "exec" && atual.tipo = "exec" && _EhComboExclusivo(s.macro) && _EhComboExclusivo(atual.macro))
            continue
        return s.label
    }
    return ""
}

; Botão do mouse sozinho ganha "*" (dispara mesmo com modificador segurado).
; Com modificador ("+XButton1") o "*" sai: senão "XButton1" e
; "Shift+XButton1" não poderiam ser hotkeys diferentes.
_MontarChaveHk(tecla) {
    if (tecla = "N/A" || tecla = "")
        return ""
    temMods := (tecla ~= "^[\^!+]+.")
    prefixo := (tecla ~= "i)Button" && !temMods) ? "$*" : "$"
    return prefixo . tecla
}

_TeclaExec(nome) {
    global MACROS_INFO
    info := MACROS_INFO[nome]
    return CfgLer(info.secao, info.exec, "")
}

; Re-registra todas as hotkeys a partir do INI. Só precisa rodar quando
; uma tecla muda (captura, reset) — ligar/desligar um
; macro NÃO exige re-registro, porque os critérios de HotIf consultam
; macros[] na hora do pressionamento.
;
; Os critérios (funções de HotIf) são criados uma única vez e reusados:
; o AHK identifica a variante de uma hotkey pelo objeto do critério, e
; desligar uma hotkey só funciona com o MESMO critério ativo. Antes cada
; chamada criava closures novas — o "Off" nunca achava a variante, e
; teclas antigas continuavam capturadas (e acumulando) pela sessão toda.
AtualizarHotkeyCombo() {
    global MACROS_INFO
    static registradas := []
    static critExec := 0, critJogo := 0

    if !critExec {
        critExec := Map()
        for nome, info in MACROS_INFO
            critExec[nome] := _CriterioExec.Bind(nome)
        critJogo := (*) => JogoAtivo()
    }

    for r in registradas {
        HotIf(r.crit)
        try Hotkey(r.chave, "Off")
    }
    registradas := []

    pedidos := []
    for nome, info in MACROS_INFO {
        pedidos.Push({ chave: _MontarChaveHk(CfgLer(info.secao, info.exec, "")), crit: critExec[nome], cb: ProcessarPressionamento })
        pedidos.Push({ chave: _MontarChaveHk(CfgLer(info.secao, "toggleHotkey", "")), crit: critJogo, cb: ToggleMacroPorHotkey.Bind(nome) })
    }
    pedidos.Push({ chave: _MontarChaveHk(CfgLer("Geral", "teclaPanico", "")), crit: critJogo, cb: (*) => DesligarTodosMacros() })

    for p in pedidos {
        if (p.chave = "")
            continue
        HotIf(p.crit)
        try {
            Hotkey(p.chave, p.cb, "On")
            registradas.Push({ chave: p.chave, crit: p.crit })
        }
    }

    HotIf()
}

; Critério da hotkey de execução: jogo em foco, macro ligado e — para os
; que não são interrompíveis (combos principal/secundário) — nenhum outro
; macro em andamento.
_CriterioExec(nome, *) {
    global macros, MACROS_INFO, _macroExecutando
    return JogoAtivo() && macros[nome] && (MACROS_INFO[nome].interrompivel || !_macroExecutando)
}

; ─── Toggle via hotkey ────────────────────────────────────
ToggleMacroPorHotkey(nome, *) {
    global MACROS_INFO
    ligado := AlternarMacro(nome)
    ShowHint(MACROS_INFO[nome].label ": " (ligado ? "LIGADO" : "DESLIGADO"), 1200, ligado ? "success" : "info")
}

; ─── Despachante central ─────────────────────────────────
ProcessarPressionamento(thisHotkey) {
    global macros, executandoCooldown, _macroExecutando, MACROS_ORDEM, MACROS_INFO

    teclaPura := RegExReplace(thisHotkey, "^[$~*]+")

    alvo := ""
    for nome in MACROS_ORDEM {
        if (macros[nome] && _TeclaExec(nome) = teclaPura) {
            alvo := nome
            break
        }
    }
    if (alvo = "")
        return

    ; Revive, Combo Revive e Cooldown (cancelamento) não são bloqueados
    ; pela flag de execução — funcionam mesmo durante um combo.
    interrompivel := MACROS_INFO[alvo].interrompivel
    if (!interrompivel) {
        if (_macroExecutando)
            return
        _macroExecutando := true
    }

    try {
        switch alvo {
            case "comboPrincipal", "comboSecundario":
                ExecutarCombo(alvo)
            case "comboRevive":
                ExecutarComboRevive()
            case "revive":
                ExecutarRevive()
            case "cooldown":
                if (executandoCooldown) {
                    executandoCooldown := false
                    ShowHint("CANCELADO", 1000, "warn")
                } else {
                    ExecutarMacroCooldown()
                }
        }
    } finally {
        if (!interrompivel)
            _macroExecutando := false
    }
}
