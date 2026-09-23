; =====================================================
; ui\mini_menu.ahk — HUD compacta (GDI+, cantos arredondados,
;                    hover e transições reais)
; =====================================================
;
; Substitui o antigo mini-menu (retângulos chapados) por uma barra
; flutuante desenhada com GDI+ numa janela em camadas: hover com
; realce animado + tooltip e estado ativo com anel de brilho pulsante.
;
; É a interface principal do app: abre/fecha com Ctrl+F12 (pokemacro.ahk).
; Com o mouse sobre a barra aparece um botão ⚙ ao lado (vertical) ou
; abaixo (horizontal) de cada ícone, que abre a tela de configuração
; daquele macro, além do ⚙ geral e do ✕.
;
; API pública mantida para o resto do app:
;   global miniGui          — objeto Gui quando aberta, 0 quando fechada
;   AbrirMiniMenu()          — abre/fecha (chamado pelo Ctrl+F12 e pelo botão ⚙ interno)
;   _RecriarMini()           — pede um redesenho (chamado quando um macro
;                              é ligado/desligado por outra tela, ou o tema muda)

global miniGui        := 0
global _hudX          := 0
global _hudY          := 0
global _hudBarHover   := false  ; true enquanto o mouse está sobre a barra — engrenagens/fechar só existem nesse momento
global _hudHoverId    := ""
global _hudHoverT     := Map()
global _hudBoxes      := []
global _hudVisibleCache := 0   ; cache de _HudVisibleItems() — ver comentário lá
global _hudCanvas       := 0   ; canvas GDI+ persistente entre frames (ver Gdip_ResizeCanvas em lib\gdip.ahk)
global _hudEventHook    := 0   ; handle do hook de EVENT_SYSTEM_FOREGROUND (ver _HudRegistrarHook)
global _hudEventCb      := 0   ; ponteiro do callback, criado uma única vez
global _hudVisivel      := true  ; false enquanto a HUD está escondida (jogo fora de foco) — o pulso não redesenha
global _hudDesenhando   := false ; trava de reentrância do _HudRedraw (ver comentário lá)
global _hudRedrawPendente := false

; Tooltip dos ícones da barra numa janela em camadas própria: desenhado no
; canvas da HUD ele ficava cortado, porque o canvas tem exatamente o tamanho
; da barra e o tooltip nasce acima dela (e, nas pontas, além das laterais).
; A janela é WS_EX_TRANSPARENT (cliques passam direto) e NOACTIVATE.
global _hudTipGui       := 0
global _hudTipCanvas    := 0
global _hudTipVisivel   := false
global _hudTipMedidas   := Map()   ; cache rótulo → largura medida (Gdip_MeasureText cria um Graphics por chamada)

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
; pulso, e IniRead é I/O de arquivo — reler 5 seções do INI em
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
    global miniGui, _hudX, _hudY, _hudHoverId, _hudHoverT, _hudBarHover, _hudVisivel

    Gdip_EnsureStarted()

    _hudHoverId := ""
    _hudHoverT  := Map()
    _hudBarHover := false
    _hudVisivel  := true   ; nasce visível; _HudVisibilidade abaixo corrige
    _HudAtualizarVisibleItems()

    pos := _HudCarregarPos()
    _hudX := pos[1]
    _hudY := pos[2]

    miniGui := Gui("-Caption +ToolWindow +AlwaysOnTop +E0x80000")
    miniGui.Show("x" _hudX " y" _hudY " w10 h10 NoActivate Hide")
    WinShow("ahk_id " miniGui.Hwnd)

    _HudTipCriar()

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
    global miniGui, _hudCanvas, _hudDesenhando
    if (!miniGui)
        return
    ; Um frame interrompido (ex.: Ctrl+F12 no meio do desenho) ainda está
    ; usando o canvas — adia o fechamento até ele terminar.
    if (_hudDesenhando) {
        SetTimer(_HudFechar, -15)
        return
    }
    _HudSalvarPos()
    SetTimer(_HudPulseTick, 0)
    SetTimer(_HudFxTick, 0)
    _HudRemoverHook()
    _HudTipDestruir()
    try miniGui.Destroy()
    miniGui := 0
    if (_hudCanvas) {
        Gdip_DestroyLayeredCanvas(_hudCanvas)
        _hudCanvas := 0
    }
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
    x := CfgLer("MiniMenu", "posX", "")
    y := CfgLer("MiniMenu", "posY", "")
    if !(IsInteger(x) && IsInteger(y))
        return [A_ScreenWidth - 420, 40]
    ; Se a resolução/monitor mudou, não deixa a HUD nascer fora da área
    ; visível. Usa a área virtual (todos os monitores), não só o principal,
    ; para não puxar de volta uma HUD deixada num segundo monitor.
    vx := SysGet(76), vy := SysGet(77), vw := SysGet(78), vh := SysGet(79)
    return [Max(vx, Min(Integer(x), vx + vw - 80)), Max(vy, Min(Integer(y), vy + vh - 80))]
}

_HudSalvarPos() {
    global miniGui
    if !miniGui
        return
    try {
        WinGetPos(&x, &y, , , "ahk_id " miniGui.Hwnd)
        SalvarCfg("MiniMenu", "posX", x)
        SalvarCfg("MiniMenu", "posY", y)
    }
}

; Oculta a HUD quando o jogo não está em foco (mesmo comportamento de antes).
; Recebe o hwnd da janela que acabou de virar ativa (via _HudOnForegroundChange);
; se vier vazio (chamada manual, ex. ao abrir a HUD), descobre a janela ativa na hora.
_HudVisibilidade(hwndAtivo := 0) {
    global miniGui, _macroExecutando, executandoCooldown, _hudVisivel
    if !miniGui
        return
    if (_macroExecutando || executandoCooldown)
        return
    try {
        if (!hwndAtivo)
            hwndAtivo := WinGetID("A")
        exeAtivo  := WinGetProcessName("ahk_id " hwndAtivo)
        visivel   := (exeAtivo = JOGO_EXE || exeAtivo ~= "i)^AutoHotkey")
        if visivel {
            WinShow("ahk_id " miniGui.Hwnd)
            if !_hudVisivel {
                _hudVisivel := true
                _HudRedraw()   ; o pulso não redesenhou enquanto estava escondida
            }
        } else {
            WinHide("ahk_id " miniGui.Hwnd)
            _hudVisivel := false
            _HudTipEsconder()
        }
        ; Jogo em foco: confere (uma vez por processo) se ele roda como
        ; admin e o macro não. Via timer, fora do callback do hook.
        if (exeAtivo = JOGO_EXE)
            SetTimer(VerificarElevacaoJogo, -1)
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
    Win_ArmarMouseLeave(hwnd)
    ; WM_MOUSEMOVE só chega enquanto o cursor está sobre a janela da HUD,
    ; então essa borda (false → true) é o sinal de "entrou na barra" —
    ; usado para só então desenhar engrenagens/fechar. Redesenha
    ; uma vez aqui (não a cada pixel), o resto do frame já ia rodar de
    ; qualquer forma pelo hit-test de hover abaixo.
    if (!_hudBarHover) {
        _hudBarHover := true
        _HudRedraw()
    }
    xy := Win_DecodeXY(lParam)
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
    xy := Win_DecodeXY(lParam)
    _hudX := xy[1]
    _hudY := xy[2]
}

_HudWM_MouseLeave(wParam, lParam, msg, hwnd) {
    global miniGui, _hudHoverId, _hudBarHover
    if (!miniGui || hwnd != miniGui.Hwnd)
        return
    _hudHoverId := ""
    _hudBarHover := false   ; sai da barra: some com engrenagens/fechar
    _HudRedraw()
}

_HudWM_LButtonDown(wParam, lParam, msg, hwnd) {
    global miniGui
    if (!miniGui || hwnd != miniGui.Hwnd)
        return
    xy := Win_DecodeXY(lParam)
    box := _HudHitTest(xy[1], xy[2])
    if (box)
        _HudActivar(box)
    else
        DragJanela()   ; clique fora de qualquer ícone: arrasta a barra pelo fundo
}

_HudActivar(box) {
    switch box.kind {
        case "gear":    AbrirConfigGeral()
        ; Fechar é adiado para fora do handler de WM_LBUTTONDOWN: destruir a
        ; janela enquanto ainda se está dentro do próprio despacho de
        ; mensagens dela causa erro (reentrância). Ctrl+F12 fecha direto
        ; porque roda numa thread de hotkey, sem esse problema.
        case "close":   SetTimer(_HudFechar, -1)
        case "macro":   AlternarMacro(box.nome)
        case "cfg":     box.cfgFn()
    }
}

; ── Animação ─────────────────────────────────────────────
_HudStartFx() {
    SetTimer(_HudFxTick, 16)
}

_HudFxTick() {
    global _hudHoverId, _hudHoverT

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

    _HudRedraw()

    if (!ativo)
        SetTimer(_HudFxTick, 0)
}

_HudPulseTick() {
    global macros, _hudVisivel
    if !_hudVisivel
        return
    if (macros["comboPrincipal"] || macros["comboSecundario"] || macros["revive"] || macros["comboRevive"] || macros["cooldown"])
        _HudRedraw()
}

; ── Ícone real (mesmos .png usados na janela principal) ───
; Tamanho fixo: permite cachear o ícone já reamostrado uma única vez em
; vez de escalar em alta qualidade a cada frame, que era a maior causa de
; lentidão nas animações.
_HudIconImg(nome, size) {
    global icons
    return Gdip_ScaledIcon(A_ScriptDir "\" icons[nome], size)
}

_HudDrawMiniBtn(g, kind, cx, cy, d, hoverT) {
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
        case "close":
            Gdip_DrawLine(g, pen, cx - armLen, cy - armLen, cx + armLen, cy + armLen)
            Gdip_DrawLine(g, pen, cx - armLen, cy + armLen, cx + armLen, cy - armLen)
    }
    Gdip_DeletePen(pen)
}

; ── Desenho principal ────────────────────────────────────
; Sem Critical: com Critical ligado, uma hotkey de macro pressionada no
; meio de um frame (o pulso redesenha ~12x/s com macro ligado) esperava o
; frame terminar. Em vez disso, uma trava simples evita reentrância no
; canvas compartilhado: um redesenho pedido enquanto outro está em
; andamento (ex.: a hotkey interrompeu o frame e ligou um macro) é
; reagendado para logo depois, então o estado novo nunca se perde.
_HudRedraw() {
    global _hudDesenhando, _hudRedrawPendente
    if (_hudDesenhando) {
        _hudRedrawPendente := true
        return
    }
    _hudDesenhando := true
    try
        _HudDesenharFrame()
    finally
        _hudDesenhando := false
    if (_hudRedrawPendente) {
        _hudRedrawPendente := false
        SetTimer(_HudRedraw, -1)
    }
}

_HudDesenharFrame() {
    global miniGui, _hudX, _hudY, _hudHoverT, _hudBoxes, macros, _HUD_SCALE, _hudBarHover, _hudCanvas

    if (!miniGui)
        return
    hudHwnd := miniGui.Hwnd

    accent := T()["ACCENT"]
    items  := _HudVisibleItems()
    s      := _HUD_SCALE

    PAD := Round(14*s), GAP := Round(10*s), BTN_D := Round(36*s), MINI_D := Round(22*s), SEP_H := Round(22*s)
    BAR_THICK := Round(58*s)   ; espessura fixa da barra (altura se horizontal, largura se vertical)
    ICON_BAR_SZ := Round(34*s)
    GEAR_D := Round(20*s), GEAR_GAP := Round(8*s)

    vertical := (GetHudOrientacao() = "vertical")

    boxes    := []
    barIcons := []

    ; Com o mouse sobre a barra (_hudBarHover) a HUD vira duas fileiras
    ; (colunas, se vertical): a dos ícones, com separador + ✕ no fim, e
    ; uma faixa de configurações com o ⚙ de cada macro alinhado ao seu
    ; ícone e o ⚙ geral alinhado ao ✕. Fora do hover só os ícones existem
    ; — no jogo, quase sempre só se quer ligar/desligar um macro.
    ;
    ; A faixa cresce PARA FORA da barra (abaixo na horizontal, à direita
    ; na vertical): os ícones não se mexem quando ela aparece, então o que
    ; está sob o mouse continua lá. A distância entre as fileiras deixa as
    ; áreas de clique sem sobreposição (ícone: BTN_D/2 + 3, ⚙: GEAR_D/2 + 3).
    mostrarCluster := _hudBarHover
    sepX := 0, sepY := 0
    gearCx := 0, gearCy := 0, closeCx := 0, closeCy := 0
    tGear := 0, tClose := 0

    mostrarCfg := mostrarCluster && items.Length > 0
    cfgOffset  := BTN_D / 2 + GEAR_GAP + GEAR_D / 2
    cfgFaixa   := mostrarCluster ? (GEAR_GAP + GEAR_D + Round(4*s)) : 0

    if (vertical) {
        ; Ícones empilhados numa coluna estreita — a mesma lógica de
        ; sempre, só que ao longo de y em vez de x (ver ramo "else").
        barCX := BAR_THICK // 2
        cy := PAD

        for m in items {
            hk := "bar_" m["id"]
            hv := _hudHoverT.Has(hk) ? _hudHoverT[hk] : 0
            r  := BTN_D / 2 + hv * 2 * s
            thisCy := cy + BTN_D / 2
            barIcons.Push({ m: m, cx: barCX, cy: thisCy, r: r, hoverT: hv, cfgCx: barCX + cfgOffset, cfgCy: thisCy })
            cy += BTN_D + GAP
        }

        if (mostrarCluster) {
            cy += 2
            sepY := cy
            cy += 1 + GAP

            tClose := _hudHoverT.Has("close") ? _hudHoverT["close"] : 0
            closeCx := barCX, closeCy := cy + MINI_D / 2
            boxes.Push({ id: "close", kind: "close", cx: closeCx, cy: closeCy, r: MINI_D / 2 + 3 })

            tGear := _hudHoverT.Has("gear") ? _hudHoverT["gear"] : 0
            gearCx := barCX + cfgOffset, gearCy := closeCy
            boxes.Push({ id: "gear", kind: "gear", cx: gearCx, cy: gearCy, r: MINI_D / 2 + 3 })
            cy += MINI_D
        }

        winW := BAR_THICK + cfgFaixa
        winH := cy + PAD
    } else {
        barCY := BAR_THICK // 2
        cx := PAD

        for m in items {
            hk := "bar_" m["id"]
            hv := _hudHoverT.Has(hk) ? _hudHoverT[hk] : 0
            r  := BTN_D / 2 + hv * 2 * s
            thisCx := cx + BTN_D / 2
            barIcons.Push({ m: m, cx: thisCx, cy: barCY, r: r, hoverT: hv, cfgCx: thisCx, cfgCy: barCY + cfgOffset })
            cx += BTN_D + GAP
        }

        if (mostrarCluster) {
            cx += 2
            sepX := cx
            cx += 1 + GAP

            tClose := _hudHoverT.Has("close") ? _hudHoverT["close"] : 0
            closeCx := cx + MINI_D / 2, closeCy := barCY
            boxes.Push({ id: "close", kind: "close", cx: closeCx, cy: closeCy, r: MINI_D / 2 + 3 })

            tGear := _hudHoverT.Has("gear") ? _hudHoverT["gear"] : 0
            gearCx := closeCx, gearCy := barCY + cfgOffset
            boxes.Push({ id: "gear", kind: "gear", cx: gearCx, cy: gearCy, r: MINI_D / 2 + 3 })
            cx += MINI_D
        }

        winW := cx + PAD
        winH := BAR_THICK + cfgFaixa
    }

    for it in barIcons {
        m := it.m
        boxes.Push({ id: "bar_" m["id"], kind: "macro", nome: m["nome"], cx: it.cx, cy: it.cy, r: BTN_D / 2 + 3 })
        if (mostrarCfg)
            boxes.Push({ id: "cfg_" m["id"], kind: "cfg", cfgFn: m["cfg"], cx: it.cfgCx, cy: it.cfgCy, r: GEAR_D / 2 + 3 })
    }

    _hudBoxes := boxes

    winW := Max(winW, 10)
    winH := Max(winH, 10)
    canvas := Gdip_ResizeCanvas(&_hudCanvas, winW, winH)
    g := canvas.pGraphics

    ; fundo + borda
    bgBrush := Gdip_BrushSolid(Gdip_Argb(240, "0x0f0d12"))
    Gdip_FillRoundRect(g, bgBrush, 0, 0, winW, winH, 16*s)
    Gdip_DeleteBrush(bgBrush)

    borderPen := Gdip_Pen(Gdip_Argb(255, "0x241f2c"), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, winW - 1, winH - 1, 16*s)
    Gdip_DeletePen(borderPen)

    ; ícones da barra
    tipAlvo := 0
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

        ; ⚙ do macro: apagado por padrão, acende quando o mouse está no
        ; ícone dele ou no próprio ⚙ — fica claro de qual macro é, e os
        ; outros não chamam atenção (menos clique errado no meio do jogo).
        if (mostrarCfg) {
            tCfg := _hudHoverT.Has("cfg_" m["id"]) ? _hudHoverT["cfg_" m["id"]] : 0
            _HudDrawMiniBtn(g, "gear", it.cfgCx, it.cfgCy, GEAR_D, tCfg)
            destaque := Max(tCfg, hoverT)
            if (destaque < 1) {
                rDim := GEAR_D / 2 + 2*s
                dimBrush := Gdip_BrushSolid(Gdip_Argb(Round(150 * (1 - destaque)), "0x0f0d12"))
                Gdip_FillEllipse(g, dimBrush, it.cfgCx - rDim, it.cfgCy - rDim, rDim * 2, rDim * 2)
                Gdip_DeleteBrush(dimBrush)
            }
        }

        ; Tooltip: só guarda o ícone com mais hover (durante a transição de
        ; um ícone para outro, os dois estão com hoverT > 0) — o desenho
        ; é feito na janela própria, ver _HudTipDesenhar.
        if (hoverT > 0.02 && (!tipAlvo || hoverT > tipAlvo.hoverT))
            tipAlvo := it
    }

    ; separador + ✕ / ⚙ geral — só existem com o mouse sobre a barra.
    ; A linha do separador é perpendicular ao eixo da barra e atravessa as
    ; duas fileiras (ícones e configurações): vertical quando a barra é
    ; horizontal, horizontal quando a barra é a coluna.
    if (mostrarCluster) {
        sepPen := Gdip_Pen(Gdip_Argb(255, "0x221f27"), 1)
        if (vertical)
            Gdip_DrawLine(g, sepPen, closeCx - SEP_H / 2, sepY, gearCx + SEP_H / 2, sepY)
        else
            Gdip_DrawLine(g, sepPen, sepX, closeCy - SEP_H / 2, sepX, gearCy + SEP_H / 2)
        Gdip_DeletePen(sepPen)

        _HudDrawMiniBtn(g, "gear",  gearCx,  gearCy,  MINI_D, tGear)
        _HudDrawMiniBtn(g, "close", closeCx, closeCy, MINI_D, tClose)
    }

    Gdip_PresentLayeredCanvas(canvas, hudHwnd, _hudX, _hudY)

    if (tipAlvo)
        _HudTipDesenhar(tipAlvo, vertical, winW, winH)
    else
        _HudTipEsconder()
}

; ── Tooltip dos ícones da barra (janela própria) ─────────
_HudTipCriar() {
    global _hudTipGui, _hudTipVisivel, miniGui
    _hudTipVisivel := false
    ; E0x80000 layered, E0x20 transparent (mouse atravessa), E0x08000000 noactivate
    _hudTipGui := Gui("-Caption +ToolWindow +AlwaysOnTop +E0x80000 +E0x20 +E0x08000000 +Owner" miniGui.Hwnd)
    _hudTipGui.Show("w10 h10 NoActivate Hide")
}

_HudTipDestruir() {
    global _hudTipGui, _hudTipCanvas, _hudTipVisivel
    try _hudTipGui.Destroy()
    _hudTipGui := 0
    _hudTipVisivel := false
    if (_hudTipCanvas) {
        Gdip_DestroyLayeredCanvas(_hudTipCanvas)
        _hudTipCanvas := 0
    }
}

_HudTipEsconder() {
    global _hudTipGui, _hudTipVisivel
    if (_hudTipGui && _hudTipVisivel) {
        DllCall("ShowWindow", "Ptr", _hudTipGui.Hwnd, "Int", 0)   ; SW_HIDE
        _hudTipVisivel := false
    }
}

; Área de trabalho do monitor onde a HUD está (para o tooltip não sair da
; tela nem ir parar em outro monitor). Devolve [esq, topo, dir, base].
_HudAreaMonitor(hwnd) {
    hMon := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", 2, "Ptr")   ; MONITOR_DEFAULTTONEAREST
    mi := Buffer(40, 0)
    NumPut("UInt", 40, mi, 0)
    DllCall("GetMonitorInfo", "Ptr", hMon, "Ptr", mi)
    return [NumGet(mi, 20, "Int"), NumGet(mi, 24, "Int"), NumGet(mi, 28, "Int"), NumGet(mi, 32, "Int")]
}

; it: ícone da barra (coordenadas relativas à HUD). Barra horizontal: o
; tooltip fica acima (ou abaixo, se não couber). Barra vertical: à esquerda
; (ou à direita, se não couber) — acima de uma coluna estreita ele cobriria
; os ícones vizinhos.
_HudTipDesenhar(it, vertical, hudW, hudH) {
    global _hudTipGui, _hudTipCanvas, _hudTipVisivel, _hudTipMedidas, _hudX, _hudY, _hudVisivel, miniGui, _HUD_SCALE
    if (!_hudTipGui || !_hudVisivel)
        return
    s := _HUD_SCALE
    m := it.m
    hoverT := it.hoverT

    label := m["label"]
    fontSz := Round(12*s)
    chave := label "|" fontSz
    if !_hudTipMedidas.Has(chave)
        _hudTipMedidas[chave] := Gdip_MeasureText(label, fontSz, true)[1]
    tw := Round(_hudTipMedidas[chave] + 24*s)
    th := Round(26*s)
    gap := Round(6*s)

    area := _HudAreaMonitor(miniGui.Hwnd)
    if (vertical) {
        tx := _hudX - tw - gap
        if (tx < area[1])
            tx := _hudX + hudW + gap
        ty := Round(_hudY + it.cy - th / 2)
    } else {
        tx := Round(_hudX + it.cx - tw / 2)
        ty := _hudY - th - gap
        if (ty < area[2])
            ty := _hudY + hudH + gap
    }
    tx := Max(area[1], Min(tx, area[3] - tw))
    ty := Max(area[2], Min(ty, area[4] - th))

    canvas := Gdip_ResizeCanvas(&_hudTipCanvas, tw, th)
    g := canvas.pGraphics
    ; AntiAliasGridFit (3) em vez do AntiAlias (4) padrão do canvas: encaixa
    ; os glifos na grade de pixels, bem mais nítido em fonte pequena. Setado
    ; a cada frame porque Gdip_ResizeCanvas pode recriar o canvas.
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", g, "Int", 3)

    tipBg := Gdip_BrushSolid(Gdip_Argb(Round(250 * hoverT), "0x0a090c"))
    Gdip_FillRoundRect(g, tipBg, 0, 0, tw, th, 7*s)
    Gdip_DeleteBrush(tipBg)

    tipPen := Gdip_Pen(Gdip_Argb(Round(255 * hoverT), "0x3a3544"), 1)
    Gdip_DrawRoundRect(g, tipPen, 0.5, 0.5, tw - 1, th - 1, 7*s)
    Gdip_DeletePen(tipPen)

    Gdip_DrawText(g, label, fontSz, true, Gdip_Argb(Round(255 * hoverT), "0xffffff"), 0, 0, tw, th, true)

    Gdip_PresentLayeredCanvas(canvas, _hudTipGui.Hwnd, tx, ty)
    if (!_hudTipVisivel) {
        DllCall("ShowWindow", "Ptr", _hudTipGui.Hwnd, "Int", 4)   ; SW_SHOWNOACTIVATE
        _hudTipVisivel := true
    }
}
