#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)

; =====================================================
; docs\gerador\gerar_imagens.ahk — Gera as imagens de docs\img\
; =====================================================
;
; Não tira print da tela: chama as próprias funções de desenho do app
; (_DesenharConfig*, _HudDesenharFrame, paleta do ShowHint) num canvas
; GDI+ fora da tela e salva em PNG (2x), com marcadores numerados
; amarelos. Os números de cada tela (listas passadas a RenderCfg) são os
; mesmos das tabelas dos guias em docs\*.md — mudou um, mude o outro.
;
; Usa demo.ini (valores de exemplo) numa cópia temporária — nunca lê nem
; grava o config.ini real.
;
; Uso: executar este arquivo (saída padrão: docs\img\), ou passar outra
; pasta de saída como 1º argumento.

#Include ..\..\lib\globals.ahk
#Include ..\..\lib\config.ahk
#Include ..\..\lib\gdip.ahk
#Include ..\..\lib\gdip_config.ahk
#Include ..\..\lib\hint.ahk
#Include ..\..\lib\window.ahk
#Include ..\..\lib\input.ahk
#Include ..\..\lib\deteccao.ahk
#Include ..\..\lib\atualizacao.ahk
#Include ..\..\ui\mini_menu.ahk
#Include ..\..\ui\config_combo.ahk
#Include ..\..\ui\config_revive.ahk
#Include ..\..\ui\config_cooldown.ahk
#Include ..\..\ui\config_combo_revive.ahk
#Include ..\..\ui\config_geral.ahk
#Include ..\..\ui\config_rotacao.ahk
#Include ..\..\macros\hotkeys.ahk
#Include ..\..\macros\combo.ahk
#Include ..\..\macros\revive.ahk
#Include ..\..\macros\cooldown.ahk
#Include ..\..\macros\combo_revive.ahk
#Include ..\..\macros\rotacao.ahk

; ── Config de demonstração (cópia temporária — nunca o config.ini real) ──
FileCopy(A_ScriptDir "\demo.ini", A_ScriptDir "\demo_run.ini", true)
configFile := A_ScriptDir "\demo_run.ini"
_cfgCache.Clear()

; O app monta os caminhos dos ícones a partir de A_ScriptDir — copia a
; pasta icons\ para cá. A cópia fica (está no .gitignore): o cache de
; imagens do app mantém os PNGs abertos até o processo terminar, então
; não dá para apagá-la de dentro do script.
DirCopy(A_ScriptDir "\..\..\icons", A_ScriptDir "\icons", true)

OUT := A_Args.Length ? A_Args[1] : A_ScriptDir "\..\img"
DirCreate(OUT)
Gdip_EnsureStarted()

S := 2   ; resolução das imagens (2x a escala lógica)

; ── Utilitários ──────────────────────────────────────────
SalvarPng(pBitmap, path) {
    clsid := Buffer(16)
    DllCall("ole32\CLSIDFromString", "WStr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "Ptr", clsid)
    r := DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", path, "Ptr", clsid, "Ptr", 0)
    if (r != 0)
        FileAppend("ERRO ao salvar " path " (" r ")`n", "*")
    else
        FileAppend("ok " path "`n", "*")
}

; Marcador numerado (círculo amarelo com número escuro) — coordenadas lógicas.
Badge(g, cx, cy, n) {
    r := 9
    sh := Gdip_BrushSolid(Gdip_Argb(120, "0x000000"))
    Gdip_FillEllipse(g, sh, cx - r - 1.5, cy - r - 0.5, r * 2 + 3, r * 2 + 3)
    Gdip_DeleteBrush(sh)
    br := Gdip_BrushSolid(Gdip_Argb(255, "0xffcb05"))
    Gdip_FillEllipse(g, br, cx - r, cy - r, r * 2, r * 2)
    Gdip_DeleteBrush(br)
    pen := Gdip_Pen(Gdip_Argb(255, "0x14181f"), 1.2)
    Gdip_DrawEllipse(g, pen, cx - r, cy - r, r * 2, r * 2)
    Gdip_DeletePen(pen)
    Gdip_DrawText(g, String(n), 8.5, true, Gdip_Argb(255, "0x14181f"), cx - r - 4, cy - r - 3, r * 2 + 8, r * 2 + 8, true)
}

AcharBox(boxes, id) {
    for b in boxes
        if (b.id = id)
            return b
    throw Error("box não encontrado: " id)
}

; Canto superior direito do cartão ao qual o box pertence (telas de 288px).
AnotarCartao(g, boxes, id, n) {
    b := AcharBox(boxes, id)
    topo := b.y
    if (b.h = 17)                        ; pílula de toggle/segmentado
        topo := b.y - 21
    else if (b.HasOwnProp("kind") && b.kind = "slider")
        topo := b.y - 16
    dir := (b.x + b.w <= 139 && !(b.id ~= "_1$")) ? 139 : 274
    Badge(g, dir - 7, topo + 7, n)
}

; Renderiza uma tela de config (mesma função de desenho do app) num PNG.
; seletor: { botao: id do box que abre o seletor, ... } — clica nele (o
; onClick abre o seletor via _GCfg_AbrirSeletor) e desenha o painel.
RenderCfg(nome, w, h, drawFn, anot, hoverId := "", confirm := 0, seletor := 0) {
    global S, OUT, _gcfgConfirm, _gcfgSeletor, _gcfgGui
    canvas := Gdip_NewLayeredCanvas(w * S, h * S)
    g := canvas.pGraphics
    Gdip_ScaleTransform(g, S, S)
    boxes := drawFn.Call(g, w, h, hoverId)
    if (confirm) {
        _gcfgConfirm := confirm
        _GCfg_DesenharConfirmacao(g, w, h, hoverId)
        _gcfgConfirm := 0
    }
    if (seletor) {
        ; _GCfg_AbrirSeletor exige uma tela aberta e redesenha nela — uma
        ; janela fictícia escondida basta; o desenho que vale é o daqui.
        _gcfgGui := Gui("-Caption +ToolWindow +E0x80000")
        AcharBox(boxes, seletor.botao).onClick.Call()
        _gcfgGui.Destroy(), _gcfgGui := 0
        _GCfg_DesenharSeletor(g, w, h, seletor.hover)
        _gcfgSeletor := 0
    }
    for a in anot {
        if (a.Length = 2)
            AnotarCartao(g, boxes, a[2], a[1])
        else
            Badge(g, a[2], a[3], a[1])
    }
    SalvarPng(canvas.pBitmap, OUT "\" nome ".png")
    Gdip_DestroyLayeredCanvas(canvas)
}

; Mesmo desenho do ShowHint (lib\hint.ahk: _HintMedidas/_HintDesenhar),
; só que para um PNG.
RenderHint(nome, text, kind) {
    global S, OUT
    m := _HintMedidas(text)
    k := 1.25
    canvas := Gdip_NewLayeredCanvas(Ceil(m.w * k), Ceil(m.h * k))
    g := canvas.pGraphics
    Gdip_ScaleTransform(g, k, k)
    _HintDesenhar(g, text, kind, m)
    SalvarPng(canvas.pBitmap, OUT "\" nome ".png")
    Gdip_DestroyLayeredCanvas(canvas)
}

; Contagem (lib\hint.ahk: _ContadorDesenhar) do tipo "pausa" ou "stun".
RenderContador(nome, tipo, text, compacto, perigo := false) {
    global OUT
    m := _ContadorMedidas(tipo, compacto)
    k := 1.25
    canvas := Gdip_NewLayeredCanvas(Ceil(m.w * k), Ceil(m.h * k))
    g := canvas.pGraphics
    Gdip_ScaleTransform(g, k, k)
    _ContadorDesenhar(g, tipo, text, m, perigo)
    SalvarPng(canvas.pBitmap, OUT "\" nome ".png")
    Gdip_DestroyLayeredCanvas(canvas)
}

; Prévia arrastável da contagem (lib\hint.ahk: _ContadorPrevPintar),
; desenhada num PNG em vez da janela.
RenderPreviewContador(nome, tipo, compacto) {
    global OUT
    pm := _ContadorPrevMedidas(tipo, compacto)
    k := 1.25
    canvas := Gdip_NewLayeredCanvas(Ceil(pm.w * k), Ceil(pm.h * k))
    g := canvas.pGraphics
    Gdip_ScaleTransform(g, k, k)
    _ContadorPrevPintar(g, tipo, pm)
    SalvarPng(canvas.pBitmap, OUT "\" nome ".png")
    Gdip_DestroyLayeredCanvas(canvas)
}

; HUD: usa o próprio _HudDesenharFrame numa janela escondida e salva o canvas.
RenderHud(nome, barHover, hoverT, anotar := false) {
    global miniGui, _hudCanvas, _hudBarHover, _hudHoverT, _hudBoxes, _HUD_SCALE, _hudVisibleCache, OUT
    _hudVisibleCache := 0
    if (_hudCanvas) {
        Gdip_DestroyLayeredCanvas(_hudCanvas)
        _hudCanvas := 0
    }
    _hudBarHover := barHover
    _hudHoverT   := hoverT
    _HudDesenharFrame()
    c := _hudCanvas
    g := c.pGraphics
    if (anotar) {
        k := _HUD_SCALE
        for b in _hudBoxes {
            n := 0
            switch b.kind {
                case "macro": n := 1
                case "cfg":   n := 2
                case "gear":  n := 3
                case "close": n := 4
            }
            ; só marca o primeiro ícone/⚙ de macro, para não poluir
            if ((b.kind = "macro" && b.id != "bar_c1") || (b.kind = "cfg" && b.id != "cfg_c1"))
                continue
            DllCall("gdiplus\GdipResetWorldTransform", "Ptr", g)
            Gdip_ScaleTransform(g, k, k)
            Badge(g, b.cx / k + b.r / k - 3, b.cy / k - b.r / k + 3, n)
        }
        DllCall("gdiplus\GdipResetWorldTransform", "Ptr", g)
    }
    ; recorta ao tamanho lógico do frame
    DllCall("gdiplus\GdipCloneBitmapAreaI", "Int", 0, "Int", 0, "Int", c.w, "Int", c.h,
        "Int", 0xE200B, "Ptr", c.pBitmap, "Ptr*", &pClone := 0)
    SalvarPng(pClone, OUT "\" nome ".png")
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pClone)
}

; ── Telas de configuração ───────────────────────────────
RenderCfg("config-combo", 288, 464, _DesenharConfigCombo.Bind("comboPrincipal"),
    [[1, "inicial"], [2, "final"], [3, "hkmacro"], [4, "toggle"], [5, "atk_a"], [6, "def_a"], [7, "sleep"],
     [8, "stun_a"], [9, "stunTecla"], [10, "stunTam_a"], [11, "stunPos"], [12, "stunCopiar"], [13, "showmini_a"]])

; Seletor do botão do stun aberto (F3..F8, stun no F5), mouse sobre o F5.
RenderCfg("config-combo-stun", 288, 464, _DesenharConfigCombo.Bind("comboPrincipal"), [], "", 0,
    { botao: "stunTecla", hover: "sel_3" })

RenderCfg("config-combo-reset", 288, 464, _DesenharConfigCombo.Bind("comboPrincipal"), [], "conf_nao",
    { titulo: "RESETAR COMBOPRINCIPAL?", sub: "Esta ação não pode ser desfeita.", onSim: 0, textoSim: "SIM, RESETAR" })

RenderCfg("config-revive", 288, 308, _DesenharConfigRevive,
    [[1, "pos"], [2, "hkrevive"], [3, "delay"], [4, "hkmacro"], [5, "toggle"], [6, "dedo"], [7, "dedoTeste"], [8, "showmini_a"]])

RenderCfg("config-combo-revive", 288, 360, _DesenharConfigComboRevive,
    [[1, "inicial"], [2, "final"], [3, "hkmacro"], [4, "toggle"], [5, "atk_a"], [6, "def_a"], [7, "delay"], [8, "sleep"], [9, "showmini_a"]])

RenderCfg("config-cooldown", 288, 422, _DesenharConfigCooldown,
    [[1, "hkcd"], [2, "toggle"], [3, "pkm_1"], [4, 267, 155], [5, 267, 237], [6, "fd_a"], [7, "showmini_a"]])

; Seletor aberto na tecla do PKM 3 (Ctrl+4), mouse sobre o 3.
RenderCfg("config-cooldown-seletor", 288, 422, _DesenharConfigCooldown, [], "", 0,
    { botao: "tecla3", hover: "sel_3" })

; Padrão (1º de cada rotação à mão): sequência 2-3-4 | 2-5-6; dois apertos
; depois do início, o próximo é o Ctrl+4 da 1ª rotação (contorno verde).
; Os marcadores 7 (pokémon), 8 (combo pós-troca), 9 (Pokestop), 10 (pausa
; no combo) e 11 (stun, última linha) vão em todos os cartões de rotação (um
; por rotação; cartões a cada 172).
_rotacaoPos := 3
RenderCfg("config-rotacao", 288, AlturaConfigRotacao(), _DesenharConfigRotacao,
    [[1, "hkmacro"], [2, "toggle"], [3, "reiniciar"], [4, "pokestop"], [5, "formato_a"], [6, "primeiro_a"],
     [7, 165, 207], [7, 165, 379], [8, 267, 271], [8, 267, 443], [9, 267, 295], [9, 267, 467],
     [10, 267, 319], [10, 267, 491], [11, 267, 343], [11, 267, 515],
     [15, "delay"], [16, "contagemTam_a"], [17, "contagemPos"], [18, "showmini_a"]])

; Painel da pausa aberto no 3º passo da 1ª rotação (Combo 1, F3..F8:
; pausa depois do F4 por 1500 ms), mouse sobre o F4.
RenderCfg("config-rotacao-pausa", 288, AlturaConfigRotacao(), _DesenharConfigRotacao, [], "", 0,
    { botao: "p1p3", hover: "sel_3" })

; Seletor do stun aberto no 3º passo da 1ª rotação (Combo 1, F3..F8: stun
; no F6), mouse sobre o F6.
RenderCfg("config-rotacao-stun", 288, AlturaConfigRotacao(), _DesenharConfigRotacao, [], "", 0,
    { botao: "st1p3", hover: "sel_5" })

; Seletor aberto no 3º passo da 2ª rotação (Ctrl+5), mouse sobre o 6.
RenderCfg("config-rotacao-seletor", 288, AlturaConfigRotacao(), _DesenharConfigRotacao, [], "", 0,
    { botao: "r2p3", hover: "sel_6" })

; Seletor do combo pós-troca aberto no 3º passo da 2ª rotação, mouse
; sobre o C1.
RenderCfg("config-rotacao-combo", 288, AlturaConfigRotacao(), _DesenharConfigRotacao, [], "", 0,
    { botao: "c2p3", hover: "sel_2" })

; Formato 3x3 (2-3 | 4-5 | E/R-6: o 2º passo da 3ª rotação é o de ITEM,
; o que mostra os campos 12-14 do elixir/revive): ao ligar, o próximo é o
; Ctrl+2 da 1ª rotação, e o passo de ITEM mostra ELIXIR (1ª volta).
SalvarCfg("Rotacao", "formato", "3x3")
_rotacaoPos := 1, _rotacaoCiclo := 1
RenderCfg("config-rotacao-3x3", 288, AlturaConfigRotacao(), _DesenharConfigRotacao,
    [[1, "hkmacro"], [2, "toggle"], [3, "reiniciar"], [4, "pokestop"], [5, "formato_a"], [6, "primeiro_a"],
     [7, 165, 207], [7, 165, 379], [7, 165, 551], [8, 267, 271], [8, 267, 443], [8, 267, 615],
     [9, 267, 295], [9, 267, 467], [9, 267, 639], [10, 267, 319], [10, 267, 491], [10, 267, 663],
     [11, 267, 343], [11, 267, 515], [11, 267, 687],
     [12, "elixir"], [13, "elixirModo_a"], [14, "reviveModo_a"],
     [15, "delay"], [16, "contagemTam_a"], [17, "contagemPos"], [18, "showmini_a"]])

; "COMEÇAR AQUI" da 3ª rotação (tem o E/R): seletor ELIXIR/REVIVE aberto,
; mouse sobre o REVIVE.
RenderCfg("config-rotacao-vez", 288, AlturaConfigRotacao(), _DesenharConfigRotacao, [], "", 0,
    { botao: "atual3", hover: "sel_2" })
SalvarCfg("Rotacao", "formato", "2x4")

RenderCfg("config-geral", 288, 558, _DesenharConfigGeral,
    [[1, "prefF_a"], [2, "legado_a"], [3, "escala_1"], [4, "orient_a"], [5, "panico"], [6, "fa"], [7, "fd"], [8, "pokestop"],
     [9, "vis_comboPrincipal_a"], [10, 267, 507]])

; Cartão de atualização depois de achar uma versão nova (ATUALIZAR liberado)
_atualiz.nova := "2.1.0", _atualiz.estado := "disponivel"
RenderCfg("config-geral-atualizacao", 288, 558, _DesenharConfigGeral, [[11, 267, 519]])
_atualiz.nova := "", _atualiz.estado := "ocioso"

; hover num campo, para mostrar o destaque
RenderCfg("config-combo-hover", 288, 464, _DesenharConfigCombo.Bind("comboPrincipal"), [], "hkmacro")

; ── HUD ─────────────────────────────────────────────────
_HUD_SCALE := 2
miniGui := Gui("-Caption +ToolWindow +E0x80000")
macros["comboPrincipal"] := true
macros["revive"] := true
macros["rotacao"] := true
_rotacaoPos := 1   ; início padrão (1º pokémon à mão): o ícone da Rotação mostra "2"
RenderHud("hud", false, Map())
RenderHud("hud-hover", true, Map("bar_c1", 1.0), true)
macros["comboPrincipal"] := false
macros["revive"] := false
macros["rotacao"] := false
RenderHud("hud-desligada", false, Map())
SalvarCfg("Geral", "hudOrientacao", "vertical")
macros["comboPrincipal"] := true
RenderHud("hud-vertical", true, Map("cfg_c1", 1.0))
SalvarCfg("Geral", "hudOrientacao", "horizontal")

; ── Avisos (ShowHint) ───────────────────────────────────
RenderHint("hint-tecla", "Pressione tecla ou botão do mouse (ESC cancela)", "info")
RenderHint("hint-combo", "Pressione tecla, botão do mouse ou combinação com Ctrl/Alt/Shift (ESC cancela)", "info")
RenderHint("hint-salvo", "TECLA MACRO: XBUTTON2", "success")
RenderHint("hint-conflito", "XBUTTON1 já é usada em REVIVE", "danger")
RenderHint("hint-posicao", "Clique no local desejado (ESC cancela)", "info")
RenderHint("hint-posicao-salva", "Posição salva: 412, 688", "success")
RenderHint("hint-cancelado", "Cancelado", "warn")
RenderHint("hint-dedo", "Com o pokémon FORA, clique no centro do ícone do dedo (ESC cancela)", "info")
RenderHint("hint-dedo-afaste", "Agora afaste o mouse do ícone", "info")
RenderHint("hint-dedo-ok", "Ícone do dedo capturado!", "success")
RenderHint("hint-dedo-teste", "DEDO ENCONTRADO em 1012, 941 (3 ms) — pokémon FORA", "success")
RenderHint("hint-dedo-teste-nao", "DEDO NÃO ENCONTRADO (21 ms) — pokémon guardado/morto", "warn")
RenderHint("hint-proibido", "Clique esquerdo/direito não pode ser usado", "warn")
RenderHint("hint-revive-erro", "Erro: Defina a posição primeiro!", "danger")
RenderHint("hint-rotacao-reiniciada", "ROTAÇÃO REINICIADA — próximo: Ctrl+2", "info")
RenderContador("contagem-pausa", "pausa", "1,4s", false)
RenderContador("contagem-pausa-compacta", "pausa", "1,4s", true)
RenderContador("contagem-stun", "stun", "4,2s", false)
RenderContador("contagem-stun-compacta", "stun", "4,2s", true)
RenderContador("contagem-stun-fim", "stun", "1,6s", false, true)
RenderPreviewContador("contagem-previa", "pausa", false)
RenderPreviewContador("contagem-previa-compacta", "pausa", true)
RenderPreviewContador("contagem-previa-stun", "stun", false)

FileDelete(A_ScriptDir "\demo_run.ini")
ExitApp()
