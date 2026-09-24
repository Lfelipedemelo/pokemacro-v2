; =====================================================
; lib\gdip_config.ahk — Framework GDI+ para telas de configuração
; =====================================================
;
; Mesma técnica da HUD (ui\mini_menu.ahk): uma janela em camadas
; (UpdateLayeredWindow) desenhada do zero a cada redesenho com GDI+ —
; cantos arredondados de verdade, sem depender de controles nativos do
; Win32 (que não suportam isso). Cada tela de config monta sua própria
; função de desenho (ui\config_*.ahk) e chama _GCfg_Abrir(); o framework
; cuida de: posicionar/mostrar a janela, roteamento de mouse (hover,
; clique, arraste da janela pelo fundo) e o arraste do controle de
; slider (usado pelos campos de delay/tempo).
;
; Só uma tela de configuração fica aberta por vez — chamar _GCfg_Abrir
; com outra já aberta fecha a anterior e abre a nova (nunca fica sem
; efeito por já "ter algo aberto").
;
; API usada pelas telas de config:
;   _GCfg_Abrir(w, h, drawFn)      — abre a janela; drawFn(g, w, h, hoverId) → boxes[]
;   _GCfg_Fechar()                 — fecha a janela atual (se houver)
;   _GCfg_Redraw()                 — força um redesenho (ex.: depois de uma captura de tecla)
;   _GCfg_Header(...)              — desenha a barra de título (cabeçalho + botões × / ↺)
;   _GCfg_Field(...)               — cartão "rótulo + valor clicável" (captura de tecla/posição)
;   _GCfg_Toggle(...)              — cartão com 2 opções (pílula segmentada)
;   _GCfg_Segmented(...)           — cartão com N opções (pílula segmentada)
;   _GCfg_Slider(...)              — cartão com barra arrastável (valores numéricos)
;   _GCfg_MiniSlider(...)          — versão compacta do slider, para vários lado a lado
;   _GCfg_ShowInMini(...)          — cartão "exibir no mini menu" (compartilhado entre telas)

global _gcfgGui     := 0
global _gcfgW       := 0
global _gcfgH       := 0
; _gcfgX/_gcfgY: posição atual (física, top-left) da tela de config aberta.
; Persistida em config.ini ["Geral"]configPosX/configPosY ao fechar (ver
; _GCfg_Fechar) e restaurada ao abrir (ver _GCfg_Abrir) — compartilhada
; entre todas as telas de config, já que só uma fica aberta por vez.
global _gcfgX       := 0
global _gcfgY       := 0
global _gcfgBoxes   := []
global _gcfgHoverId := ""
global _gcfgDraw    := 0
global _gcfgDragBox := 0
global _gcfgConfirm := 0   ; confirmação aberta por cima da tela ({titulo, sub, onSim, textoSim}) ou 0
global _gcfgEdit    := 0   ; chip de slider sendo editado pelo teclado (ver _GCfg_EditarValorSlider) ou 0
global _gcfgCanvas  := 0   ; canvas GDI+ reaproveitado entre redesenhos (ver _GCfg_Redraw)

; Fator de escala aplicado a todas as telas de configuração. Widgets
; continuam desenhando em coordenadas "lógicas" (as mesmas de sempre);
; é o Graphics inteiro que é ampliado antes de chamar drawFn, então
; formas, textos e traços crescem juntos sem precisar mexer em cada
; tela (ui\config_*.ahk). Coordenadas de mouse (físicas) são convertidas
; de volta para lógicas antes do hit-test — ver _GCfg_WM_MouseMove/LButtonDown.
;
; _GCFG_SCALE_BASE (1.35) é o zoom fixo que essas telas sempre tiveram.
; O multiplicador "TAMANHO DA INTERFACE" (pequeno/normal/grande, tela de
; Configurações Gerais) fica em cima dele — normal = 1.0x, ou seja, o
; tamanho de sempre. Como essas telas só redesenham por interação (hover/
; clique/drag), não a cada frame, escalar o Graphics inteiro aqui não
; tem custo de fps — diferente da HUD (ui\mini_menu.ahk), que anima a
; 60fps e por isso escala do outro jeito (ver _HUD_SCALE lá).
global _GCFG_SCALE_BASE := 1.35
global _GCFG_SCALE      := _GCFG_SCALE_BASE * EscalaFator()

; ── Abrir / fechar ─────────────────────────────────────
; Se outra tela de config já estiver aberta, fecha-a primeiro — só uma
; fica visível por vez, mas clicar num botão de config sempre leva a
; ele (em vez de ficar sem efeito porque "já tinha algo aberto").
_GCfg_Abrir(w, h, drawFn) {
    global _gcfgGui, _gcfgW, _gcfgH, _gcfgX, _gcfgY, _gcfgBoxes, _gcfgHoverId, _gcfgDraw, _gcfgDragBox, _GCFG_SCALE, _gcfgConfirm, _gcfgEdit

    if (_gcfgGui)
        _GCfg_Fechar()
    _gcfgConfirm := 0
    _gcfgEdit    := 0

    Gdip_EnsureStarted()

    _gcfgW := w, _gcfgH := h
    physW := Round(w * _GCFG_SCALE), physH := Round(h * _GCFG_SCALE)

    ; Reabre no mesmo lugar onde a última tela de config (qualquer uma —
    ; só existe uma por vez, ver comentário no topo do arquivo) foi
    ; fechada. Clampado contra o tamanho atual da tela pra não deixar a
    ; janela presa fora da área visível se a resolução/monitor mudou. Usa a
    ; área virtual (todos os monitores), como a HUD — clampar só pelo
    ; monitor principal puxava de volta uma tela deixada no segundo monitor.
    savedX := CfgLer("Geral", "configPosX", "")
    savedY := CfgLer("Geral", "configPosY", "")
    if (IsInteger(savedX) && IsInteger(savedY)) {
        vx := SysGet(76), vy := SysGet(77), vw := SysGet(78), vh := SysGet(79)
        _gcfgX := Max(vx, Min(Integer(savedX), vx + vw - physW))
        _gcfgY := Max(vy, Min(Integer(savedY), vy + vh - physH))
    } else {
        _gcfgX := (A_ScreenWidth  - physW) // 2
        _gcfgY := (A_ScreenHeight - physH) // 2
    }
    _gcfgBoxes   := []
    _gcfgHoverId := ""
    _gcfgDraw    := drawFn
    _gcfgDragBox := 0

    _gcfgGui := Gui("-Caption +ToolWindow +AlwaysOnTop +E0x80000")
    _gcfgGui.Show("x" _gcfgX " y" _gcfgY " w10 h10 NoActivate Hide")
    WinShow("ahk_id " _gcfgGui.Hwnd)

    OnMessage(0x200, _GCfg_WM_MouseMove)   ; WM_MOUSEMOVE
    OnMessage(0x201, _GCfg_WM_LButtonDown) ; WM_LBUTTONDOWN
    OnMessage(0x202, _GCfg_WM_LButtonUp)   ; WM_LBUTTONUP
    OnMessage(0x2A3, _GCfg_WM_MouseLeave)  ; WM_MOUSELEAVE
    OnMessage(0x0003, _GCfg_WM_Move)       ; WM_MOVE
    OnMessage(0x0100, _GCfg_WM_KeyDown)    ; WM_KEYDOWN (edição do valor de slider)
    OnMessage(0x0102, _GCfg_WM_Char)       ; WM_CHAR    (idem)
    OnMessage(0x0006, _GCfg_WM_Activate)   ; WM_ACTIVATE

    _GCfg_Redraw()
    return true
}

_GCfg_Fechar() {
    global _gcfgGui, _gcfgDragBox, _gcfgX, _gcfgY, _gcfgConfirm, _gcfgCanvas
    if (!_gcfgGui)
        return
    _GCfg_ConfirmarEdicao()   ; fechar com um valor digitado e não confirmado salva ele
    SalvarCfg("Geral", "configPosX", _gcfgX)
    SalvarCfg("Geral", "configPosY", _gcfgY)
    _gcfgDragBox := 0
    _gcfgConfirm := 0
    try _gcfgGui.Destroy()
    _gcfgGui := 0
    if (_gcfgCanvas) {
        Gdip_DestroyLayeredCanvas(_gcfgCanvas)
        _gcfgCanvas := 0
    }
}

; ── Desenho ────────────────────────────────────────────
_GCfg_Redraw() {
    global _gcfgGui, _gcfgW, _gcfgH, _gcfgX, _gcfgY, _gcfgBoxes, _gcfgDraw, _gcfgHoverId, _GCFG_SCALE, _gcfgConfirm, _gcfgCanvas
    if (!_gcfgGui || !_gcfgDraw)
        return
    Critical "On"
    try {
        physW := Round(_gcfgW * _GCFG_SCALE), physH := Round(_gcfgH * _GCFG_SCALE)
        ; Canvas reaproveitado entre redesenhos (arrastar um slider redesenha a
        ; cada movimento do mouse — recriar o DIB a cada vez era o custo maior).
        ; Zera transformação e recorte antes do clear: o clear respeita o clip,
        ; e a escala seria multiplicada de novo em cima da anterior.
        if (_gcfgCanvas) {
            Gdip_ResetClip(_gcfgCanvas.pGraphics)
            DllCall("gdiplus\GdipResetWorldTransform", "Ptr", _gcfgCanvas.pGraphics)
        }
        canvas := Gdip_ResizeCanvas(&_gcfgCanvas, physW, physH)
        Gdip_ScaleTransform(canvas.pGraphics, _GCFG_SCALE, _GCFG_SCALE)
        _gcfgBoxes := _gcfgDraw.Call(canvas.pGraphics, _gcfgW, _gcfgH, _gcfgHoverId)
        ; Com uma confirmação aberta, ela cobre a tela e só os botões dela
        ; recebem clique (ver _GCfg_Confirmar).
        if (_gcfgConfirm)
            _gcfgBoxes := _GCfg_DesenharConfirmacao(canvas.pGraphics, _gcfgW, _gcfgH, _gcfgHoverId)
        Gdip_PresentLayeredCanvas(canvas, _gcfgGui.Hwnd, _gcfgX, _gcfgY)
    } finally {
        ; Um erro no desenho não pode deixar o script inteiro em Critical
        ; (as hotkeys dos macros ficariam presas atrás dele).
        Critical "Off"
    }
}

; ── Confirmação (sobreposta à tela de config aberta) ────
; Substitui a antiga janelinha nativa (Gui com controles Win32, fora do
; tema e com cantos quadrados): a confirmação é desenhada por cima da
; própria tela atual, com o mesmo visual GDI+. onSim é chamado só se o
; usuário confirmar; "Não" apenas fecha a sobreposição.
_GCfg_Confirmar(titulo, subtitulo, onSim, textoSim := "SIM, RESETAR") {
    global _gcfgConfirm, _gcfgHoverId, _gcfgGui
    if (!_gcfgGui)
        return
    _gcfgConfirm := { titulo: titulo, sub: subtitulo, onSim: onSim, textoSim: textoSim }
    _gcfgHoverId := ""
    _GCfg_Redraw()
}

_GCfg_ResponderConfirmacao(sim, *) {
    global _gcfgConfirm, _gcfgHoverId
    pedido := _gcfgConfirm
    _gcfgConfirm := 0
    _gcfgHoverId := ""
    if (sim && pedido)
        pedido.onSim.Call()
}

_GCfg_DesenharConfirmacao(g, w, h, hoverId) {
    global _gcfgConfirm
    c := _gcfgConfirm
    boxes := []

    Gdip_SetClipRoundRect(g, 0, 0, w, h, 14)
    veu := Gdip_BrushSolid(Gdip_Argb(215, "0x0a0c10"))
    Gdip_FillRect(g, veu, 0, 0, w, h)
    Gdip_DeleteBrush(veu)
    Gdip_ResetClip(g)

    cw := w - 36, chh := 128
    cx := (w - cw) / 2, cy := (h - chh) / 2

    card := Gdip_BrushSolid(Gdip_Argb(255, T()["BG2"]))
    Gdip_FillRoundRect(g, card, cx, cy, cw, chh, 10)
    Gdip_DeleteBrush(card)

    Gdip_SetClipRoundRect(g, cx, cy, cw, chh, 10)
    faixa := Gdip_BrushSolid(Gdip_Argb(255, T()["DANGER"]))
    Gdip_FillRect(g, faixa, cx, cy, cw, 3)
    Gdip_DeleteBrush(faixa)
    Gdip_ResetClip(g)

    bordaPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawRoundRect(g, bordaPen, cx, cy, cw, chh, 10)
    Gdip_DeletePen(bordaPen)

    Gdip_DrawText(g, c.titulo, 11, true, Gdip_Argb(255, T()["TEXT"]), cx + 10, cy + 14, cw - 20, 22, true)
    Gdip_DrawText(g, c.sub,     9, false, Gdip_Argb(255, T()["MUTED"]), cx + 10, cy + 40, cw - 20, 18, true)

    bw := (cw - 30) / 2, bh := 30, by := cy + chh - bh - 14
    bxSim := cx + 10, bxNao := bxSim + bw + 10
    hovSim := (hoverId = "conf_sim"), hovNao := (hoverId = "conf_nao")

    br := Gdip_BrushSolid(Gdip_Argb(255, hovSim ? "0x5a2525" : "0x3d1f1f"))
    Gdip_FillRoundRect(g, br, bxSim, by, bw, bh, 7)
    Gdip_DeleteBrush(br)
    Gdip_DrawText(g, c.textoSim, 9, true, Gdip_Argb(255, "0xff8484"), bxSim, by, bw, bh, true)

    br := Gdip_BrushSolid(Gdip_Argb(255, hovNao ? T()["BG3"] : T()["BG"]))
    Gdip_FillRoundRect(g, br, bxNao, by, bw, bh, 7)
    Gdip_DeleteBrush(br)
    Gdip_DrawText(g, "NÃO", 9, true, Gdip_Argb(255, hovNao ? T()["TEXT"] : T()["MUTED"]), bxNao, by, bw, bh, true)

    boxes.Push({ id: "conf_sim", x: bxSim, y: by, w: bw, h: bh, onClick: _GCfg_ResponderConfirmacao.Bind(true) })
    boxes.Push({ id: "conf_nao", x: bxNao, y: by, w: bw, h: bh, onClick: _GCfg_ResponderConfirmacao.Bind(false) })
    ; véu inteiro por último: bloqueia clique/arraste no resto da tela
    boxes.Push({ id: "conf_veu", x: 0, y: 0, w: w, h: h })
    return boxes
}

; ── Entrada do mouse ───────────────────────────────────
_GCfg_HitTest(x, y) {
    global _gcfgBoxes
    for b in _gcfgBoxes {
        if (x >= b.x && x <= b.x + b.w && y >= b.y && y <= b.y + b.h)
            return b
    }
    return 0
}

_GCfg_WM_MouseMove(wParam, lParam, msg, hwnd) {
    global _gcfgGui, _gcfgHoverId, _gcfgDragBox, _GCFG_SCALE
    if (!_gcfgGui || hwnd != _gcfgGui.Hwnd)
        return
    Win_ArmarMouseLeave(hwnd)
    xy := Win_DecodeXY(lParam)
    mx := xy[1] / _GCFG_SCALE, my := xy[2] / _GCFG_SCALE   ; físico → lógico

    if (_gcfgDragBox) {
        if !(wParam & 0x1) {   ; botão esquerdo não está mais pressionado
            _gcfgDragBox := 0
            return
        }
        _GCfg_SliderSetFromX(_gcfgDragBox, mx)
        return
    }

    box := _GCfg_HitTest(mx, my)
    novoId := box ? box.id : ""
    if (novoId != _gcfgHoverId) {
        _gcfgHoverId := novoId
        _GCfg_Redraw()
    }
}

_GCfg_WM_LButtonDown(wParam, lParam, msg, hwnd) {
    global _gcfgGui, _gcfgDragBox, _GCFG_SCALE, _gcfgEdit
    if (!_gcfgGui || hwnd != _gcfgGui.Hwnd)
        return
    xy := Win_DecodeXY(lParam)
    mx := xy[1] / _GCFG_SCALE, my := xy[2] / _GCFG_SCALE   ; físico → lógico
    box := _GCfg_HitTest(mx, my)

    ; Clique fora do chip em edição confirma o valor digitado antes de
    ; tratar o clique normalmente.
    if (_gcfgEdit && !(box && box.id = _gcfgEdit.id "_valor"))
        _GCfg_ConfirmarEdicao()

    if (!box) {
        DragJanela(hwnd)   ; clique fora de qualquer cartão: arrasta a janela pelo fundo
        return
    }

    if (box.HasOwnProp("kind") && box.kind = "slider") {
        _gcfgDragBox := box
        _GCfg_SliderSetFromX(box, mx)
        return
    }

    ; Redesenha depois de todo clique: antes, alternâncias que só salvavam
    ; o valor (ex.: FULL ATTACK ativar/desativar) só apareciam na tela
    ; quando o mouse saía da pílula e o hover mudava.
    if (box.HasOwnProp("onClick")) {
        box.onClick.Call()
        _GCfg_Redraw()
    }
}

_GCfg_WM_LButtonUp(wParam, lParam, msg, hwnd) {
    global _gcfgGui, _gcfgDragBox
    if (!_gcfgGui || hwnd != _gcfgGui.Hwnd)
        return
    _gcfgDragBox := 0
}

_GCfg_WM_MouseLeave(wParam, lParam, msg, hwnd) {
    global _gcfgGui, _gcfgHoverId
    if (!_gcfgGui || hwnd != _gcfgGui.Hwnd)
        return
    if (_gcfgHoverId != "") {
        _gcfgHoverId := ""
        _GCfg_Redraw()
    }
}

_GCfg_WM_Move(wParam, lParam, msg, hwnd) {
    global _gcfgGui, _gcfgX, _gcfgY
    if (!_gcfgGui || hwnd != _gcfgGui.Hwnd)
        return
    xy := Win_DecodeXY(lParam)
    _gcfgX := xy[1], _gcfgY := xy[2]
}

; ── Escala da interface (chamado pela tela de Configurações Gerais) ──
; Fecha e reabre a tela de config atual no novo tamanho/posição. Não pode
; rodar direto de dentro de AplicarEscalaInterface porque essa função é
; chamada pelo próprio onClick do cartão de escala — destruir a janela
; ainda dentro do despacho de mensagens dela (_GCfg_WM_LButtonDown) dá
; erro de reentrância, o mesmo cuidado do botão fechar da HUD (ver
; ui\mini_menu.ahk, case "close"). Por isso o SetTimer(..., -1) abaixo.
_GCfg_ReaplicarEscala() {
    global _gcfgGui, _gcfgW, _gcfgH, _gcfgDraw
    if (!_gcfgGui || !_gcfgDraw)
        return
    _GCfg_Abrir(_gcfgW, _gcfgH, _gcfgDraw)
}

AplicarEscalaInterface(nome) {
    global _GCFG_SCALE, _GCFG_SCALE_BASE, _HUD_SCALE, _gcfgGui, miniGui

    SalvarCfg("Geral", "escalaInterface", nome)
    fator := EscalaFator(nome)

    _GCFG_SCALE := _GCFG_SCALE_BASE * fator
    _HUD_SCALE  := fator

    if (miniGui)
        _HudRedraw()
    if (_gcfgGui)
        SetTimer(_GCfg_ReaplicarEscala, -1)
}

; ── Slider ──────────────────────────────────────────────
_GCfg_SliderSetFromX(box, mx) {
    ; "frac", não "t": T() (tema) é uma função global e o AHK é
    ; case-insensitive — uma variável local "t" nessa função quebraria
    ; qualquer T() chamado nela (ver mesmo cuidado em _GCfg_Slider).
    frac := (mx - box.x) / box.w
    frac := Max(0.0, Min(1.0, frac))
    raw := box.min + (box.max - box.min) * frac
    val := Round(raw / box.step) * box.step
    val := Max(box.min, Min(box.max, val))
    box.value := val
    box.onChange.Call(val)
    _GCfg_Redraw()
}

; Estado de edição do chip do slider "id", ou 0 se não é ele que está em edição.
_GCfg_EdicaoDoSlider(id) {
    global _gcfgEdit
    return (_gcfgEdit && _gcfgEdit.id = id) ? _gcfgEdit : 0
}

; Chip em edição: número digitado + unidade, centralizados como o chip
; normal. Valor recém-aberto aparece "selecionado" (fundo realçado — o
; primeiro dígito substitui tudo); depois, um cursor piscando no fim do
; número. Borda na cor de destaque para deixar claro que está editando.
_GCfg_DesenharChipEmEdicao(g, ed, unit, x, y, w, h) {
    borda := Gdip_Pen(Gdip_Argb(255, T()["ACCENT"]), 1)
    Gdip_DrawRoundRect(g, borda, x + 0.5, y + 0.5, w - 1, h - 1, 5)
    Gdip_DeletePen(borda)

    ; Gdip_MeasureText inclui uma folga de ~1/6 em de cada lado do texto;
    ; "pad" desconta isso para o realce e o cursor encostarem nos dígitos.
    pad := 1.5
    numW  := (ed.texto = "") ? 0 : Gdip_MeasureText(ed.texto, 9, true)[1] - pad * 2
    fullW := Gdip_MeasureText(ed.texto " " unit, 9, true)[1]
    tx := x + (w - fullW) / 2

    Gdip_DrawText(g, ed.texto " " unit, 9, true, Gdip_Argb(255, T()["ACCENT"]), tx, y, fullW + 4, h, false)
    ; Selecionado: fundo de destaque e o número por cima em cor clara
    ; (mesma posição — o número é o começo da string desenhada acima).
    if (ed.selecionado && numW > 0) {
        sel := Gdip_BrushSolid(Gdip_Argb(255, T()["ACCENT2"]))
        Gdip_FillRoundRect(g, sel, tx + pad - 2, y + 3, numW + 4, h - 6, 3)
        Gdip_DeleteBrush(sel)
        Gdip_DrawText(g, ed.texto, 9, true, Gdip_Argb(255, T()["TEXT"]), tx, y, numW + pad * 2 + 4, h, false)
    }

    if (ed.cursor && !ed.selecionado) {
        cx := tx + pad + numW + 0.5
        caneta := Gdip_Pen(Gdip_Argb(255, T()["TEXT"]), 1)
        Gdip_DrawLine(g, caneta, cx, y + 4, cx, y + h - 4)
        Gdip_DeletePen(caneta)
    }
}

; ── Edição do valor de um slider pelo teclado ───────────
; Clicar no chip de valor de um _GCfg_Slider transforma o chip num campo
; de texto desenhado no próprio canvas (sem janela nativa). A janela de
; config é ativada para receber o teclado (WM_CHAR): dígitos digitam,
; Backspace apaga, Enter confirma, Esc cancela. Clicar fora do chip ou a
; janela perder o foco também confirma. O primeiro dígito substitui o
; valor inteiro (ele começa "selecionado", como num campo normal).
_GCfg_EditarValorSlider(id, atual, vMin, vMax, step, onChange, *) {
    global _gcfgEdit, _gcfgGui
    if (_gcfgEdit && _gcfgEdit.id = id)
        return
    _GCfg_ConfirmarEdicao()
    _gcfgEdit := { id: id, texto: String(atual), selecionado: true, cursor: true,
        min: vMin, max: vMax, step: step, onChange: onChange }
    try WinActivate("ahk_id " _gcfgGui.Hwnd)
    SetTimer(_GCfg_PiscarCursor, 530)
}

_GCfg_PiscarCursor() {
    global _gcfgEdit
    if (!_gcfgEdit) {
        SetTimer(_GCfg_PiscarCursor, 0)
        return
    }
    _gcfgEdit.cursor := !_gcfgEdit.cursor
    _GCfg_Redraw()
}

; Encerra a edição sem salvar.
_GCfg_CancelarEdicao() {
    global _gcfgEdit
    if (!_gcfgEdit)
        return
    _gcfgEdit := 0
    SetTimer(_GCfg_PiscarCursor, 0)
    _GCfg_Redraw()
}

; Encerra a edição salvando o número digitado — ajustado para dentro da
; faixa do slider e arredondado ao passo dele. Campo vazio = cancela.
_GCfg_ConfirmarEdicao() {
    global _gcfgEdit
    e := _gcfgEdit
    if (!e)
        return
    _gcfgEdit := 0
    SetTimer(_GCfg_PiscarCursor, 0)
    if (e.texto != "") {
        digitado := Integer(e.texto)
        val := Round(digitado / e.step) * e.step
        val := Max(e.min, Min(e.max, val))
        e.onChange.Call(val)
        if (val != digitado)
            ShowHint("AJUSTADO PARA " val " (" e.min "–" e.max ")", 1500, "warn")
    }
    _GCfg_Redraw()
}

; Enter/Esc/Backspace vêm pelo WM_KEYDOWN: numa janela Gui o AHK passa
; as teclas pelo IsDialogMessage, que come Enter/Esc antes de virarem
; WM_CHAR. Devolver 0 aqui impede esse processamento padrão.
_GCfg_WM_KeyDown(wParam, lParam, msg, hwnd) {
    global _gcfgGui, _gcfgEdit
    if (!_gcfgGui || hwnd != _gcfgGui.Hwnd || !_gcfgEdit)
        return
    e := _gcfgEdit
    switch wParam {
        case 0x0D: _GCfg_ConfirmarEdicao()   ; Enter
        case 0x1B: _GCfg_CancelarEdicao()    ; Esc
        case 0x08:                           ; Backspace
            e.texto := e.selecionado ? "" : SubStr(e.texto, 1, -1)
            e.selecionado := false
            _GCfg_EdicaoDigitou()
        default: return
    }
    return 0
}

; Dígitos (teclado normal ou numérico) chegam já traduzidos como WM_CHAR.
_GCfg_WM_Char(wParam, lParam, msg, hwnd) {
    global _gcfgGui, _gcfgEdit
    if (!_gcfgGui || hwnd != _gcfgGui.Hwnd || !_gcfgEdit)
        return
    e := _gcfgEdit
    ch := Chr(wParam)
    if !(ch ~= "^\d$")
        return 0
    if (e.selecionado)
        e.texto := "", e.selecionado := false
    if (StrLen(e.texto) < StrLen(String(e.max)))
        e.texto .= ch
    _GCfg_EdicaoDigitou()
    return 0
}

; Depois de cada tecla: cursor visível e piscada reiniciada, como num
; campo de texto normal.
_GCfg_EdicaoDigitou() {
    global _gcfgEdit
    _gcfgEdit.cursor := true
    SetTimer(_GCfg_PiscarCursor, 530)
    _GCfg_Redraw()
}

_GCfg_WM_Activate(wParam, lParam, msg, hwnd) {
    global _gcfgGui, _gcfgEdit
    ; Ao sair do app com a tela aberta e ativa, o AHK destrói a janela e
    ; só depois chega este WM_ACTIVATE — ler .Hwnd de uma Gui destruída
    ; lança erro e a saída travava. Daí o try.
    try guiHwnd := _gcfgGui ? _gcfgGui.Hwnd : 0
    catch
        return
    if (!guiHwnd || hwnd != guiHwnd)
        return
    if ((wParam & 0xFFFF) = 0 && _gcfgEdit)   ; WA_INACTIVE
        _GCfg_ConfirmarEdicao()
}

; ── Widgets ─────────────────────────────────────────────

; Cabeçalho: faixa colorida + título + botões × (fechar) e ↺ (resetar,
; opcional — passe 0 para omitir, como na tela Configurações Gerais).
; Devolve a altura ocupada.
_GCfg_Header(g, boxes, w, titulo, corFaixa, onReset, onFechar, hoverId) {
    hH := 34

    hdrBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG2"]))
    Gdip_FillRect(g, hdrBrush, 0, 0, w, hH)
    Gdip_DeleteBrush(hdrBrush)

    faixaBrush := Gdip_BrushSolid(Gdip_Argb(255, corFaixa))
    Gdip_FillRect(g, faixaBrush, 0, 0, w, 2)
    Gdip_DeleteBrush(faixaBrush)

    ; Separador desenhado antes dos botões: o glifo "↺" costuma ter tinta
    ; um pouco abaixo da caixa nominal, e se a linha fosse desenhada por
    ; cima ela cortaria visualmente a parte de baixo do ícone.
    sepPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawLine(g, sepPen, 0, hH, w, hH)
    Gdip_DeletePen(sepPen)

    d  := 22
    cy := hH // 2
    tituloW := w - 14 - (onReset ? (d * 2 + 20) : (d + 14))
    Gdip_DrawText(g, titulo, 10, true, Gdip_Argb(255, T()["TEXT"]), 14, 0, tituloW, hH, false)

    _GCfg_IconBtn(g, boxes, "close", w - 14 - d/2, cy, d, "×", hoverId = "close", false, onFechar)
    if (onReset)
        _GCfg_ResetIconBtn(g, boxes, "reset", w - 14 - d - 8 - d/2, cy, d, hoverId = "reset", onReset)

    return hH
}

_GCfg_IconBtn(g, boxes, id, cx, cy, d, glyph, hovered, perigo, onClick) {
    r := d / 2
    if (hovered) {
        bg := perigo ? Gdip_Argb(255, "0x3d1f1f") : Gdip_Argb(255, T()["BG3"])
        br := Gdip_BrushSolid(bg)
        Gdip_FillEllipse(g, br, cx - r, cy - r, d, d)
        Gdip_DeleteBrush(br)
    }
    col := perigo ? Gdip_Argb(255, "0xe05252") : Gdip_Argb(255, T()["MUTED"])
    Gdip_DrawText(g, glyph, 11, true, col, cx - r - 4, cy - r - 4, d + 8, d + 8, true)
    boxes.Push({ id: id, x: cx - r, y: cy - r, w: d, h: d, onClick: onClick })
}

; Botão de reset com o ícone icons\reset.png (PNG preto, recolorido em
; tempo real para vermelho) em vez de um glifo Unicode ("↺"), que
; dependia da fonte instalada e renderizava com a parte de baixo cortada
; em algumas máquinas.
_GCfg_ResetIconBtn(g, boxes, id, cx, cy, d, hovered, onClick) {
    r := d / 2
    if (hovered) {
        br := Gdip_BrushSolid(Gdip_Argb(255, "0x3d1f1f"))
        Gdip_FillEllipse(g, br, cx - r, cy - r, d, d)
        Gdip_DeleteBrush(br)
    }

    icoSz := 14
    pImg := Gdip_LoadImage(A_ScriptDir "\icons\reset.png")
    Gdip_DrawImageTinted(g, pImg, cx - icoSz/2, cy - icoSz/2, icoSz, icoSz, Gdip_Argb(255, "0xe05252"))

    boxes.Push({ id: id, x: cx - r, y: cy - r, w: d, h: d, onClick: onClick })
}

; Cartão "rótulo + valor clicável" — usado para teclas/posições
; capturadas (clicar em qualquer parte do cartão abre a captura).
; Devolve a altura ocupada (fixa).
_GCfg_Field(g, boxes, id, x, y, w, label, valor, onClick, hoverId) {
    ch := 44
    hovered := (hoverId = id)

    cardBrush := Gdip_BrushSolid(Gdip_Argb(255, hovered ? T()["BG3"] : T()["BG2"]))
    Gdip_FillRoundRect(g, cardBrush, x, y, w, ch, 8)
    Gdip_DeleteBrush(cardBrush)

    Gdip_DrawText(g, label, 9, true, Gdip_Argb(255, T()["MUTED"]), x + 8, y + 5, w - 16, 14, false)
    Gdip_DrawText(g, "▶ " valor, 10, true, Gdip_Argb(255, hovered ? T()["ACCENT"] : T()["TEXT"]),
        x + 8, y + 21, w - 16, 18, true)

    boxes.Push({ id: id, x: x, y: y, w: w, h: ch, onClick: onClick })
    return ch
}

; Cartão de alternância entre 2 opções (pílula segmentada).
; Devolve a altura ocupada (fixa).
_GCfg_Toggle(g, boxes, idBase, x, y, w, label, optA, optB, ativoA, onA, onB, hoverId) {
    ch := 44

    cardBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG2"]))
    Gdip_FillRoundRect(g, cardBrush, x, y, w, ch, 8)
    Gdip_DeleteBrush(cardBrush)

    Gdip_DrawText(g, label, 9, true, Gdip_Argb(255, T()["MUTED"]), x + 8, y + 5, w - 16, 14, false)

    segY := y + 21, segH := 17
    segWA := (w - 16) // 2
    segWB := (w - 16) - segWA
    segXA := x + 8
    segXB := segXA + segWA

    idA := idBase "_a", idB := idBase "_b"
    hovA := (hoverId = idA), hovB := (hoverId = idB)

    corA := ativoA  ? T()["ACCENT2"] : (hovA ? T()["BG3"] : T()["BG"])
    corB := !ativoA ? T()["ACCENT2"] : (hovB ? T()["BG3"] : T()["BG"])
    txtA := ativoA  ? T()["TEXT"] : T()["MUTED"]
    txtB := !ativoA ? T()["TEXT"] : T()["MUTED"]

    brA := Gdip_BrushSolid(Gdip_Argb(255, corA))
    Gdip_FillRoundRect(g, brA, segXA, segY, segWA, segH, 5)
    Gdip_DeleteBrush(brA)
    Gdip_DrawText(g, optA, 9, true, Gdip_Argb(255, txtA), segXA, segY, segWA, segH, true)

    brB := Gdip_BrushSolid(Gdip_Argb(255, corB))
    Gdip_FillRoundRect(g, brB, segXB, segY, segWB, segH, 5)
    Gdip_DeleteBrush(brB)
    Gdip_DrawText(g, optB, 9, true, Gdip_Argb(255, txtB), segXB, segY, segWB, segH, true)

    boxes.Push({ id: idA, x: segXA, y: segY, w: segWA, h: segH, onClick: onA })
    boxes.Push({ id: idB, x: segXB, y: segY, w: segWB, h: segH, onClick: onB })

    return ch
}

; Cartão de alternância entre N opções (ex.: Pokémon Inicial 1..4).
; onSelect recebe o índice (1-based) escolhido. Devolve a altura ocupada.
_GCfg_Segmented(g, boxes, idBase, x, y, w, label, opts, selecionado, onSelect, hoverId) {
    ch := 44

    cardBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG2"]))
    Gdip_FillRoundRect(g, cardBrush, x, y, w, ch, 8)
    Gdip_DeleteBrush(cardBrush)

    Gdip_DrawText(g, label, 9, true, Gdip_Argb(255, T()["MUTED"]), x + 8, y + 5, w - 16, 14, false)

    n := opts.Length
    segY := y + 21, segH := 17
    innerW := w - 16
    segW := innerW // n

    Loop n {
        idx := A_Index
        segX := x + 8 + segW * (idx - 1)
        segWi := (idx = n) ? (innerW - segW * (n - 1)) : segW
        id := idBase "_" idx
        ativo := (idx = selecionado)
        hov := (hoverId = id)
        cor := ativo ? T()["ACCENT2"] : (hov ? T()["BG3"] : T()["BG"])
        txt := ativo ? T()["TEXT"] : T()["MUTED"]

        br := Gdip_BrushSolid(Gdip_Argb(255, cor))
        Gdip_FillRoundRect(g, br, segX, segY, segWi, segH, 5)
        Gdip_DeleteBrush(br)
        Gdip_DrawText(g, opts[idx], 9, true, Gdip_Argb(255, txt), segX, segY, segWi, segH, true)

        boxes.Push({ id: id, x: segX, y: segY, w: segWi, h: segH, onClick: onSelect.Bind(idx) })
    }

    return ch
}

; Cartão com barra arrastável para valores numéricos (delay em ms,
; tempos em segundos etc.). Devolve a altura ocupada (fixa).
; min/max: nomes evitados como parâmetros (colidiriam com as funções
; Min()/Max() usadas aqui dentro) — por isso vMin/vMax.
_GCfg_Slider(g, boxes, id, x, y, w, label, value, vMin, vMax, step, unit, onChange, hoverId) {
    ch := 44
    hovered := (hoverId = id)

    cardBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG2"]))
    Gdip_FillRoundRect(g, cardBrush, x, y, w, ch, 8)
    Gdip_DeleteBrush(cardBrush)

    Gdip_DrawText(g, label, 9, true, Gdip_Argb(255, T()["MUTED"]), x + 8, y + 5, w - 16, 14, false)

    chipW := 54
    trackX := x + 8
    trackW := w - 16 - chipW - 6
    trackY := y + 27
    trackH := 6

    frac := (vMax = vMin) ? 0 : (value - vMin) / (vMax - vMin)
    frac := Max(0.0, Min(1.0, frac))
    fillW := Round(trackW * frac)

    bgBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG"]))
    Gdip_FillRoundRect(g, bgBrush, trackX, trackY, trackW, trackH, trackH // 2)
    Gdip_DeleteBrush(bgBrush)

    if (fillW > trackH) {
        fillBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["ACCENT2"]))
        Gdip_FillRoundRect(g, fillBrush, trackX, trackY, fillW, trackH, trackH // 2)
        Gdip_DeleteBrush(fillBrush)
    }

    knobR := hovered ? 7 : 6
    knobCx := trackX + fillW
    knobCy := trackY + trackH // 2
    knobBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["ACCENT"]))
    Gdip_FillEllipse(g, knobBrush, knobCx - knobR, knobCy - knobR, knobR * 2, knobR * 2)
    Gdip_DeleteBrush(knobBrush)

    ; Chip do valor: clicável, vira um campo para digitar o número à mão
    ; (ver _GCfg_EditarValorSlider). Clareia no hover para indicar isso.
    chipX := trackX + trackW + 6, chipY := y + 20, chipH := 20
    ed := _GCfg_EdicaoDoSlider(id)
    chipHov := (hoverId = id "_valor")
    chipBrush := Gdip_BrushSolid(Gdip_Argb(255, (chipHov || ed) ? T()["BG3"] : T()["BG"]))
    Gdip_FillRoundRect(g, chipBrush, chipX, chipY, chipW, chipH, 5)
    Gdip_DeleteBrush(chipBrush)
    if (ed)
        _GCfg_DesenharChipEmEdicao(g, ed, unit, chipX, chipY, chipW, chipH)
    else
        Gdip_DrawText(g, value " " unit, 9, true, Gdip_Argb(255, T()["ACCENT"]), chipX, chipY, chipW, chipH, true)

    boxes.Push({ id: id, kind: "slider", x: trackX, y: y + 16, w: trackW, h: 28,
        min: vMin, max: vMax, step: step, value: value, onChange: onChange })
    boxes.Push({ id: id "_valor", x: chipX, y: chipY, w: chipW, h: chipH,
        onClick: _GCfg_EditarValorSlider.Bind(id, value, vMin, vMax, step, onChange) })

    return ch
}

; Versão compacta do slider, sem chip numérico ao lado — usada quando
; vários deles precisam ficar lado a lado numa mesma linha estreita
; (ex.: os 4 tempos de espera do Cooldown). O valor aparece num chip
; pequeno acima da trilha, clicável para digitar o número — mesma edição
; do chip do _GCfg_Slider (ver _GCfg_EditarValorSlider). Devolve a altura
; ocupada (fixa).
_GCfg_MiniSlider(g, boxes, id, x, y, w, titulo, value, vMin, vMax, step, unit, onChange, hoverId) {
    ch := 40

    Gdip_DrawText(g, titulo, 8, true, Gdip_Argb(255, T()["MUTED"]), x, y, w, 12, true)

    chipW := Min(40, w - 6), chipH := 14
    chipX := x + (w - chipW) / 2, chipY := y + 11
    ed := _GCfg_EdicaoDoSlider(id)
    chipHov := (hoverId = id "_valor")
    if (chipHov || ed) {
        chipBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG3"]))
        Gdip_FillRoundRect(g, chipBrush, chipX, chipY, chipW, chipH, 4)
        Gdip_DeleteBrush(chipBrush)
    }
    if (ed)
        _GCfg_DesenharChipEmEdicao(g, ed, unit, chipX, chipY, chipW, chipH)
    else
        Gdip_DrawText(g, value unit, 9, true, Gdip_Argb(255, T()["ACCENT"]), chipX, chipY, chipW, chipH, true)

    ; Chip antes da trilha na lista: as áreas de clique se encostam, e o
    ; hit-test devolve a primeira que contém o ponto.
    boxes.Push({ id: id "_valor", x: chipX, y: chipY, w: chipW, h: chipH,
        onClick: _GCfg_EditarValorSlider.Bind(id, value, vMin, vMax, step, onChange) })

    trackY := y + 30
    trackH := 5
    trackX := x + 3
    trackW := w - 6

    frac := (vMax = vMin) ? 0 : (value - vMin) / (vMax - vMin)
    frac := Max(0.0, Min(1.0, frac))
    fillW := Round(trackW * frac)

    bgBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG"]))
    Gdip_FillRoundRect(g, bgBrush, trackX, trackY, trackW, trackH, trackH // 2)
    Gdip_DeleteBrush(bgBrush)

    if (fillW > trackH) {
        fillBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["ACCENT2"]))
        Gdip_FillRoundRect(g, fillBrush, trackX, trackY, fillW, trackH, trackH // 2)
        Gdip_DeleteBrush(fillBrush)
    }

    knobR := (hoverId = id) ? 6 : 5
    knobCx := trackX + fillW
    knobCy := trackY + trackH // 2
    knobBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["ACCENT"]))
    Gdip_FillEllipse(g, knobBrush, knobCx - knobR, knobCy - knobR, knobR * 2, knobR * 2)
    Gdip_DeleteBrush(knobBrush)

    boxes.Push({ id: id, kind: "slider", x: trackX, y: trackY - 8, w: trackW, h: 20,
        min: vMin, max: vMax, step: step, value: value, onChange: onChange })

    return ch
}

; Botão compacto lado a lado (ex.: os 4 mapeamentos de tecla do Cooldown):
; título acima, botão clicável abaixo mostrando o valor atual no próprio
; texto. Cada clique dispara onClick — quem chama decide o que fazer com
; o valor (ex.: ciclar 1..9). Devolve a altura ocupada (fixa).
_GCfg_MiniButton(g, boxes, id, x, y, w, titulo, valorTexto, onClick, hoverId) {
    ch := 40
    hovered := (hoverId = id)

    Gdip_DrawText(g, titulo, 8, true, Gdip_Argb(255, T()["MUTED"]), x, y, w, 12, true)

    btnY := y + 15, btnH := 21
    btnBrush := Gdip_BrushSolid(Gdip_Argb(255, hovered ? T()["BG3"] : T()["BG"]))
    Gdip_FillRoundRect(g, btnBrush, x, btnY, w, btnH, 6)
    Gdip_DeleteBrush(btnBrush)
    Gdip_DrawText(g, valorTexto, 9, true, Gdip_Argb(255, hovered ? T()["ACCENT"] : T()["TEXT"]),
        x, btnY, w, btnH, true)

    boxes.Push({ id: id, x: x, y: btnY, w: w, h: btnH, onClick: onClick })
    return ch
}

; Cartão compartilhado "Exibir no Mini Menu" — usado em todas as telas
; de macro (Combo, Revive, Combo Revive, Cooldown).
_GCfg_ShowInMini(g, boxes, x, y, w, secao, hoverId) {
    atual := GetShowInMini(secao)
    return _GCfg_Toggle(g, boxes, "showmini", x, y, w, "EXIBIR NO MINI MENU", "SIM", "NÃO", atual,
        (*) => (SalvarCfg(secao, "showInMini", "true"),  _RecriarMini()),
        (*) => (SalvarCfg(secao, "showInMini", "false"), _RecriarMini()), hoverId)
}
