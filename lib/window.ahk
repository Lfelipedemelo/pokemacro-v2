; =====================================================
; lib\window.ahk — Helpers de janela compartilhados pela HUD
;                  (ui\mini_menu.ahk) e telas de config
;                  (lib\gdip_config.ahk)
; =====================================================

global JOGO_EXE := "pxgme.exe"

JogoAtivo() {
    return WinActive("ahk_exe " JOGO_EXE)
}

; Arrasta a janela 'hwnd' como se o clique fosse na barra de título
; (WM_NCLBUTTONDOWN com HTCAPTION). Recebe o hwnd em vez de usar a janela
; ativa: a HUD não se ativa ao ser clicada (WS_EX_NOACTIVATE), então a
; ativa ali é o jogo — e a mensagem iria para ele.
DragJanela(hwnd) {
    PostMessage(0xA1, 2,,, "ahk_id " hwnd)
}

; Mostra uma janela sem ativá-la (SW_SHOWNOACTIVATE). WinShow usa SW_SHOW,
; que pode tirar o foco do jogo — e com o jogo fora de foco as hotkeys dos
; macros param e o combo em andamento é interrompido.
Win_MostrarSemAtivar(hwnd) {
    DllCall("ShowWindow", "Ptr", hwnd, "Int", 4)
}

; Pede ao Windows um WM_MOUSELEAVE quando o cursor sair da janela.
Win_ArmarMouseLeave(hwnd) {
    tme := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("UInt", tme.Size, tme, 0)
    NumPut("UInt", 2,        tme, 4)  ; TME_LEAVE
    NumPut("Ptr",  hwnd,     tme, 8)
    DllCall("TrackMouseEvent", "Ptr", tme)
}

; Extrai (x, y) com sinal de um lParam de mensagem de mouse/WM_MOVE.
Win_DecodeXY(lParam) {
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    if (x > 32767)
        x -= 65536
    if (y > 32767)
        y -= 65536
    return [x, y]
}

; ─── Jogo rodando como administrador ───────────────────
; Se o jogo roda elevado e o script não, o Windows bloqueia hotkeys e
; Send para a janela do jogo (UIPI) — os macros simplesmente "não
; funcionam", sem erro nenhum. Checa uma vez por processo do jogo e
; oferece reiniciar o script como administrador.
VerificarElevacaoJogo() {
    static pidsChecados := Map()
    if A_IsAdmin
        return
    pid := ProcessExist(JOGO_EXE)
    if (!pid || pidsChecados.Has(pid))
        return
    pidsChecados[pid] := true

    if !_ProcessoEhElevado(pid)
        return

    r := MsgBox("O PokéXGames está rodando como administrador, mas o macro não."
        . "`n`nNessa situação o Windows bloqueia as teclas enviadas pelo macro."
        . "`n`nReiniciar o macro como administrador agora?",
        "PokeMacro", "YesNo Icon! 0x40000")
    if (r = "Yes") {
        try {
            Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
            ExitApp()
        } catch {
            ShowHint("Não foi possível reiniciar como administrador", 1800, "danger")
        }
    }
}

; true se o processo roda elevado. Sem privilégio, o próprio acesso ao
; token de um processo elevado é negado — o que também indica elevação.
_ProcessoEhElevado(pid) {
    hProc := DllCall("OpenProcess", "UInt", 0x1000, "Int", 0, "UInt", pid, "Ptr")  ; PROCESS_QUERY_LIMITED_INFORMATION
    if !hProc
        return false
    elevado := false
    if DllCall("advapi32\OpenProcessToken", "Ptr", hProc, "UInt", 0x0008, "Ptr*", &hTok := 0) {  ; TOKEN_QUERY
        buf := Buffer(4, 0)
        if DllCall("advapi32\GetTokenInformation", "Ptr", hTok, "Int", 20, "Ptr", buf, "UInt", 4, "UInt*", &ret := 0)  ; TokenElevation
            elevado := NumGet(buf, 0, "UInt") != 0
        DllCall("CloseHandle", "Ptr", hTok)
    } else {
        elevado := (A_LastError = 5)   ; ERROR_ACCESS_DENIED
    }
    DllCall("CloseHandle", "Ptr", hProc)
    return elevado
}
