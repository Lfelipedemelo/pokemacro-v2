; =====================================================
; lib\input.ahk — Captura de teclas e posições do mouse
; =====================================================

; Aguarda o usuário pressionar uma tecla/botão do mouse e salva no INI.
; Se 'uiText' for um objeto de controle, atualiza seu valor visual.
CapturarTecla(configSection, configKey, uiText := 0, label := "Tecla") {
    global configFile

    ShowHint("Pressione tecla ou botão do mouse (ESC cancela)", 999999)

    ih := InputHook("L0 E")
    ih.KeyOpt("{Escape}", "N")
    ih.KeyOpt("{All}", "E")
    ih.Start()

    tecla := ""

    Loop {
        Sleep(10)

        if GetKeyState("Escape", "P") {
            ih.Stop()
            ShowHint("Cancelado", 1200)
            return
        }

        key := ih.EndKey

        if (key = "Escape")
            continue

        if (key != "") {
            if (key ~= "i)^(Control|Shift|Alt|LControl|RControl|LShift|RShift|LAlt|RAlt)$")
                continue
            tecla := key
            break
        }

        for btn in ["LButton", "RButton", "XButton1", "XButton2"] {
            if GetKeyState(btn, "P") {
                tecla := btn
                break 2
            }
        }
    }

    ih.Stop()

    if (!tecla) {
        ShowHint("Nenhuma tecla detectada", 1000)
        return
    }

    IniWrite(tecla, configFile, configSection, configKey)

    if (configKey = "teclaHotkey")
        AtualizarHotkeyCombo()

    if IsObject(uiText)
        uiText.Value := label ": [ " StrUpper(tecla) " ]"

    ShowHint(label " salvo: " StrUpper(tecla), 1200)
}

; Aguarda um clique do mouse e salva as coordenadas no INI.
CapturarPosicaoMouse(secao, objetoTexto, chaveX := "clickX", chaveY := "clickY") {
    global configFile
    CoordMode("Mouse", "Screen")

    ShowHint("Clique no local desejado (ESC cancela)", 999999)

    ; Espera soltar o botão caso já esteja pressionado
    while GetKeyState("LButton", "P")
        Sleep(10)

    Loop {
        Sleep(10)

        if GetKeyState("Escape", "P") {
            ShowHint("Cancelado", 1200)
            return
        }

        if GetKeyState("LButton", "P") {
            MouseGetPos(&posX, &posY)
            break
        }
    }

    IniWrite(posX, configFile, secao, chaveX)
    IniWrite(posY, configFile, secao, chaveY)

    if IsSet(objetoTexto) && IsObject(objetoTexto)
        objetoTexto.Value := "Posição: [ " posX ", " posY " ]"

    ShowHint("Posição salva: " posX ", " posY, 1200)
}

; Captura UMA tecla de teclado OU um botão de mouse (sem modificadores).
; Usado para hotkeys de toggle — simples e confiável.
; Exemplos: "F5", "XButton1", "q", "F12"
CapturarCombo(configSection, configKey, uiText := 0, label := "Hotkey") {
    global configFile

    ShowHint("Pressione UMA tecla ou botão do mouse (ESC cancela)", 999999)

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
    ih.KeyOpt("{Escape}", "N")
    ih.KeyOpt("{LControl}{RControl}{LShift}{RShift}{LAlt}{RAlt}", "")
    ih.OnKeyDown := (ih, vk, sc) => _OnComboKey(ih, vk, sc)
    ih.Start()

    resultado := ""

    Loop {
        Sleep(10)

        if GetKeyState("Escape", "P") {
            ih.Stop()
            ShowHint("Cancelado", 1200)
            return
        }

        if (ih.InProgress = 0) {
            k := ih.EndKey
            if (k = "Escape") {
                ShowHint("Cancelado", 1200)
                return
            }
            if (k != "") {
                resultado := _NormalizarTecla(k)
                break
            }
        }

        for btn in ["XButton1", "XButton2", "MButton"] {
            if GetKeyState(btn, "P") {
                ih.Stop()
                resultado := btn
                while GetKeyState(btn, "P")
                    Sleep(10)
                break 2
            }
        }
    }

    if (resultado = "") {
        ShowHint("Nenhuma tecla detectada", 1000)
        return
    }

    IniWrite(resultado, configFile, configSection, configKey)
    AtualizarHotkeyCombo()

    if IsObject(uiText)
        uiText.Value := label ": [ " StrUpper(resultado) " ]"

    ShowHint(label ": " StrUpper(resultado), 1500)
}

_OnComboKey(ih, vk, sc) {
    nome := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
    if (nome ~= "i)^(Control|Shift|Alt|LControl|RControl|LShift|RShift|LAlt|RAlt|LWin|RWin)$")
        return
    ih.Stop()
}

_NormalizarTecla(k) {
    if (k ~= "^[A-Za-z]$")
        return StrLower(k)
    return k
}

; Exibição legível de uma tecla (sem modificadores)
_ComboDisplay(tecla) {
    return StrUpper(tecla)
}
