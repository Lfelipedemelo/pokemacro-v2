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
#Include ..\..\ui\mini_menu.ahk
#Include ..\..\ui\config_combo.ahk
#Include ..\..\ui\config_revive.ahk
#Include ..\..\ui\config_cooldown.ahk
#Include ..\..\ui\config_combo_revive.ahk
#Include ..\..\ui\config_geral.ahk
#Include ..\..\macros\hotkeys.ahk
#Include ..\..\macros\combo.ahk
#Include ..\..\macros\revive.ahk
#Include ..\..\macros\cooldown.ahk
#Include ..\..\macros\combo_revive.ahk

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
RenderCfg(nome, w, h, drawFn, anot, hoverId := "", confirm := 0) {
    global S, OUT, _gcfgConfirm
    canvas := Gdip_NewLayeredCanvas(w * S, h * S)
    g := canvas.pGraphics
    Gdip_ScaleTransform(g, S, S)
    boxes := drawFn.Call(g, w, h, hoverId)
    if (confirm) {
        _gcfgConfirm := confirm
        _GCfg_DesenharConfirmacao(g, w, h, hoverId)
        _gcfgConfirm := 0
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

; Mesmo desenho do ShowHint (lib\hint.ahk), só que para um PNG.
RenderHint(nome, text, kind) {
    global S, OUT
    pal := _HintPaleta(kind)
    PAD := 24, ICON_D := 44, GAP := 18, fontSz := 15, radius := 16
    sz   := Gdip_MeasureText(text, fontSz, true, 720)
    txtW := Ceil(sz[1]) + 2
    txtH := Ceil(sz[2])
    h := PAD + Max(ICON_D, txtH) + PAD
    w := PAD + ICON_D + GAP + txtW + PAD
    k := 1.25
    canvas := Gdip_NewLayeredCanvas(Ceil(w * k), Ceil(h * k))
    g := canvas.pGraphics
    Gdip_ScaleTransform(g, k, k)

    bgBrush := Gdip_BrushSolid(Gdip_Argb(245, T()["BG"]))
    Gdip_FillRoundRect(g, bgBrush, 0, 0, w, h, radius)
    Gdip_DeleteBrush(bgBrush)
    Gdip_SetClipRoundRect(g, 0, 0, w, h, radius)
    stripeBrush := Gdip_BrushSolid(Gdip_Argb(255, pal["cor"]))
    Gdip_FillRect(g, stripeBrush, 0, 0, w, 4)
    Gdip_DeleteBrush(stripeBrush)
    Gdip_ResetClip(g)
    borderPen := Gdip_Pen(Gdip_Argb(255, T()["SEP"]), 1.4)
    Gdip_DrawRoundRect(g, borderPen, 0.5, 0.5, w - 1, h - 1, radius)
    Gdip_DeletePen(borderPen)
    icCx := PAD + ICON_D / 2, icCy := h / 2
    icBg := Gdip_BrushSolid(Gdip_Argb(46, pal["cor"]))
    Gdip_FillEllipse(g, icBg, icCx - ICON_D / 2, icCy - ICON_D / 2, ICON_D, ICON_D)
    Gdip_DeleteBrush(icBg)
    icRing := Gdip_Pen(Gdip_Argb(255, pal["cor"]), 1.8)
    Gdip_DrawEllipse(g, icRing, icCx - ICON_D / 2, icCy - ICON_D / 2, ICON_D, ICON_D)
    Gdip_DeletePen(icRing)
    Gdip_DrawText(g, pal["glifo"], 18, true, Gdip_Argb(255, pal["cor"]),
        icCx - ICON_D / 2, icCy - ICON_D / 2, ICON_D, ICON_D, true)
    Gdip_DrawText(g, text, fontSz, true, Gdip_Argb(255, T()["TEXT"]), PAD + ICON_D + GAP, 0, txtW, h, false)

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
RenderCfg("config-combo", 288, 308, _DesenharConfigCombo.Bind("comboPrincipal"),
    [[1, "inicial"], [2, "final"], [3, "hkmacro"], [4, "toggle"], [5, "atk_a"], [6, "def_a"], [7, "sleep"], [8, "showmini_a"]])

RenderCfg("config-combo-reset", 288, 308, _DesenharConfigCombo.Bind("comboPrincipal"), [], "conf_nao",
    { titulo: "RESETAR COMBOPRINCIPAL?", sub: "Esta ação não pode ser desfeita.", onSim: 0, textoSim: "SIM, RESETAR" })

RenderCfg("config-revive", 288, 308, _DesenharConfigRevive,
    [[1, "pos"], [2, "hkrevive"], [3, "delay"], [4, "hkmacro"], [5, "toggle"], [6, "dedo"], [7, "dedoTeste"], [8, "showmini_a"]])

RenderCfg("config-combo-revive", 288, 360, _DesenharConfigComboRevive,
    [[1, "inicial"], [2, "final"], [3, "hkmacro"], [4, "toggle"], [5, "atk_a"], [6, "def_a"], [7, "delay"], [8, "sleep"], [9, "showmini_a"]])

RenderCfg("config-cooldown", 288, 422, _DesenharConfigCooldown,
    [[1, "hkcd"], [2, "toggle"], [3, "pkm_1"], [4, 267, 155], [5, 267, 237], [6, "fd_a"], [7, "showmini_a"]])

RenderCfg("config-geral", 288, 476, _DesenharConfigGeral,
    [[1, "prefF_a"], [2, "legado_a"], [3, "escala_1"], [4, "orient_a"], [5, "panico"], [6, "fa"], [7, "fd"], [8, "vis_comboPrincipal_a"]])

; hover num campo, para mostrar o destaque
RenderCfg("config-combo-hover", 288, 308, _DesenharConfigCombo.Bind("comboPrincipal"), [], "hkmacro")

; ── HUD ─────────────────────────────────────────────────
_HUD_SCALE := 2
miniGui := Gui("-Caption +ToolWindow +E0x80000")
macros["comboPrincipal"] := true
macros["revive"] := true
RenderHud("hud", false, Map())
RenderHud("hud-hover", true, Map("bar_c1", 1.0), true)
macros["comboPrincipal"] := false
macros["revive"] := false
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

FileDelete(A_ScriptDir "\demo_run.ini")
ExitApp()
