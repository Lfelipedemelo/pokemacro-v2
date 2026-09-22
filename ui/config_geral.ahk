; =====================================================
; ui\config_geral.ahk — Configurações Gerais (GDI+)
; =====================================================

GetUsarPrefixoF() {
    return CfgLer("Geral", "usarPrefixoF", "true")
}

GetModoLegado() {
    return CfgLer("Geral", "modoLegado", "false")
}

; Orientação da barra de ícones da HUD — "horizontal" (padrão, ícones
; lado a lado) ou "vertical" (ícones empilhados numa coluna). Lida em
; tempo real por _HudRedraw (ui\mini_menu.ahk) — barato, vem do cache
; de config em memória (lib\config.ahk).
GetHudOrientacao() {
    return CfgLer("Geral", "hudOrientacao", "horizontal")
}

AbrirConfigGeral() {
    _GCfg_Abrir(288, 528, _DesenharConfigGeral)
}

; ── Tamanho da interface (HUD + telas de config) ──
; Mapeamento simples índice (pílula de 3 opções) <-> nome salvo no INI.
_ConfigGeral_EscalaIdx(nome) {
    switch nome {
        case "pequeno": return 1
        case "grande":  return 3
        default:        return 2
    }
}

_ConfigGeral_EscalaNome(idx) {
    switch idx {
        case 1:  return "pequeno"
        case 3:  return "grande"
        default: return "normal"
    }
}

; ── Macros que podem ser exibidos/ocultados na HUD (Ctrl+F12) ──
; Mesma seção/chave "showInMini" usada pelo toggle "EXIBIR NO MINI MENU"
; de cada tela de macro (_GCfg_ShowInMini em lib\gdip_config.ahk) — este
; painel só dá um lugar único para ver e mexer nos 5 de uma vez.
_ConfigGeral_MacrosVisiveis() {
    return [
        Map("secao", "comboPrincipal",  "label", "COMBO PRINCIPAL"),
        Map("secao", "comboSecundario", "label", "COMBO SECUNDÁRIO"),
        Map("secao", "Revive",          "label", "REVIVER"),
        Map("secao", "comboRevive",     "label", "COMBO REVIVE"),
        Map("secao", "Cooldown",        "label", "COOLDOWN"),
    ]
}

; Cartão de alternância "exibir na HUD" para um macro específico. idBase
; inclui a seção para não colidir com o hover dos outros cartões da
; lista (todos usariam "showmini" se reaproveitassem _GCfg_ShowInMini).
_GCfg_VisibilidadeItem(g, boxes, x, y, w, secao, label, hoverId) {
    atual := GetShowInMini(secao)
    return _GCfg_Toggle(g, boxes, "vis_" secao, x, y, w, label, "SIM", "NÃO", atual,
        (*) => (SalvarCfg(secao, "showInMini", "true"),  _RecriarMini(), _GCfg_Redraw()),
        (*) => (SalvarCfg(secao, "showInMini", "false"), _RecriarMini(), _GCfg_Redraw()), hoverId)
}

; ── Perfis ──
; Cartão "PERFIL ATIVO": ◀ nome ▶ troca entre perfis, "+ NOVO" cria um
; copiando as configs dos macros do perfil atual, "EXCLUIR" remove o
; perfil ativo (menos o padrão). Ver lib\config.ahk (seção Perfis).
_ConfigGeral_CartaoPerfil(g, boxes, x, y, w, hoverId) {
    ch := 44
    card := Gdip_BrushSolid(Gdip_Argb(255, T()["BG2"]))
    Gdip_FillRoundRect(g, card, x, y, w, ch, 8)
    Gdip_DeleteBrush(card)
    Gdip_DrawText(g, "PERFIL ATIVO", 9, true, Gdip_Argb(255, T()["MUTED"]), x + 8, y + 5, w - 16, 14, false)

    varios  := PerfisLista().Length > 1
    padrao  := PerfilAtivo() = ""
    segY := y + 21, segH := 17
    setaW := 18, novoW := 46, exclW := 52, gap := 4
    nomeX := x + 8 + setaW + gap
    nomeW := w - 16 - setaW * 2 - novoW - exclW - gap * 4

    _ConfigGeral_Botao(g, boxes, "perf_ant", x + 8, segY, setaW, segH, "◀", varios, hoverId, (*) => ProximoPerfil(-1))

    nomeBr := Gdip_BrushSolid(Gdip_Argb(255, T()["BG"]))
    Gdip_FillRoundRect(g, nomeBr, nomeX, segY, nomeW, segH, 5)
    Gdip_DeleteBrush(nomeBr)
    Gdip_DrawText(g, StrUpper(PerfilNomeExibicao()), 9, true, Gdip_Argb(255, T()["TEXT"]), nomeX, segY, nomeW, segH, true)

    bx := nomeX + nomeW + gap
    _ConfigGeral_Botao(g, boxes, "perf_prox", bx, segY, setaW, segH, "▶", varios, hoverId, (*) => ProximoPerfil(1))
    bx += setaW + gap
    _ConfigGeral_Botao(g, boxes, "perf_novo", bx, segY, novoW, segH, "+ NOVO", true, hoverId, (*) => _ConfigGeral_NovoPerfil())
    bx += novoW + gap
    _ConfigGeral_Botao(g, boxes, "perf_excl", bx, segY, exclW, segH, "EXCLUIR", !padrao, hoverId,
        (*) => _GCfg_Confirmar("EXCLUIR PERFIL " StrUpper(PerfilNomeExibicao()) "?",
            "As configs dos macros desse perfil serão apagadas.",
            (*) => ExcluirPerfilAtivo(), "SIM, EXCLUIR"), true)
    return ch
}

; Botãozinho em pílula usado no cartão de perfil. Desabilitado = apagado
; e sem área de clique.
_ConfigGeral_Botao(g, boxes, id, x, y, w, h, texto, habilitado, hoverId, onClick, perigo := false) {
    hov := habilitado && (hoverId = id)
    cor := hov ? (perigo ? "0x3d1f1f" : T()["BG3"]) : T()["BG"]
    br := Gdip_BrushSolid(Gdip_Argb(255, cor))
    Gdip_FillRoundRect(g, br, x, y, w, h, 5)
    Gdip_DeleteBrush(br)
    corTxt := !habilitado ? Gdip_Argb(90, T()["MUTED"])
        : perigo ? Gdip_Argb(255, "0xe05252")
        : Gdip_Argb(255, hov ? T()["TEXT"] : T()["MUTED"])
    Gdip_DrawText(g, texto, 8, true, corTxt, x, y, w, h, true)
    if (habilitado)
        boxes.Push({ id: id, x: x, y: y, w: w, h: h, onClick: onClick })
}

_ConfigGeral_NovoPerfil() {
    SetTimer(_GCfg_InputNoTopo.Bind("Novo perfil"), -80)
    r := InputBox("Nome do novo perfil (letras, números, espaço, _ ou -).`nAs configs dos macros do perfil atual serão copiadas.",
        "Novo perfil", "w320 h140")
    if (r.Result != "OK" || Trim(r.Value) = "")
        return
    erro := CriarPerfil(r.Value)
    if (erro != "")
        ShowHint(erro, 2000, "danger")
}

_DesenharConfigGeral(g, w, h, hoverId) {
    boxes := []

    Gdip_SetClipRoundRect(g, 0, 0, w, h, 14)
    bodyBrush := Gdip_BrushSolid(Gdip_Argb(255, T()["BG"]))
    Gdip_FillRect(g, bodyBrush, 0, 0, w, h)
    Gdip_DeleteBrush(bodyBrush)

    hH := _GCfg_Header(g, boxes, w, "CONFIGURAÇÕES GERAIS", T()["ACCENT2"], 0, (*) => _GCfg_Fechar(), hoverId)

    pad  := 14
    colW := (w - pad*2 - 10) // 2
    col2 := pad + colW + 10
    y := hH + 10

    y += _ConfigGeral_CartaoPerfil(g, boxes, pad, y, w - pad*2, hoverId) + 8

    usarF := GetUsarPrefixoF()
    _GCfg_Toggle(g, boxes, "prefF", pad, y, colW, "PREFIXO [F]", "F1..F9", "1..9", usarF = "true",
        (*) => SalvarCfg("Geral", "usarPrefixoF", "true"),
        (*) => SalvarCfg("Geral", "usarPrefixoF", "false"), hoverId)

    modoLegado := GetModoLegado()
    _GCfg_Toggle(g, boxes, "legado", col2, y, colW, "MODO LEGADO", "ATIVO", "INATIVO", modoLegado = "true",
        (*) => SalvarCfg("Geral", "modoLegado", "true"),
        (*) => SalvarCfg("Geral", "modoLegado", "false"), hoverId)
    y += 44 + 8

    ; "Normal" é o tamanho de sempre da HUD e das telas de config — ver
    ; AplicarEscalaInterface (lib\gdip_config.ahk) e _HUD_SCALE (ui\mini_menu.ahk).
    _GCfg_Segmented(g, boxes, "escala", pad, y, w - pad*2, "TAMANHO DA INTERFACE",
        ["PEQUENO", "NORMAL", "GRANDE"], _ConfigGeral_EscalaIdx(GetEscalaInterface()),
        (idx) => AplicarEscalaInterface(_ConfigGeral_EscalaNome(idx)), hoverId)
    y += 44 + 8

    orientVertical := GetHudOrientacao() = "vertical"
    _GCfg_Toggle(g, boxes, "orient", pad, y, colW, "ÍCONES DA HUD", "HORIZ.", "VERT.", !orientVertical,
        (*) => (SalvarCfg("Geral", "hudOrientacao", "horizontal"), _RecriarMini()),
        (*) => (SalvarCfg("Geral", "hudOrientacao", "vertical"), _RecriarMini()), hoverId)

    ; Tecla de pânico: desliga todos os macros e para o que estiver
    ; rodando (combo, cooldown) — ver DesligarTodosMacros.
    _GCfg_Field(g, boxes, "panico", col2, y, colW, "TECLA DE PÂNICO", _ComboDisplay(CfgLer("Geral", "teclaPanico", "N/A")),
        (*) => (CapturarCombo("Geral", "teclaPanico", 0, "TECLA DE PÂNICO"), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    faVal := CfgLer("Geral", "fullAttack", "N/A")
    _GCfg_Field(g, boxes, "fa", pad, y, colW, "FULL ATTACK", StrUpper(faVal),
        (*) => (CapturarTecla("Geral", "fullAttack", 0, "FULL ATTACK"), _GCfg_Redraw()), hoverId)

    fdVal := CfgLer("Geral", "fullDefense", "N/A")
    _GCfg_Field(g, boxes, "fd", col2, y, colW, "FULL DEFENSE", StrUpper(fdVal),
        (*) => (CapturarTecla("Geral", "fullDefense", 0, "FULL DEFENSE"), _GCfg_Redraw()), hoverId)
    y += 44 + 8

    Gdip_DrawText(g, "MACROS EXIBIDOS NA INTERFACE", 9, true, Gdip_Argb(255, T()["MUTED"]), pad, y, w - pad*2, 14, false)
    y += 20

    itens := _ConfigGeral_MacrosVisiveis()
    _GCfg_VisibilidadeItem(g, boxes, pad,  y, colW, itens[1]["secao"], itens[1]["label"], hoverId)
    _GCfg_VisibilidadeItem(g, boxes, col2, y, colW, itens[2]["secao"], itens[2]["label"], hoverId)
    y += 44 + 8

    _GCfg_VisibilidadeItem(g, boxes, pad,  y, colW, itens[3]["secao"], itens[3]["label"], hoverId)
    _GCfg_VisibilidadeItem(g, boxes, col2, y, colW, itens[4]["secao"], itens[4]["label"], hoverId)
    y += 44 + 8

    _GCfg_VisibilidadeItem(g, boxes, pad, y, w - pad*2, itens[5]["secao"], itens[5]["label"], hoverId)
    y += 44

    Gdip_ResetClip(g)
    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, 14)
    Gdip_DeletePen(borderPen)

    return boxes
}
