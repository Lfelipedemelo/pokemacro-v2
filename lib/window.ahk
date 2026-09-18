; =====================================================
; lib\window.ahk — Persistência e drag da janela principal
; =====================================================

DragJanela(*) {
    PostMessage(0xA1, 2,,, "A")
}

SalvarPosicaoJanela() {
    global myGui, configFile

    if !myGui
        return

    WinGetPos(&x, &y,,, "ahk_id " myGui.Hwnd)
    IniWrite(x, configFile, "Janela", "posX")
    IniWrite(y, configFile, "Janela", "posY")
}

CarregarPosicaoJanela() {
    global configFile

    x := IniRead(configFile, "Janela", "posX", "")
    y := IniRead(configFile, "Janela", "posY", "")

    return (x != "" && y != "") ? "x" x " y" y : "Center"
}
