; =====================================================
; lib\input.ahk — Captura de teclas e posições do mouse
; =====================================================

; Botões que nunca podem virar tecla de macro: seriam capturados pelo
; hook e o clique normal do mouse deixaria de chegar ao jogo.
_BotaoProibido(tecla) {
    return (tecla = "LButton" || tecla = "RButton")
}

; Grava uma tecla capturada. Se (secao, chave) for uma hotkey (executar,
; ligar/desligar ou pânico), antes checa conflito com as outras hotkeys e,
; depois de salvar, re-registra todas — sem isso a tecla nova só passava
; a valer depois de outra ação qualquer re-registrar as hotkeys.
; Devolve true se salvou.
_SalvarTeclaCapturada(secao, chave, tecla, label) {
    ehHotkey := HotkeySlotExiste(secao, chave)
    if (ehHotkey) {
        conflito := ConflitoDeTecla(secao, chave, tecla)
        if (conflito != "") {
            ShowHint(_ComboDisplay(tecla) " já é usada em " conflito, 2200, "danger")
            return false
        }
    }
    SalvarCfg(secao, chave, tecla)
    if (ehHotkey)
        AtualizarHotkeyCombo()
    ShowHint(label ": " _ComboDisplay(tecla), 1300, "success")
    return true
}

; Modificadores fisicamente pressionados, no formato de hotkey do AHK.
; Ordem fixa (^!+) para que a mesma combinação vire sempre o mesmo texto
; no INI — a checagem de conflito e o despachante comparam strings.
_ModsPressionados() {
    mods := ""
    if GetKeyState("Ctrl", "P")
        mods .= "^"
    if GetKeyState("Alt", "P")
        mods .= "!"
    if GetKeyState("Shift", "P")
        mods .= "+"
    return mods
}

; Tira os modificadores das teclas que encerram o InputHook: sozinhos eles
; não são a tecla escolhida, só entram como prefixo dela.
_IgnorarModsNoHook(ih) {
    ih.KeyOpt("{LControl}{RControl}{LShift}{RShift}{LAlt}{RAlt}{LWin}{RWin}", "-E -S")
}

; Aguarda o usuário pressionar uma tecla/botão do mouse e salva no INI.
; Se (secao, chave) for uma hotkey, aceita combinação com Ctrl/Alt/Shift
; (ex.: "^y", "+XButton1"); teclas que o macro ENVIA ao jogo ficam
; sempre com uma tecla só.
; Se 'uiText' for um objeto de controle, atualiza seu valor visual.
CapturarTecla(configSection, configKey, uiText := 0, label := "Tecla") {
    aceitaMods := HotkeySlotExiste(configSection, configKey)
    ShowHint(aceitaMods
        ? "Pressione tecla, botão do mouse ou combinação com Ctrl/Alt/Shift (ESC cancela)"
        : "Pressione tecla ou botão do mouse (ESC cancela)", 999999)

    ; Aguarda soltar o botão que abriu a captura (evita capturar o próprio clique)
    while GetKeyState("LButton", "P")
        Sleep(10)
    Sleep(150)

    ; Sem a opção E: EndKey devolve o nome da tecla ("y"), não o caractere
    ; gerado — com Ctrl/Shift segurado o caractere seria outro.
    ih := InputHook("L0")
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{Escape}", "-E")
    _IgnorarModsNoHook(ih)
    ih.Start()

    tecla := ""

    Loop {
        Sleep(10)

        if GetKeyState("Escape", "P") {
            ih.Stop()
            ShowHint("Cancelado", 1200, "warn")
            return
        }

        key := ih.EndKey
        if (key != "") {
            tecla := _NormalizarTecla(key)
            break
        }

        for btn in ["LButton", "RButton", "MButton", "XButton1", "XButton2"] {
            if GetKeyState(btn, "P") {
                tecla := btn
                break 2
            }
        }
    }

    ; Lido logo após detectar a tecla, enquanto os modificadores ainda estão
    ; segurados.
    mods := aceitaMods ? _ModsPressionados() : ""
    ih.Stop()

    if (!tecla) {
        ShowHint("Nenhuma tecla detectada", 1000, "warn")
        return
    }
    if _BotaoProibido(tecla) {
        while GetKeyState(tecla, "P")
            Sleep(10)
        ShowHint("Clique esquerdo/direito não pode ser usado", 1800, "warn")
        return
    }

    tecla := mods . tecla
    if !_SalvarTeclaCapturada(configSection, configKey, tecla, label)
        return

    if IsObject(uiText)
        uiText.Value := label ": [ " _ComboDisplay(tecla) " ]"
}

; Aguarda um clique do mouse e salva as coordenadas no INI.
CapturarPosicaoMouse(secao, objetoTexto, chaveX := "clickX", chaveY := "clickY") {
    CoordMode("Mouse", "Screen")

    ShowHint("Clique no local desejado (ESC cancela)", 999999)

    ; Espera soltar o botão caso já esteja pressionado
    while GetKeyState("LButton", "P")
        Sleep(10)

    Loop {
        Sleep(10)

        if GetKeyState("Escape", "P") {
            ShowHint("Cancelado", 1200, "warn")
            return
        }

        if GetKeyState("LButton", "P") {
            MouseGetPos(&posX, &posY)
            break
        }
    }

    SalvarCfg(secao, chaveX, posX)
    SalvarCfg(secao, chaveY, posY)

    if IsSet(objetoTexto) && IsObject(objetoTexto)
        objetoTexto.Value := "Posição: [ " posX ", " posY " ]"

    ShowHint("Posição salva: " posX ", " posY, 1200, "success")
}

; Captura uma tecla de teclado OU um botão de mouse, opcionalmente com
; Ctrl/Alt/Shift. Usado para as hotkeys de toggle e pânico.
; Exemplos: "F5", "XButton1", "q", "^y", "+XButton2"
CapturarCombo(configSection, configKey, uiText := 0, label := "Hotkey") {
    ShowHint("Pressione tecla, botão do mouse ou combinação com Ctrl/Alt/Shift (ESC cancela)", 999999)

    ; Aguarda soltar tudo antes de começar
    Sleep(300)
    Loop {
        Sleep(20)
        allUp := true
        for k in ["LButton","RButton","XButton1","XButton2","MButton","Space"] {
            if GetKeyState(k, "P") {
                allUp := false
                break
            }
        }
        if allUp
            break
    }
    Sleep(150)

    ih := InputHook("V I")
    ih.KeyOpt("{All}", "E S")
    _IgnorarModsNoHook(ih)
    ih.Start()

    resultado := ""

    Loop {
        Sleep(10)

        if GetKeyState("Escape", "P") {
            ih.Stop()
            ShowHint("Cancelado", 1200, "warn")
            return
        }

        if (ih.InProgress = 0) {
            k := ih.EndKey
            if (k = "Escape") {
                ShowHint("Cancelado", 1200, "warn")
                return
            }
            if (k != "") {
                resultado := _ModsPressionados() . _NormalizarTecla(k)
                break
            }
        }

        for btn in ["XButton1", "XButton2", "MButton"] {
            if GetKeyState(btn, "P") {
                resultado := _ModsPressionados() . btn
                ih.Stop()
                while GetKeyState(btn, "P")
                    Sleep(10)
                break 2
            }
        }
    }

    if (resultado = "") {
        ShowHint("Nenhuma tecla detectada", 1000, "warn")
        return
    }

    if !_SalvarTeclaCapturada(configSection, configKey, resultado, label)
        return

    if IsObject(uiText)
        uiText.Value := label ": [ " _ComboDisplay(resultado) " ]"
}

_NormalizarTecla(k) {
    if (k ~= "^[A-Za-z]$")
        return StrLower(k)
    return k
}

; Exibição legível de uma tecla, com modificadores por extenso:
; "^+y" → "CTRL + SHIFT + Y". A tecla precisa sobrar depois do prefixo,
; então uma tecla que seja o próprio "^" não é confundida com Ctrl.
_ComboDisplay(tecla) {
    if !RegExMatch(tecla, "^([\^!+]*)(.+)$", &m)
        return StrUpper(tecla)
    txt := ""
    if InStr(m[1], "^")
        txt .= "CTRL + "
    if InStr(m[1], "!")
        txt .= "ALT + "
    if InStr(m[1], "+")
        txt .= "SHIFT + "
    return txt . StrUpper(m[2])
}
