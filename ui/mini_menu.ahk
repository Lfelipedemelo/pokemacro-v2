; =====================================================
; ui\mini_menu.ahk — HUD compacta (GDI+, cantos arredondados,
;                    hover e transições reais)
; =====================================================
;
; Substitui o antigo mini-menu (retângulos chapados) por uma barra
; flutuante desenhada com GDI+ numa janela em camadas: hover com
; realce animado + tooltip, estado ativo com anel de brilho pulsante,
; e um painel-resumo que expande/recolhe com transição de altura.
;
; É a interface principal do app: abre/fecha com Ctrl+F12 (pokemacro.ahk).
; O painel expandido (chevron) mostra um botão ⚙ por macro que abre a
; tela de configuração específica daquele macro.
;
; API pública mantida para o resto do app:
;   global miniGui          — objeto Gui quando aberta, 0 quando fechada
;   AbrirMiniMenu()          — abre/fecha (chamado pelo Ctrl+F12 e pelo botão ⚙ interno)
;   _RecriarMini()           — pede um redesenho (chamado quando um macro
;                              é ligado/desligado por outra tela, ou o tema muda)

global miniGui        := 0
global _hudX          := 0
global _hudY          := 0
global _hudExpanded   := false
global _hudExpandT    := 0.0
global _hudBarHover   := false  ; true enquanto o mouse está sobre a barra — engrenagem/expandir/fechar só existem nesse momento
global _hudHoverId    := ""
global _hudHoverT     := Map()
global _hudBoxes      := []
global _hudVisibleCache := 0   ; cache de _HudVisibleItems() — ver comentário lá
global _hudEventHook    := 0   ; handle do hook de EVENT_SYSTEM_FOREGROUND (ver _HudRegistrarHook)
global _hudEventCb      := 0   ; ponteiro do callback, criado uma única vez

; Fator de escala da HUD ("TAMANHO DA INTERFACE" em Configurações Gerais,
; ver EscalaFator em lib\globals.ahk). Diferente das telas de config
; (lib\gdip_config.ahk), que escalam o Graphics inteiro com uma
; transformação, aqui multiplicamos as constantes de layout ANTES de
; desenhar (ver _HudRedraw): a HUD anima a até 60fps (_HudFxTick), e um
; ícone cacheado (Gdip_ScaledIcon) já nasce no tamanho final pedido —
; com transformação de canvas ele seria desenhado nesse tamanho e DEPOIS
; esticado de novo pelo GDI+ (HighQualityBicubic) a cada frame. Mudando
; o tamanho pedido ao cache em vez disso, o recorte caro roda uma única
; vez por tamanho (na primeira vez que a escala muda), não por frame.
global _HUD_SCALE       := EscalaFator()

; ── Tecla configurada de cada macro, para o tooltip da barra ──
_KeyHint(tipo) {
    cfg := GetCfg(tipo)
    hk  := cfg["teclaHotkey"]
    return (hk != "N/A" && hk != "") ? StrUpper(hk) : ""
}

_KeyHintCooldown() {
    cfg := GetCfg("Cooldown")
    hk  := cfg["hotkeyCooldown"]
    return (hk != "N/A" && hk != "") ? StrUpper(hk) : ""
}

; ── Lista de macros exibidos na HUD ────────────────────
_HudMacroList() {
    return [
        Map("id", "c1", "nome", "comboPrincipal",  "label", "Combo Principal",  "secao", "comboPrincipal",  "cfg", (*) => AbrirConfigCombo("comboPrincipal")),
        Map("id", "c2", "nome", "comboSecundario", "label", "Combo Secundário", "secao", "comboSecundario", "cfg", (*) => AbrirConfigCombo("comboSecundario")),
        Map("id", "c3", "nome", "revive",          "label", "Reviver",          "secao", "Revive",          "cfg", (*) => AbrirTelaConfigRevive("revive")),
        Map("id", "c4", "nome", "comboRevive",     "label", "Combo Revive",     "secao", "comboRevive",     "cfg", (*) => AbrirConfigComboRevive()),
        Map("id", "c5", "nome", "cooldown",        "label", "Cooldown",         "secao", "Cooldown",        "cfg", (*) => AbrirConfigCooldown()),
    ]
}

; Lê o INI (showInMini de cada macro) e recacheia. Só precisa rodar quando
; a HUD abre ou quando o toggle "EXIBIR NO MINI MENU" muda na config geral
; (_RecriarMini chama isso) — nunca a cada frame (ver _HudVisibleItems).
_HudAtualizarVisibleItems() {
    global _hudVisibleCache
    out := []
    for m in _HudMacroList()
        if GetShowInMini(m["secao"])
            out.Push(m)
    _hudVisibleCache := out
}

; Igual aos ícones (_HudIconImg): _HudRedraw roda a 60fps durante hover/
; expandir/pulso, e IniRead é I/O de arquivo — reler 5 seções do INI em
; todo frame era a mesma classe de lentidão que já resolvemos pros ícones.
; Devolve a lista cacheada; quem muda o INI é responsável por chamar
; _HudAtualizarVisibleItems() (abrir a HUD, ou _RecriarMini).
_HudVisibleItems() {
    global _hudVisibleCache
    if !_hudVisibleCache
        _HudAtualizarVisibleItems()
    return _hudVisibleCache
}

; ── Abrir / fechar ──────────────────────────────────────
AbrirMiniMenu() {
    global miniGui
    if (miniGui) {
        _HudFechar()
        return
    }
    _HudAbrir()
}

_HudAbrir() {
    global miniGui, _hudX, _hudY, _hudExpanded, _hudExpandT, _hudHoverId, _hudHoverT, _hudBarHover

    Gdip_EnsureStarted()

    _hudHoverId := ""
    _hudHoverT  := Map()
    _hudBarHover := false
    _hudExpanded := (IniRead(configFile, "MiniMenu", "expandido", "1") = "1")
    _hudExpandT  := _hudExpanded ? 1.0 : 0.0
    _HudAtualizarVisibleItems()

    pos := _HudCarregarPos()
    _hudX := pos[1]
    _hudY := pos[2]

    miniGui := Gui("-Caption +ToolWindow +AlwaysOnTop +E0x80000")
    miniGui.Show("x" _hudX " y" _hudY " w10 h10 NoActivate Hide")
    WinShow("ahk_id " miniGui.Hwnd)

    OnMessage(0x200, _HudWM_MouseMove)  ; WM_MOUSEMOVE
    OnMessage(0x201, _HudWM_LButtonDown) ; WM_LBUTTONDOWN
    OnMessage(0x2A3, _HudWM_MouseLeave)  ; WM_MOUSELEAVE
    OnMessage(0x0003, _HudWM_Move)       ; WM_MOVE

    _HudRedraw()
    SetTimer(_HudPulseTick, 80)
    _HudVisibilidade()      ; aplica visibilidade inicial
    _HudRegistrarHook()     ; e depois só reavalia quando a janela ativa mudar
}

_HudFechar() {
    global miniGui
    if (!miniGui)
        return
    _HudSalvarPos()
    SetTimer(_HudPulseTick, 0)
    SetTimer(_HudFxTick, 0)
    _HudRemoverHook()
    try miniGui.Destroy()
    miniGui := 0
}

; Chamado pelo resto do app quando um macro muda de estado em outra tela,
; ou quando o toggle "EXIBIR NO MINI MENU" muda na config geral — por
; isso recacheia a lista de visíveis antes de redesenhar.
_RecriarMini() {
    global miniGui
    if (miniGui) {
        _HudAtualizarVisibleItems()
        _HudRedraw()
    }
}

_HudCarregarPos() {
    global configFile
    x := IniRead(configFile, "MiniMenu", "posX", "")
    y := IniRead(configFile, "MiniMenu", "posY", "")
    if (x = "" || y = "")
        return [A_ScreenWidth - 420, 40]
    return [Integer(x), Integer(y)]
}

_HudSalvarPos() {
    global miniGui, configFile
    if !miniGui
        return
    try {
        WinGetPos(&x, &y, , , "ahk_id " miniGui.Hwnd)
        IniWrite(x, configFile, "MiniMenu", "posX")
        IniWrite(y, configFile, "MiniMenu", "posY")
    }
}

; Oculta a HUD quando o jogo não está em foco (mesmo comportamento de antes).
; Recebe o hwnd da janela que acabou de virar ativa (via _HudOnForegroundChange);
; se vier vazio (chamada manual, ex. ao abrir a HUD), descobre a janela ativa na hora.
_HudVisibilidade(hwndAtivo := 0) {
    global miniGui, _macroExecutando, executandoCooldown
    if !miniGui
        return
    if (_macroExecutando || executandoCooldown)
        return
    try {
        if (!hwndAtivo)
            hwndAtivo := WinGetID("A")
        exeAtivo  := WinGetProcessName("ahk_id " hwndAtivo)
        visivel   := (exeAtivo = "pxgme.exe" || exeAtivo = "AutoHotkey64.exe" || exeAtivo = "AutoHotkey.exe")
        if visivel
            WinShow("ahk_id " miniGui.Hwnd)
        else
            WinHide("ahk_id " miniGui.Hwnd)
    }
}

; ── Detecção de troca de janela ativa (sem polling) ────────
; Antes isso rodava num SetTimer de 100ms pra sempre, reavaliando a janela
; ativa mesmo quando nada mudava. O Windows já notifica exatamente quando o
; foreground muda (EVENT_SYSTEM_FOREGROUND), então usamos um WinEventHook:
; zero custo enquanto o jogador não troca de janela, e reação imediata
; (sem até 100ms de atraso) quando troca.
_HudRegistrarHook() {
    global _hudEventHook, _hudEventCb
    if (_hudEventHook)
        return
    if (!_hudEventCb)
        _hudEventCb := CallbackCreate(_HudOnForegroundChange, "", 7)
    ; SetWinEventHook(eventMin, eventMax, hmodWinEventProc, pfnWinEventProc, idProcess, idThread, dwFlags)
    _hudEventHook := DllCall("SetWinEventHook", "UInt", 0x3, "UInt", 0x3, "Ptr", 0, "Ptr", _hudEventCb, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
}

_HudRemoverHook() {
    global _hudEventHook
    if (_hudEventHook) {
        DllCall("UnhookWinEvent", "Ptr", _hudEventHook)
        _hudEventHook := 0
    }
}

_HudOnForegroundChange(hHook, event, hwnd, idObject, idChild, idThread, msEventTime) {
    _HudVisibilidade(hwnd)
}

; ── Entrada do mouse / clique ───────────────────────────
_HudArmarSaida(hwnd) {
    tme := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("UInt", tme.Size, tme, 0)
    NumPut("UInt", 2,        tme, 4)  ; TME_LEAVE
    NumPut("Ptr",  hwnd,     tme, 8)
    DllCall("TrackMouseEvent", "Ptr", tme)
}

_HudDecodeXY(lParam) {
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    if (x > 32767)
        x -= 65536
    if (y > 32767)
        y -= 65536
    return [x, y]
}

_HudHitTest(x, y) {
    global _hudBoxes
    for b in _hudBoxes {
        if (b.HasOwnProp("r")) {
            dx := x - b.cx, dy := y - b.cy
            if (dx * dx + dy * dy <= b.r * b.r)
                return b
        } else {
            if (x >= b.x && x <= b.x + b.w && y >= b.y && y <= b.y + b.h)
                return b
        }
    }
    return 0
}

_HudWM_MouseMove(wParam, lParam, msg, hwnd) {
    global miniGui, _hudHoverId, _hudBarHover
    if (!miniGui || hwnd != miniGui.Hwnd)
        return
    _HudArmarSaida(hwnd)
    ; WM_MOUSEMOVE só chega enquanto o cursor está sobre a janela da HUD,
    ; então essa borda (false → true) é o sinal de "entrou na barra" —
    ; usado para só então desenhar engrenagem/expandir/fechar. Redesenha
    ; uma vez aqui (não a cada pixel), o resto do frame já ia rodar de
    ; qualquer forma pelo hit-test de hover abaixo.
    if (!_hudBarHover) {
        _hudBarHover := true
        _HudRedraw()
    }
    xy := _HudDecodeXY(lParam)
    box := _HudHitTest(xy[1], xy[2])
    novoId := box ? box.id : ""
    if (novoId != _hudHoverId) {
        _hudHoverId := novoId
        _HudStartFx()
    }
}

; A janela é movida pelo próprio OS quando o usuário arrasta a barra de
; título "falsa" (drag pelo truque de WM_NCLBUTTONDOWN em lib\window.ahk).
; Sem isso, _hudX/_hudY ficam com a posição antiga e o próximo redesenho
; (hover, pulso do macro ativo etc.) puxaria a janela de volta ao lugar salvo.
_HudWM_Move(wParam, lParam, msg, hwnd) {
    global miniGui, _hudX, _hudY
    if (!miniGui || hwnd != miniGui.Hwnd)
        return
    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF
    if (x > 32767)
        x -= 65536
    if (y > 32767)
        y -= 65536
    _hudX := x
    _hudY := y
}

_HudWM_MouseLeave(wParam, lParam, msg, hwnd) {
    global miniGui, _hudHoverId, _hudBarHover
    if (!miniGui || hwnd != miniGui.Hwnd)
        return
    _hudHoverId := ""
    _hudBarHover := false   ; sai da barra: some com gear/expandir/fechar
    _HudRedraw()
}

_HudWM_LButtonDown(wParam, lParam, msg, hwnd) {
    global miniGui
    if (!miniGui || hwnd != miniGui.Hwnd)
        return
    xy := _HudDecodeXY(lParam)
    box := _HudHitTest(xy[1], xy[2])
    if (box)
        _HudActivar(box)
    else
        DragJanela()   ; clique fora de qualquer ícone: arrasta a barra pelo fundo
}

_HudActivar(box) {
    global _hudExpanded, configFile
    switch box.kind {
        case "gear":    AbrirConfigGeral()
        case "chevron":
            _hudExpanded := !_hudExpanded
            IniWrite(_hudExpanded ? "1" : "0", configFile, "MiniMenu", "expandido")
            _HudStartFx()
        ; Fechar é adiado para fora do handler de WM_LBUTTONDOWN: destruir a
        ; janela enquanto ainda se está dentro do próprio despacho de
        ; mensagens dela causa erro (reentrância). Ctrl+F12 fecha direto
        ; porque roda numa thread de hotkey, sem esse problema.
        case "close":   SetTimer(_HudFechar, -1)
        case "macro":   _HudToggleMacro(box.nome)
        case "cfg":     box.cfgFn()
    }
}

; ── Toggle de macro (mesma regra de exclusividade das outras telas) ──
_HudToggleMacro(nome) {
    global macros, uiRefs

    macros[nome] := !macros[nome]

    if (macros[nome] && (nome = "comboPrincipal" || nome = "comboSecundario" || nome = "comboRevive")) {
        for outro in ["comboPrincipal", "comboSecundario", "comboRevive"] {
            if (outro != nome && macros[outro]) {
                macros[outro] := false
                if uiRefs.Has(outro)
                    try AtualizarVisual(uiRefs[outro], false)
            }
        }
    }

    if uiRefs.Has(nome)
        try AtualizarVisual(uiRefs[nome], macros[nome])

    AtualizarHotkeyCombo()
    _HudRedraw()
}

; ── Animação ─────────────────────────────────────────────
_HudStartFx() {
    SetTimer(_HudFxTick, 16)
}

_HudFxTick() {
    global _hudHoverId, _hudHoverT, _hudExpandT, _hudExpanded

    ativo := false
    speed := 0.28

    for id, hv in _hudHoverT.Clone() {
        alvo := (id = _hudHoverId) ? 1.0 : 0.0
        nt := hv + (alvo - hv) * speed
        if (Abs(alvo - nt) < 0.01)
            nt := alvo
        _hudHoverT[id] := nt
        if (nt != alvo)
            ativo := true
    }
    if (_hudHoverId != "" && !_hudHoverT.Has(_hudHoverId)) {
        _hudHoverT[_hudHoverId] := speed
        ativo := true
    }

    alvoExp := _hudExpanded ? 1.0 : 0.0
    nt := _hudExpandT + (alvoExp - _hudExpandT) * 0.25
    if (Abs(alvoExp - nt) < 0.01)
        nt := alvoExp
    if (nt != _hudExpandT)
        ativo := true
    _hudExpandT := nt

    _HudRedraw()

    if (!ativo)
        SetTimer(_HudFxTick, 0)
}

_HudPulseTick() {
    global macros
    if (macros["comboPrincipal"] || macros["comboSecundario"] || macros["revive"] || macros["comboRevive"] || macros["cooldown"])
        _HudRedraw()
}

; ── Ícone real (mesmos .png usados na janela principal) ───
; Tamanho fixo por contexto (barra / linha do painel): permite cachear o
; ícone já reamostrado uma única vez em vez de escalar em alta qualidade
; a cada frame, que era a maior causa de lentidão nas animações.
_HudIconImg(nome, size) {
    global icons
    return Gdip_ScaledIcon(A_ScriptDir "\" icons[nome], size)
}

_HudDrawMiniBtn(g, kind, cx, cy, d, hoverT, expandido := false) {
    global _HUD_SCALE
    scale := _HUD_SCALE

    r := d / 2 + hoverT * 1.5 * scale
    bg := Gdip_LerpArgb(255, "0x16131b", "0x2a2632", hoverT)
    brush := Gdip_BrushSolid(bg)
    Gdip_FillEllipse(g, brush, cx - r, cy - r, r * 2, r * 2)
    Gdip_DeleteBrush(brush)

    col := Gdip_LerpArgb(255, "0x65636d", "0xe8e6ec", hoverT)
    if (kind = "close")
        col := Gdip_LerpArgb(255, "0x65636d", "0xff8484", hoverT)
    pen := Gdip_Pen(col, 1.6 * scale)

    armLen := d * 0.22
    switch kind {
        case "gear":
            ; Ícone de engrenagem pronto (icons\gear.png, recolorido para
            ; cinza claro), reamostrado e cacheado uma vez por tamanho — mesmo
            ; mecanismo dos ícones dos macros (_HudIconImg), sem custo de
            ; desenho vetorial por frame.
            iconSz := Round(d * 0.62)
            Gdip_DrawImage(g, Gdip_ScaledIcon(A_ScriptDir "\icons\gear.png", iconSz),
                cx - iconSz / 2, cy - iconSz / 2, iconSz, iconSz)
        case "chevron":
            y1 := expandido ? cy + armLen * 0.5 : cy - armLen * 0.3
            y2 := expandido ? cy - armLen * 0.3 : cy + armLen * 0.5
            Gdip_DrawLine(g, pen, cx - armLen, y1, cx, y2)
            Gdip_DrawLine(g, pen, cx, y2, cx + armLen, y1)
        case "close":
            Gdip_DrawLine(g, pen, cx - armLen, cy - armLen, cx + armLen, cy + armLen)
            Gdip_DrawLine(g, pen, cx - armLen, cy + armLen, cx + armLen, cy - armLen)
    }
    Gdip_DeletePen(pen)
}

; ── Desenho principal ────────────────────────────────────
_HudRedraw() {
    global miniGui, _hudX, _hudY, _hudExpandT, _hudExpanded, _hudHoverT, _hudBoxes, macros, _HUD_SCALE, _hudBarHover
    Critical "On"

    if (!miniGui) {
        Critical "Off"
        return
    }
    hudHwnd := miniGui.Hwnd

    accent := T()["ACCENT"]
    items  := _HudVisibleItems()
    s      := _HUD_SCALE

    PAD := Round(14*s), GAP := Round(10*s), BTN_D := Round(36*s), MINI_D := Round(22*s), SEP_H := Round(22*s)
    BAR_H := Round(58*s)
    ICON_BAR_SZ := Round(34*s), ICON_ROW_SZ := Round(20*s)

    cx := PAD
    barCY := BAR_H // 2

    boxes    := []
    barIcons := []

    for m in items {
        hk := "bar_" m["id"]
        hv := _hudHoverT.Has(hk) ? _hudHoverT[hk] : 0
        r  := BTN_D / 2 + hv * 2 * s
        thisCx := cx + BTN_D / 2
        boxes.Push({ id: hk, kind: "macro", nome: m["nome"], cx: thisCx, cy: barCY, r: BTN_D / 2 + 3 })
        barIcons.Push({ m: m, cx: thisCx, cy: barCY, r: r, hoverT: hv })
        cx += BTN_D + GAP
    }

    ; Separador + engrenagem/expandir/fechar só existem enquanto o mouse
    ; está sobre a barra (_hudBarHover) — no jogo, quase sempre só se quer
    ; ligar/desligar um macro pelos ícones da esquerda, então esse grupo
    ; nem ocupa espaço fora do hover.
    mostrarCluster := _hudBarHover
    sepX := 0
    gearCx := 0, chevCx := 0, closeCx := 0
    tGear := 0, tChev := 0, tClose := 0

    if (mostrarCluster) {
        cx += 2
        sepX := cx
        cx += 1 + GAP

        tGear := _hudHoverT.Has("gear") ? _hudHoverT["gear"] : 0
        gearCx := cx + MINI_D / 2
        boxes.Push({ id: "gear", kind: "gear", cx: gearCx, cy: barCY, r: MINI_D / 2 + 3 })
        cx += MINI_D + 6

        tChev := _hudHoverT.Has("chevron") ? _hudHoverT["chevron"] : 0
        chevCx := cx + MINI_D / 2
        boxes.Push({ id: "chevron", kind: "chevron", cx: chevCx, cy: barCY, r: MINI_D / 2 + 3 })
        cx += MINI_D + 6

        tClose := _hudHoverT.Has("close") ? _hudHoverT["close"] : 0
        closeCx := cx + MINI_D / 2
        boxes.Push({ id: "close", kind: "close", cx: closeCx, cy: barCY, r: MINI_D / 2 + 3 })
        cx += MINI_D
    }

    winW := cx + PAD

    ROW_H := Round(28*s), ROW_GAP := Round(4*s), PANEL_PAD := Round(10*s), HEADER_H := Round(18*s)
    nRows := items.Length
    panelFullH := (nRows > 0) ? (PANEL_PAD * 2 + HEADER_H + nRows * ROW_H + (nRows - 1) * ROW_GAP) : 0

    ease := _hudExpandT * _hudExpandT * (3 - 2 * _hudExpandT)   ; smoothstep
    panelH := Round(panelFullH * ease)
    mostrarPainel := (panelH > 2) && (nRows > 0)

    winH := BAR_H + panelH

    GEAR_D := Round(20*s)

    panelRows := []
    if (mostrarPainel) {
        py := BAR_H + PANEL_PAD + HEADER_H
        for m in items {
            avail := winH - py
            if (avail < 6)
                break
            rh := Min(ROW_H, avail)
            rowCy := py + rh / 2
            dotCx := winW - PAD - Round(8*s)
            rowGearCx := dotCx - Round(10*s) - GEAR_D / 2

            ; botão de configurações fica acima na lista de boxes para ter
            ; prioridade no hit-test sobre a linha inteira (que também é clicável)
            boxes.Push({ id: "cfg_" m["id"], kind: "cfg", cfgFn: m["cfg"], cx: rowGearCx, cy: rowCy, r: GEAR_D / 2 + 3 })
            boxes.Push({ id: "row_" m["id"], kind: "macro", nome: m["nome"], x: PAD, y: py, w: winW - PAD * 2, h: rh })
            panelRows.Push({ m: m, y: py, h: rh, cy: rowCy, gearCx: rowGearCx, dotCx: dotCx })
            py += ROW_H + ROW_GAP
        }
    }

    _hudBoxes := boxes

    winW := Max(winW, 10)
    winH := Max(winH, 10)
    canvas := Gdip_NewLayeredCanvas(winW, winH)
    g := canvas.pGraphics

    ; fundo + borda
    bgBrush := Gdip_BrushSolid(Gdip_Argb(240, "0x0f0d12"))
    Gdip_FillRoundRect(g, bgBrush, 0, 0, winW, winH, 16*s)
    Gdip_DeleteBrush(bgBrush)

    borderPen := Gdip_Pen(Gdip_Argb(255, "0x241f2c"), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, winW - 1, winH - 1, 16*s)
    Gdip_DeletePen(borderPen)

    ; ícones da barra
    for it in barIcons {
        m := it.m
        ligado := macros[m["nome"]]
        hoverT := it.hoverT

        fillArgb := ligado
            ? Gdip_LerpArgb(255, "0x1b1720", accent, 0.24)
            : Gdip_LerpArgb(255, "0x1b1720", "0x2a2632", hoverT)

        if (ligado) {
            fase := Mod(A_TickCount, 1600) / 1600
            glowA := Round(30 + 30 * (0.5 + 0.5 * Sin(fase * 2 * 3.14159265)))
            glowBrush := Gdip_BrushSolid(Gdip_Argb(glowA, accent))
            Gdip_FillEllipse(g, glowBrush, it.cx - it.r - 5*s, it.cy - it.r - 5*s, (it.r + 5*s) * 2, (it.r + 5*s) * 2)
            Gdip_DeleteBrush(glowBrush)
        }

        circBrush := Gdip_BrushSolid(fillArgb)
        Gdip_FillEllipse(g, circBrush, it.cx - it.r, it.cy - it.r, it.r * 2, it.r * 2)
        Gdip_DeleteBrush(circBrush)

        ringArgb := ligado ? Gdip_Argb(255, accent) : Gdip_Argb(Round(50 + hoverT * 110), "0x4a4552")
        ringPen := Gdip_Pen(ringArgb, (ligado ? 2 : 1) * s)
        Gdip_DrawEllipse(g, ringPen, it.cx - it.r, it.cy - it.r, it.r * 2, it.r * 2)
        Gdip_DeletePen(ringPen)

        Gdip_DrawImage(g, _HudIconImg(m["nome"], ICON_BAR_SZ),
            it.cx - ICON_BAR_SZ / 2, it.cy - ICON_BAR_SZ / 2, ICON_BAR_SZ, ICON_BAR_SZ)

        if (hoverT > 0.02) {
            hint := (m["nome"] = "cooldown") ? _KeyHintCooldown() : _KeyHint(m["nome"])
            label := m["label"] . (hint != "" ? "  ·  " hint : "")
            tw := StrLen(label) * 6.4*s + 20*s
            tipH := Round(22*s)
            tx := it.cx - tw / 2
            ty := it.cy - it.r - 32*s

            tipBg := Gdip_BrushSolid(Gdip_Argb(Round(235 * hoverT), "0x0a090c"))
            Gdip_FillRoundRect(g, tipBg, tx, ty, tw, tipH, 6*s)
            Gdip_DeleteBrush(tipBg)

            Gdip_DrawText(g, label, 10*s, true, Gdip_Argb(Round(255 * hoverT), "0xe8e6ec"), tx, ty, tw, tipH, true)
        }
    }

    ; separador vertical + botões auxiliares — só existem com o mouse sobre a barra
    if (mostrarCluster) {
        sepPen := Gdip_Pen(Gdip_Argb(255, "0x221f27"), 1)
        Gdip_DrawLine(g, sepPen, sepX, barCY - SEP_H / 2, sepX, barCY + SEP_H / 2)
        Gdip_DeletePen(sepPen)

        _HudDrawMiniBtn(g, "gear",    gearCx,  barCY, MINI_D, tGear)
        _HudDrawMiniBtn(g, "chevron", chevCx,  barCY, MINI_D, tChev, _hudExpanded)
        _HudDrawMiniBtn(g, "close",   closeCx, barCY, MINI_D, tClose)
    }

    ; painel-resumo
    if (mostrarPainel) {
        sepPen2 := Gdip_Pen(Gdip_Argb(Round(255 * ease), "0x1c1a20"), 1)
        Gdip_DrawLine(g, sepPen2, PAD * 0.5, BAR_H, winW - PAD * 0.5, BAR_H)
        Gdip_DeletePen(sepPen2)

        if (ease > 0.4)
            Gdip_DrawText(g, "RESUMO RÁPIDO", 9*s, true, Gdip_Argb(Round(190 * ((ease - 0.4) / 0.6)), "0x65636d"),
                PAD, BAR_H + PANEL_PAD - 2*s, winW - PAD * 2, HEADER_H, false)

        for pr in panelRows {
            m := pr.m
            ligado := macros[m["nome"]]
            y := pr.y, h := pr.h

            if (ligado) {
                rowBg := Gdip_BrushSolid(Gdip_Argb(46, accent))
                Gdip_FillRoundRect(g, rowBg, PAD, y, winW - PAD * 2, h, 8*s)
                Gdip_DeleteBrush(rowBg)
            }

            icoSz := Round(24*s)
            icoY := y + (h - icoSz) / 2
            icoBg := ligado ? Gdip_LerpArgb(255, "0x201e24", accent, 0.26) : Gdip_Argb(255, "0x201e24")
            icoBrush := Gdip_BrushSolid(icoBg)
            Gdip_FillRoundRect(g, icoBrush, PAD + 4*s, icoY, icoSz, icoSz, 6*s)
            Gdip_DeleteBrush(icoBrush)

            imgPad := 2*s
            Gdip_DrawImage(g, _HudIconImg(m["nome"], ICON_ROW_SZ), PAD + 4*s + imgPad, icoY + imgPad, ICON_ROW_SZ, ICON_ROW_SZ)

            labelX := PAD + 4*s + icoSz + 10*s
            labelW := pr.gearCx - GEAR_D / 2 - 8*s - labelX
            Gdip_DrawText(g, m["label"], 11*s, true,
                ligado ? Gdip_Argb(255, "0xf2f0f5") : Gdip_Argb(255, "0xdcdae0"),
                labelX, y, labelW, h, false)

            tCfg := _hudHoverT.Has("cfg_" m["id"]) ? _hudHoverT["cfg_" m["id"]] : 0
            _HudDrawMiniBtn(g, "gear", pr.gearCx, pr.cy, GEAR_D, tCfg)

            dotR := 3*s
            dotCy := pr.cy
            dotArgb := ligado ? Gdip_Argb(255, accent) : Gdip_Argb(255, "0x4b4855")
            dotBrush := Gdip_BrushSolid(dotArgb)
            Gdip_FillEllipse(g, dotBrush, pr.dotCx - dotR, dotCy - dotR, dotR * 2, dotR * 2)
            Gdip_DeleteBrush(dotBrush)
        }
    }

    Gdip_PresentLayeredCanvas(canvas, hudHwnd, _hudX, _hudY)
    Gdip_DestroyLayeredCanvas(canvas)
    Critical "Off"
}
