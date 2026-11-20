; =====================================================
; lib\hint.ahk — Banner de notificação e contagens (GDI+, tema do app)
; =====================================================
;
; Mesma técnica da HUD/telas de configuração (ui\mini_menu.ahk,
; lib\gdip_config.ahk): janela em camadas desenhada do zero a cada
; chamada com GDI+ — cantos arredondados de verdade e paleta igual
; ao resto do app (lib\globals.ahk → T()), em vez da antiga caixa
; com Gui nativa (cantos quadrados, cores fixas fora do tema atual).
;
; API pública:
;   ShowHint(text, time := 1200, kind := "info")
;     kind define a cor de destaque e o ícone:
;       "info"    — azul   (T().STRIPE3) — instruções/estado neutro
;       "success" — verde  (T().ACCENT)  — algo foi salvo/ativado
;       "warn"    — amarelo(T().STRIPE2) — cancelado/nada capturado
;       "danger"  — vermelho(T().DANGER) — erro/pré-requisito faltando
;   Devolve o nº deste aviso, para FecharHint(n) fechá-lo só se nenhum
;   outro tiver aparecido depois.
;
;   Contagens (ver CONTADORES): MostrarContador(tipo, ms, time) mostra o
;   tempo que falta ("1,4s") na posição e no tamanho escolhidos para
;   aquele tipo — "pausa" (pausa no combo da Rotação) ou "stun" (contagem
;   do stun dos combos). Cada tipo tem a sua janela: as duas aparecem ao
;   mesmo tempo. AlternarPreviewContador(tipo) mostra uma prévia
;   arrastável para escolher a posição.
;
; Um aviso novo com outro ainda na tela reaproveita a janela (só redesenha
; por cima) — as contagens trocam o texto a cada 100ms, e destruir e
; recriar a janela a cada vez fazia piscar.

global _hintGui := 0
global _hintTmr := 0
global _hintSeq := 0   ; nº do último aviso mostrado (ver FecharHint)

_HintPaleta(kind) {
    switch kind {
        case "success": return Map("cor", T()["ACCENT"],  "glifo", "✓")
        case "warn":    return Map("cor", T()["STRIPE2"], "glifo", "!")
        case "danger":  return Map("cor", T()["DANGER"],  "glifo", "✕")
        default:        return Map("cor", T()["STRIPE3"], "glifo", "i")
    }
}

; Medidas do aviso: { w, h, pad, iconD, gap, txtW, radius, fonte }.
_HintMedidas(text) {
    m := { pad: 24, iconD: 44, gap: 18, radius: 16, fonte: 15 }
    sz := Gdip_MeasureText(text, m.fonte, true, 720)
    m.txtW := Ceil(sz[1]) + 2
    m.h := m.pad + Max(m.iconD, Ceil(sz[2])) + m.pad
    m.w := m.pad + m.iconD + m.gap + m.txtW + m.pad
    return m
}

; Fundo arredondado + faixa colorida no topo + borda — a "moldura" comum
; aos avisos e às contagens.
_HintMoldura(g, ox, oy, w, h, radius, cor) {
    bgBrush := Gdip_BrushSolid(Gdip_Argb(245, T()["BG"]))
    Gdip_FillRoundRect(g, bgBrush, ox, oy, w, h, radius)
    Gdip_DeleteBrush(bgBrush)

    ; faixa recortada aos cantos arredondados — mesma ideia da faixa do
    ; cabeçalho das telas de config.
    Gdip_SetClipRoundRect(g, ox, oy, w, h, radius)
    stripeBrush := Gdip_BrushSolid(Gdip_Argb(255, cor))
    Gdip_FillRect(g, stripeBrush, ox, oy, w, 4)
    Gdip_DeleteBrush(stripeBrush)
    Gdip_ResetClip(g)

    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1.4)
    Gdip_DrawRoundRect(g, borderPen, ox + 0.5, oy + 0.5, w - 1, h - 1, radius)
    Gdip_DeletePen(borderPen)
}

; Desenha o aviso em 'g' com o canto superior esquerdo em (ox, oy).
; Usado pelo ShowHint e pelo gerador das imagens da documentação.
_HintDesenhar(g, text, kind, m, ox := 0, oy := 0) {
    pal := _HintPaleta(kind)
    _HintMoldura(g, ox, oy, m.w, m.h, m.radius, pal["cor"])

    ; ícone (badge circular colorido por tipo)
    d := m.iconD
    icCx := ox + m.pad + d / 2
    icCy := oy + m.h / 2

    icBg := Gdip_BrushSolid(Gdip_Argb(46, pal["cor"]))
    Gdip_FillEllipse(g, icBg, icCx - d / 2, icCy - d / 2, d, d)
    Gdip_DeleteBrush(icBg)

    icRing := Gdip_Pen(Gdip_Argb(255, pal["cor"]), 1.8)
    Gdip_DrawEllipse(g, icRing, icCx - d / 2, icCy - d / 2, d, d)
    Gdip_DeletePen(icRing)

    Gdip_DrawText(g, pal["glifo"], 18, true, Gdip_Argb(255, pal["cor"]),
        icCx - d / 2, icCy - d / 2, d, d, true)
    Gdip_DrawText(g, text, m.fonte, true, Gdip_Argb(255, T()["TEXT"]),
        ox + m.pad + d + m.gap, oy, m.txtW, m.h, false)
}

ShowHint(text, time := 1200, kind := "info") {
    global _hintGui, _hintTmr, _hintSeq

    if (_hintTmr) {
        SetTimer(_hintTmr, 0)
        _hintTmr := 0
    }
    seq := ++_hintSeq
    if (text = "") {
        _HintFechar(seq)
        return seq
    }

    Gdip_EnsureStarted()
    m := _HintMedidas(text)
    x := (A_ScreenWidth  - m.w) // 2
    y := (A_ScreenHeight - m.h) // 2

    ; E0x20 (transparente ao mouse) + E0x08000000 (não ativa): o aviso
    ; aparece no meio da tela durante o jogo — não pode tirar o foco dele
    ; nem engolir cliques.
    if !IsObject(_hintGui)
        _hintGui := _HintNovaJanela(true)

    canvas := Gdip_NewLayeredCanvas(m.w, m.h)
    _HintDesenhar(canvas.pGraphics, text, kind, m)
    Gdip_PresentLayeredCanvas(canvas, _hintGui.Hwnd, x, y)
    Gdip_DestroyLayeredCanvas(canvas)

    _hintTmr := _HintFechar.Bind(seq)
    SetTimer(_hintTmr, -time)
    return seq
}

; Janela em camadas sem foco, sempre por cima. 'transparente': o mouse
; passa através dela (avisos); sem isso ela recebe cliques (prévias).
_HintNovaJanela(transparente) {
    jan := Gui("-Caption +ToolWindow +AlwaysOnTop +E0x80000 +E0x08000000" (transparente ? " +E0x20" : ""))
    jan.Show("x0 y0 w10 h10 NoActivate Hide")
    Win_MostrarSemAtivar(jan.Hwnd)
    return jan
}

; Fecha o aviso 'seq' (devolvido por ShowHint) se ele ainda for o último
; mostrado — um aviso que apareceu depois fica na tela.
FecharHint(seq) {
    global _hintSeq, _hintTmr
    if (!seq || seq != _hintSeq)
        return
    if (_hintTmr) {
        SetTimer(_hintTmr, 0)
        _hintTmr := 0
    }
    _HintFechar(seq)
}

_HintFechar(seq) {
    global _hintGui, _hintTmr, _hintSeq
    if (seq != _hintSeq)
        return
    if IsObject(_hintGui) {
        try _hintGui.Destroy()
        _hintGui := 0
    }
    _hintTmr := 0
}

; ── Contagens ───────────────────────────────────────────
; Cada tipo guarda no INI a posição (chavePos = "x,y", centro do aviso em
; coordenadas de tela; ausente = meio da tela principal, deslocado em
; 'descer' px para os dois não nascerem um sobre o outro) e o tamanho
; (chaveTam = true para COMPACTA). NORMAL = número grande; COMPACTA =
; número pequeno. O stun também tem um rótulo "STUN" acima do número no
; NORMAL, e fica vermelho nos últimos 2 s (perigo).
global CONTADORES := Map(
    "pausa", { secao: "Rotacao", chavePos: "contagemPos", chaveTam: "contagemCompacta", cor: "STRIPE2", rotulo: "", descer: 0 },
    "stun",  { secao: "Geral",   chavePos: "stunPos",     chaveTam: "stunCompacta",     cor: "ACCENT2", rotulo: "STUN", descer: 110 })
global _contadorGui := Map()   ; tipo → janela da contagem
global _contadorTmr := Map()   ; tipo → timer que fecha a contagem sozinho
global _contadorSeq := Map("pausa", 0, "stun", 0)

; { cx, cy, compacto, centro } do tipo. Uma posição salva fora de todos
; os monitores (ex.: monitor desconectado) volta ao padrão.
ContadorPos(tipo) {
    c := CONTADORES[tipo]
    compacto := CfgLer(c.secao, c.chaveTam, "false") = "true"
    partes := StrSplit(CfgLer(c.secao, c.chavePos, ""), ",")
    if (partes.Length = 2 && IsInteger(Trim(partes[1])) && IsInteger(Trim(partes[2]))) {
        cx := Integer(Trim(partes[1])), cy := Integer(Trim(partes[2]))
        ; tela virtual = todos os monitores juntos
        vx := SysGet(76), vy := SysGet(77), vw := SysGet(78), vh := SysGet(79)
        if (cx >= vx && cx < vx + vw && cy >= vy && cy < vy + vh)
            return { cx: cx, cy: cy, compacto: compacto, centro: false }
    }
    return { cx: A_ScreenWidth // 2, cy: A_ScreenHeight // 2 + c.descer, compacto: compacto, centro: true }
}

; Texto da contagem: segundos com uma casa, arredondados para cima — chega
; a "0,1s", nunca mostra "0,0s" com tempo ainda faltando.
FormatarContagem(ms) {
    return StrReplace(Format("{:.1f}", Ceil(Max(0, ms) / 100) / 10), ".", ",") "s"
}

; Medidas: { w, h, fonte, rotuloH, radius }. A largura é a de "8,8s"
; (não a do texto atual), para a janela não mudar de tamanho na contagem.
_ContadorMedidas(tipo, compacto) {
    c := CONTADORES[tipo]
    fonte := compacto ? 15 : 30
    sz := Gdip_MeasureText("8,8s", fonte, true)
    rotuloH := (!compacto && c.rotulo != "") ? 14 : 0
    pad := compacto ? 12 : 16
    return { w: Ceil(sz[1]) + pad * 2, h: Ceil(sz[2]) + (compacto ? 14 : 12) + rotuloH,
        fonte: fonte, rotuloH: rotuloH, radius: compacto ? 12 : 16 }
}

; Desenha a contagem do tipo (texto já formatado) em 'g', canto superior
; esquerdo em (ox, oy). Usado pela janela, pela prévia e pelo gerador das
; imagens da documentação.
_ContadorDesenhar(g, tipo, text, m, perigo := false, ox := 0, oy := 0) {
    c := CONTADORES[tipo]
    cor := perigo ? T()["DANGER"] : T()[c.cor]
    _HintMoldura(g, ox, oy, m.w, m.h, m.radius, cor)
    if (m.rotuloH)
        Gdip_DrawText(g, c.rotulo, 8, true, Gdip_Argb(255, cor), ox, oy + 7, m.w, m.rotuloH, true)
    ; 2px abaixo do centro, para compensar a faixa do topo
    Gdip_DrawText(g, text, m.fonte, true, Gdip_Argb(255, cor), ox, oy + m.rotuloH + 2, m.w, m.h - m.rotuloH, true)
}

; Mostra (ou atualiza) a contagem do tipo com 'ms' faltando; fecha sozinha
; depois de 'time' ms se ninguém atualizar nem fechar antes. Devolve um nº
; para FecharContador fechar só esta (uma mais nova do mesmo tipo fica).
MostrarContador(tipo, ms, time, perigo := false) {
    global _contadorGui, _contadorTmr, _contadorSeq
    Gdip_EnsureStarted()
    if _contadorTmr.Has(tipo)
        SetTimer(_contadorTmr.Delete(tipo), 0)
    seq := ++_contadorSeq[tipo]

    pos := ContadorPos(tipo)
    m := _ContadorMedidas(tipo, pos.compacto)
    if !_contadorGui.Has(tipo)
        _contadorGui[tipo] := _HintNovaJanela(true)
    canvas := Gdip_NewLayeredCanvas(m.w, m.h)
    _ContadorDesenhar(canvas.pGraphics, tipo, FormatarContagem(ms), m, perigo)
    Gdip_PresentLayeredCanvas(canvas, _contadorGui[tipo].Hwnd, Round(pos.cx - m.w / 2), Round(pos.cy - m.h / 2))
    Gdip_DestroyLayeredCanvas(canvas)

    _contadorTmr[tipo] := FecharContador.Bind(tipo, seq)
    SetTimer(_contadorTmr[tipo], -time)
    return seq
}

; Fecha a contagem do tipo. Com 'seq', só se ela ainda for a última
; mostrada daquele tipo.
FecharContador(tipo, seq := 0) {
    global _contadorGui, _contadorTmr, _contadorSeq
    if (seq && seq != _contadorSeq[tipo])
        return
    if _contadorTmr.Has(tipo)
        SetTimer(_contadorTmr.Delete(tipo), 0)
    if _contadorGui.Has(tipo)
        try _contadorGui.Delete(tipo).Destroy()
}

; Copia a posição e o tamanho da contagem 'de' para 'para' (ex.: botão
; USAR POSIÇÃO DA PAUSA, nas telas de combo).
CopiarContador(de, para) {
    a := CONTADORES[de], b := CONTADORES[para]
    SalvarCfg(b.secao, b.chavePos, CfgLer(a.secao, a.chavePos, ""))
    SalvarCfg(b.secao, b.chaveTam, CfgLer(a.secao, a.chaveTam, "false"))
    _ContadorPrevDesenhar()
}

; Texto do campo POSIÇÃO de um tipo nas telas de config.
ContadorPosTexto(tipo) {
    if (PreviewContadorAberta() = tipo)
        return "✓ PRONTO"
    p := ContadorPos(tipo)
    return p.centro ? "CENTRO" : p.cx ", " p.cy
}

; ── Prévia arrastável ──
; Uma janela com a contagem de exemplo do tipo, no lugar e no tamanho
; atuais, mais uma legenda embaixo. Diferente da contagem de verdade, ela
; recebe o mouse: arrastar com o botão esquerdo move (a posição é salva
; ao soltar), o botão direito volta ao padrão. Não ativa (não tira o foco
; do jogo). Uma só por vez; fecha pelo mesmo campo que abriu ou junto com
; a tela de config.

global _contadorPrevGui := 0
global _contadorPrevTipo := ""
global _CONTADOR_PREV_LEGENDA := "ARRASTE  ·  BOTÃO DIREITO = CENTRO"

; Tipo da prévia aberta, ou "".
PreviewContadorAberta() {
    global _contadorPrevTipo
    return _contadorPrevTipo
}

; Abre a prévia do tipo; se ela já estiver aberta, fecha. Abrir a de um
; tipo fecha a do outro.
AlternarPreviewContador(tipo) {
    global _contadorPrevGui, _contadorPrevTipo
    if (_contadorPrevTipo = tipo) {
        FecharPreviewContador()
        return
    }
    Gdip_EnsureStarted()
    if !IsObject(_contadorPrevGui) {
        _contadorPrevGui := _HintNovaJanela(false)   ; precisa do clique para ser arrastada
        OnMessage(0x0201, _ContadorPrev_LButtonDown)   ; WM_LBUTTONDOWN
        OnMessage(0x0204, _ContadorPrev_RButtonDown)   ; WM_RBUTTONDOWN
        OnMessage(0x0232, _ContadorPrev_FimArraste)    ; WM_EXITSIZEMOVE
    }
    _contadorPrevTipo := tipo
    _ContadorPrevDesenhar()
}

FecharPreviewContador(*) {
    global _contadorPrevGui, _contadorPrevTipo
    _contadorPrevTipo := ""
    if !IsObject(_contadorPrevGui)
        return
    OnMessage(0x0201, _ContadorPrev_LButtonDown, 0)
    OnMessage(0x0204, _ContadorPrev_RButtonDown, 0)
    OnMessage(0x0232, _ContadorPrev_FimArraste, 0)
    try _contadorPrevGui.Destroy()
    _contadorPrevGui := 0
}

; Medidas da prévia: a contagem em cima, a legenda embaixo, centralizados.
_ContadorPrevMedidas(tipo, compacto) {
    global _CONTADOR_PREV_LEGENDA
    m := _ContadorMedidas(tipo, compacto)
    legW := Ceil(Gdip_MeasureText(_CONTADOR_PREV_LEGENDA, 8, true)[1]) + 16
    legH := 20
    w := Max(m.w, legW)
    return { w: w, h: m.h + 6 + legH, m: m, avisoX: (w - m.w) // 2, legW: legW, legH: legH }
}

; Pinta a prévia (contagem de exemplo + contorno tracejado + legenda) em
; 'g'. Também usado pelo gerador das imagens.
_ContadorPrevPintar(g, tipo, pm) {
    global _CONTADOR_PREV_LEGENDA
    _ContadorDesenhar(g, tipo, "1,4s", pm.m, false, pm.avisoX, 0)

    ; contorno tracejado: deixa claro que é uma prévia que dá para mover
    pen := Gdip_Pen(Gdip_Argb(255, T()[CONTADORES[tipo].cor]), 1.5)
    DllCall("gdiplus\GdipSetPenDashStyle", "Ptr", pen, "Int", 1)   ; DashStyleDash
    Gdip_DrawRoundRect(g, pen, pm.avisoX + 2, 2, pm.m.w - 4, pm.m.h - 4, pm.m.radius - 2)
    Gdip_DeletePen(pen)

    legX := (pm.w - pm.legW) / 2, legY := pm.m.h + 6
    br := Gdip_BrushSolid(Gdip_Argb(230, T()["BG"]))
    Gdip_FillRoundRect(g, br, legX, legY, pm.legW, pm.legH, 6)
    Gdip_DeleteBrush(br)
    Gdip_DrawText(g, _CONTADOR_PREV_LEGENDA, 8, true, Gdip_Argb(255, T()["MUTED"]), legX, legY, pm.legW, pm.legH, true)
}

; Redesenha a prévia aberta na posição salva (o centro da contagem fica no
; ponto salvo; a legenda fica embaixo dela). Sem prévia aberta, nada.
_ContadorPrevDesenhar(*) {
    global _contadorPrevGui, _contadorPrevTipo
    if (!IsObject(_contadorPrevGui) || _contadorPrevTipo = "")
        return
    pos := ContadorPos(_contadorPrevTipo)
    pm := _ContadorPrevMedidas(_contadorPrevTipo, pos.compacto)
    canvas := Gdip_NewLayeredCanvas(pm.w, pm.h)
    _ContadorPrevPintar(canvas.pGraphics, _contadorPrevTipo, pm)
    Gdip_PresentLayeredCanvas(canvas, _contadorPrevGui.Hwnd, Round(pos.cx - pm.w / 2), Round(pos.cy - pm.m.h / 2))
    Gdip_DestroyLayeredCanvas(canvas)
}

_ContadorPrev_LButtonDown(wParam, lParam, msg, hwnd) {
    global _contadorPrevGui
    if (!IsObject(_contadorPrevGui) || hwnd != _contadorPrevGui.Hwnd)
        return
    DragJanela(hwnd)
    return 0
}

; Fim do arraste: salva o centro da contagem (não da janela inteira — a
; legenda fica abaixo dela).
_ContadorPrev_FimArraste(wParam, lParam, msg, hwnd) {
    global _contadorPrevGui, _contadorPrevTipo
    if (!IsObject(_contadorPrevGui) || hwnd != _contadorPrevGui.Hwnd || _contadorPrevTipo = "")
        return
    c := CONTADORES[_contadorPrevTipo]
    WinGetPos(&x, &y, , , "ahk_id " hwnd)
    pm := _ContadorPrevMedidas(_contadorPrevTipo, ContadorPos(_contadorPrevTipo).compacto)
    SalvarCfg(c.secao, c.chavePos, Round(x + pm.w / 2) "," Round(y + pm.m.h / 2))
    _GCfg_Redraw()   ; o campo POSIÇÃO da tela mostra o ponto novo
}

_ContadorPrev_RButtonDown(wParam, lParam, msg, hwnd) {
    global _contadorPrevGui, _contadorPrevTipo
    if (!IsObject(_contadorPrevGui) || hwnd != _contadorPrevGui.Hwnd || _contadorPrevTipo = "")
        return
    c := CONTADORES[_contadorPrevTipo]
    SalvarCfg(c.secao, c.chavePos, "")
    _ContadorPrevDesenhar()
    _GCfg_Redraw()
    return 0
}
