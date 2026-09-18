; =====================================================
; lib\gdip.ahk — Wrapper mínimo de GDI+ via DllCall
; =====================================================
;
; Só o subconjunto usado pela HUD (ui\mini_menu.ahk): criação de uma
; camada (bitmap ARGB pré-multiplicado sobre um DIB de topo-para-baixo)
; desenhada com GDI+ e apresentada numa janela em camadas (UpdateLayeredWindow),
; o que permite cantos arredondados e transparência real por pixel — algo que
; os controles nativos Gui (usados no resto do app) não suportam.

global _gdipHDCScreen := 0
global _gdipToken     := 0

; ── Ciclo de vida ──────────────────────────────────────
Gdip_Startup() {
    DllCall("LoadLibrary", "Str", "gdiplus.dll")
    si := Buffer(24, 0)
    NumPut("UInt", 1, si, 0)   ; GdiplusVersion = 1
    DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken := 0, "Ptr", si, "Ptr", 0)
    return pToken
}

Gdip_Shutdown(pToken) {
    if (pToken)
        DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
}

; Inicializa o GDI+ uma única vez para todo o app (HUD + telas de
; configuração), não importa qual delas abre primeiro.
Gdip_EnsureStarted() {
    global _gdipToken
    if (!_gdipToken) {
        _gdipToken := Gdip_Startup()
        OnExit((*) => Gdip_Shutdown(_gdipToken))
    }
    return _gdipToken
}

; ── Canvas em camadas (DIB de topo p/ baixo + Graphics do GDI+) ──
; Devolve um objeto com: w, h, hBitmap, ppvBits, pBitmap, pGraphics
Gdip_NewLayeredCanvas(w, h) {
    global _gdipHDCScreen
    if (!_gdipHDCScreen)
        _gdipHDCScreen := DllCall("GetDC", "Ptr", 0, "Ptr")

    bmi := Buffer(40, 0)
    NumPut("UInt",   40, bmi, 0)   ; biSize
    NumPut("Int",    w,  bmi, 4)   ; biWidth
    NumPut("Int",   -h,  bmi, 8)   ; biHeight negativo = topo-para-baixo
    NumPut("UShort", 1,  bmi, 12)  ; biPlanes
    NumPut("UShort", 32, bmi, 14)  ; biBitCount
    NumPut("UInt",   0,  bmi, 16)  ; biCompression = BI_RGB

    hBitmap := DllCall("CreateDIBSection", "Ptr", _gdipHDCScreen, "Ptr", bmi,
        "UInt", 0, "Ptr*", &ppvBits := 0, "Ptr", 0, "UInt", 0, "Ptr")

    ; PixelFormat32bppPARGB — alfa pré-multiplicado, exatamente o que
    ; UpdateLayeredWindow espera receber.
    DllCall("gdiplus\GdipCreateBitmapFromScan0",
        "Int", w, "Int", h, "Int", w * 4, "Int", 0xE200B,
        "Ptr", ppvBits, "Ptr*", &pBitmap := 0)

    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", &pGraphics := 0)
    DllCall("gdiplus\GdipSetSmoothingMode",       "Ptr", pGraphics, "Int", 4) ; AntiAlias
    DllCall("gdiplus\GdipSetInterpolationMode",   "Ptr", pGraphics, "Int", 7) ; HighQualityBicubic (ícones nítidos ao redimensionar)
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", pGraphics, "Int", 4) ; AntiAlias
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", 0x00000000)

    ; capW/capH = tamanho real do DIB alocado; w/h = tamanho lógico exibido
    ; nesse frame (ver Gdip_ResizeCanvas — podem ser menores que a capacidade
    ; quando o canvas é reaproveitado entre frames).
    return { w: w, h: h, capW: w, capH: h, hBitmap: hBitmap, ppvBits: ppvBits, pBitmap: pBitmap, pGraphics: pGraphics }
}

; Redimensiona logicamente um canvas persistente (passado por referência),
; reaproveitando o DIB/Graphics do GDI+ quando ele já é grande o bastante
; e só recriando (destruindo o antigo) quando precisa crescer. Recriar
; CreateDIBSection + GdipCreateBitmapFromScan0 do zero a cada frame — como
; a HUD fazia, redesenhando a até 60fps durante hover/expandir — é a causa
; mais cara de lag nessas animações; aqui o custo por frame vira só um
; GdipGraphicsClear (memset) na área já alocada.
Gdip_ResizeCanvas(&canvasVar, w, h) {
    if (!IsObject(canvasVar) || w > canvasVar.capW || h > canvasVar.capH) {
        capW := IsObject(canvasVar) ? Max(canvasVar.capW, w) : w
        capH := IsObject(canvasVar) ? Max(canvasVar.capH, h) : h
        if IsObject(canvasVar)
            Gdip_DestroyLayeredCanvas(canvasVar)
        canvasVar := Gdip_NewLayeredCanvas(capW, capH)
    } else {
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", canvasVar.pGraphics, "UInt", 0x00000000)
    }
    canvasVar.w := w
    canvasVar.h := h
    return canvasVar
}

; Envia o canvas para a tela através de UpdateLayeredWindow (janela toda,
; posição e tamanho vêm juntos nessa mesma chamada). O DC de memória fica
; guardado no próprio canvas e é reaproveitado entre chamadas (criado só na
; primeira vez que esse hBitmap é apresentado) — o mesmo raciocínio do
; Gdip_ResizeCanvas: recriar CreateCompatibleDC/SelectObject a cada frame
; custa mais do que manter um DC vivo enquanto o bitmap não muda.
Gdip_PresentLayeredCanvas(canvas, hwnd, x, y) {
    global _gdipHDCScreen

    if (!canvas.HasOwnProp("hdcMem")) {
        canvas.hdcMem := DllCall("CreateCompatibleDC", "Ptr", _gdipHDCScreen, "Ptr")
        canvas.hOld   := DllCall("SelectObject", "Ptr", canvas.hdcMem, "Ptr", canvas.hBitmap, "Ptr")
    }

    sizeBuf := Buffer(8)
    NumPut("Int", canvas.w, sizeBuf, 0)
    NumPut("Int", canvas.h, sizeBuf, 4)

    ptSrc := Buffer(8, 0)

    ptDst := Buffer(8)
    NumPut("Int", x, ptDst, 0)
    NumPut("Int", y, ptDst, 4)

    blend := Buffer(4, 0)
    NumPut("UChar", 0,   blend, 0) ; AC_SRC_OVER
    NumPut("UChar", 0,   blend, 1) ; flags
    NumPut("UChar", 255, blend, 2) ; SourceConstantAlpha
    NumPut("UChar", 1,   blend, 3) ; AC_SRC_ALPHA

    DllCall("UpdateLayeredWindow", "Ptr", hwnd, "Ptr", _gdipHDCScreen,
        "Ptr", ptDst, "Ptr", sizeBuf, "Ptr", canvas.hdcMem, "Ptr", ptSrc,
        "UInt", 0, "Ptr", blend, "UInt", 2) ; ULW_ALPHA
}

Gdip_DestroyLayeredCanvas(canvas) {
    if (canvas.HasOwnProp("hdcMem")) {
        DllCall("SelectObject", "Ptr", canvas.hdcMem, "Ptr", canvas.hOld, "Ptr")
        DllCall("DeleteDC", "Ptr", canvas.hdcMem)
    }
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", canvas.pGraphics)
    DllCall("gdiplus\GdipDisposeImage",   "Ptr", canvas.pBitmap)
    DllCall("DeleteObject", "Ptr", canvas.hBitmap)
}

; ── Cor ────────────────────────────────────────────────
; hex: string do tema, ex. "0x57f287"
Gdip_Argb(alpha, hex) {
    return (alpha << 24) | (Integer(hex) & 0xFFFFFF)
}

; Interpola entre duas cores do tema (hexA -> hexB) por t (0..1)
Gdip_LerpArgb(alpha, hexA, hexB, t) {
    a := Integer(hexA), b := Integer(hexB)
    r := Round(((a >> 16) & 0xFF) + ((((b >> 16) & 0xFF) - ((a >> 16) & 0xFF)) * t))
    g := Round(((a >> 8)  & 0xFF) + ((((b >> 8)  & 0xFF) - ((a >> 8)  & 0xFF)) * t))
    bl := Round((a & 0xFF)        + (((b & 0xFF) - (a & 0xFF)) * t))
    return (alpha << 24) | (r << 16) | (g << 8) | bl
}

; ── Pincéis / canetas ──────────────────────────────────
Gdip_BrushSolid(argb) {
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", &pBrush := 0)
    return pBrush
}
Gdip_DeleteBrush(pBrush) => DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)

Gdip_Pen(argb, width := 1.4) {
    DllCall("gdiplus\GdipCreatePen1", "UInt", argb, "Float", width, "Int", 2, "Ptr*", &pPen := 0)
    DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPen, "Int", 2) ; Round
    DllCall("gdiplus\GdipSetPenEndCap",   "Ptr", pPen, "Int", 2) ; Round
    DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", pPen, "Int", 2) ; Round
    return pPen
}
Gdip_DeletePen(pPen) => DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)

; ── Formas ─────────────────────────────────────────────
Gdip_FillEllipse(g, brush, x, y, w, h) =>
    DllCall("gdiplus\GdipFillEllipse", "Ptr", g, "Ptr", brush, "Float", x, "Float", y, "Float", w, "Float", h)

Gdip_DrawEllipse(g, pen, x, y, w, h) =>
    DllCall("gdiplus\GdipDrawEllipse", "Ptr", g, "Ptr", pen, "Float", x, "Float", y, "Float", w, "Float", h)

Gdip_DrawLine(g, pen, x1, y1, x2, y2) =>
    DllCall("gdiplus\GdipDrawLine", "Ptr", g, "Ptr", pen, "Float", x1, "Float", y1, "Float", x2, "Float", y2)

Gdip_FillRect(g, brush, x, y, w, h) =>
    DllCall("gdiplus\GdipFillRectangle", "Ptr", g, "Ptr", brush, "Float", x, "Float", y, "Float", w, "Float", h)

Gdip_DrawPolygon(g, pen, pts) {
    n := pts.Length // 2
    buf := Buffer(8 * n)
    loop n {
        NumPut("Float", pts[(A_Index - 1) * 2 + 1], buf, (A_Index - 1) * 8)
        NumPut("Float", pts[(A_Index - 1) * 2 + 2], buf, (A_Index - 1) * 8 + 4)
    }
    DllCall("gdiplus\GdipDrawPolygon", "Ptr", g, "Ptr", pen, "Ptr", buf, "Int", n)
}

Gdip_FillPolygon(g, brush, pts) {
    n := pts.Length // 2
    buf := Buffer(8 * n)
    loop n {
        NumPut("Float", pts[(A_Index - 1) * 2 + 1], buf, (A_Index - 1) * 8)
        NumPut("Float", pts[(A_Index - 1) * 2 + 2], buf, (A_Index - 1) * 8 + 4)
    }
    DllCall("gdiplus\GdipFillPolygon", "Ptr", g, "Ptr", brush, "Ptr", buf, "Int", n, "Int", 0) ; FillModeAlternate
}

Gdip_DrawArc(g, pen, x, y, w, h, startAngle, sweepAngle) =>
    DllCall("gdiplus\GdipDrawArc", "Ptr", g, "Ptr", pen,
        "Float", x, "Float", y, "Float", w, "Float", h, "Float", startAngle, "Float", sweepAngle)

_Gdip_RoundRectPath(x, y, w, h, r) {
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", &p := 0)
    d := r * 2
    DllCall("gdiplus\GdipAddPathArc", "Ptr", p, "Float", x,         "Float", y,         "Float", d, "Float", d, "Float", 180, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", p, "Float", x + w - d, "Float", y,         "Float", d, "Float", d, "Float", 270, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", p, "Float", x + w - d, "Float", y + h - d, "Float", d, "Float", d, "Float", 0,   "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", p, "Float", x,         "Float", y + h - d, "Float", d, "Float", d, "Float", 90,  "Float", 90)
    DllCall("gdiplus\GdipClosePathFigure", "Ptr", p)
    return p
}

Gdip_FillRoundRect(g, brush, x, y, w, h, r) {
    p := _Gdip_RoundRectPath(x, y, w, h, r)
    DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", brush, "Ptr", p)
    DllCall("gdiplus\GdipDeletePath", "Ptr", p)
}

Gdip_DrawRoundRect(g, pen, x, y, w, h, r) {
    p := _Gdip_RoundRectPath(x, y, w, h, r)
    DllCall("gdiplus\GdipDrawPath", "Ptr", g, "Ptr", pen, "Ptr", p)
    DllCall("gdiplus\GdipDeletePath", "Ptr", p)
}

; Recorta os desenhos seguintes a um retângulo de cantos arredondados —
; usado para pintar um cabeçalho/corpo em blocos retos que ainda assim
; respeitam a moldura arredondada da janela (sem isso, os cantos do
; cabeçalho ficariam quadrados por cima do fundo arredondado).
Gdip_SetClipRoundRect(g, x, y, w, h, r) {
    p := _Gdip_RoundRectPath(x, y, w, h, r)
    DllCall("gdiplus\GdipSetClipPath", "Ptr", g, "Ptr", p, "Int", 0) ; CombineModeReplace
    DllCall("gdiplus\GdipDeletePath", "Ptr", p)
}

Gdip_ResetClip(g) => DllCall("gdiplus\GdipResetClip", "Ptr", g)

; Escala tudo que for desenhado depois (formas, canetas, texto) — usado
; pelas telas de configuração para ficarem maiores sem reescrever a
; matemática de layout de cada widget (lib\gdip_config.ahk).
Gdip_ScaleTransform(g, sx, sy) =>
    DllCall("gdiplus\GdipScaleWorldTransform", "Ptr", g, "Float", sx, "Float", sy, "Int", 0) ; MatrixOrderPrepend

; ── Imagens (ícones .png já existentes em icons\) ──────
Gdip_LoadImage(path) {
    static cache := Map()
    if cache.Has(path)
        return cache[path]
    DllCall("gdiplus\GdipLoadImageFromFile", "WStr", path, "Ptr*", &pImg := 0)
    cache[path] := pImg
    return pImg
}

Gdip_DrawImage(g, pImg, x, y, w, h) {
    if (!pImg)
        return
    DllCall("gdiplus\GdipDrawImageRectI", "Ptr", g, "Ptr", pImg,
        "Int", Round(x), "Int", Round(y), "Int", Round(w), "Int", Round(h))
}

; Desenha um ícone monocromático (ex.: PNG preto com fundo transparente)
; recolorido para "argb" — zera o RGB original via ColorMatrix e soma a
; cor alvo, preservando o alfa (contorno anti-aliased) do PNG de origem.
; Usado para reaproveitar ícones prontos baixados em preto no tema escuro.
Gdip_DrawImageTinted(g, pImg, x, y, w, h, argb) {
    if (!pImg)
        return
    r  := ((argb >> 16) & 0xFF) / 255.0
    gg := ((argb >> 8)  & 0xFF) / 255.0
    b  := (argb & 0xFF) / 255.0

    vals := [0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,1,0, r,gg,b,0,1]
    m := Buffer(25 * 4, 0)
    for i, v in vals
        NumPut("Float", v, m, (i - 1) * 4)

    DllCall("gdiplus\GdipCreateImageAttributes", "Ptr*", &ia := 0)
    DllCall("gdiplus\GdipSetImageAttributesColorMatrix",
        "Ptr", ia, "Int", 0, "Int", 1, "Ptr", m, "Ptr", 0, "Int", 0)

    DllCall("gdiplus\GdipGetImageWidth",  "Ptr", pImg, "UInt*", &srcW := 0)
    DllCall("gdiplus\GdipGetImageHeight", "Ptr", pImg, "UInt*", &srcH := 0)
    DllCall("gdiplus\GdipDrawImageRectRectI", "Ptr", g, "Ptr", pImg,
        "Int", Round(x), "Int", Round(y), "Int", Round(w), "Int", Round(h),
        "Int", 0, "Int", 0, "Int", srcW, "Int", srcH,
        "Int", 2, "Ptr", ia, "Ptr", 0, "Ptr", 0) ; UnitPixel

    DllCall("gdiplus\GdipDisposeImageAttributes", "Ptr", ia)
}

; Pré-renderiza um ícone no tamanho exato em que será usado, uma única vez,
; e cacheia o resultado. Reamostrar um PNG em alta qualidade a cada frame
; (a 60 fps, com vários ícones) é caro; desenhar um bitmap já do tamanho
; certo é uma cópia quase direta.
Gdip_ScaledIcon(path, size) {
    static cache := Map()
    key := path "@" size
    if cache.Has(key)
        return cache[key].pBitmap

    src := Gdip_LoadImage(path)
    canvas := Gdip_NewLayeredCanvas(size, size)
    Gdip_DrawImage(canvas.pGraphics, src, 0, 0, size, size)
    cache[key] := canvas   ; mantém o canvas vivo (dono do bitmap) pelo resto da sessão
    return canvas.pBitmap
}

; ── Texto ──────────────────────────────────────────────
Gdip_Font(size, bold := false) {
    static cache := Map()
    key := size "_" bold
    if cache.Has(key)
        return cache[key]
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe UI", "Ptr", 0, "Ptr*", &fam := 0)
    DllCall("gdiplus\GdipCreateFont", "Ptr", fam, "Float", size, "Int", bold ? 1 : 0, "Int", 2, "Ptr*", &font := 0)
    cache[key] := font
    return font
}

Gdip_StringFormat(center := true) {
    static fCenter := 0
    static fLeft := 0
    ; 0x1000 NoWrap + 0x4000 NoClip — sem NoClip, o GDI+ corta qualquer
    ; parte do glifo que ultrapasse o retângulo passado a Gdip_DrawText;
    ; símbolos como "×"/"↺" costumam ultrapassar sua caixa nominal, e
    ; isso ficou visível ao aumentar a escala das telas de configuração.
    if (center) {
        if (!fCenter) {
            DllCall("gdiplus\GdipCreateStringFormat", "Int", 0x5000, "Int", 0, "Ptr*", &f := 0)
            DllCall("gdiplus\GdipSetStringFormatAlign",     "Ptr", f, "Int", 1) ; Center
            DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", f, "Int", 1) ; Center
            fCenter := f
        }
        return fCenter
    } else {
        if (!fLeft) {
            DllCall("gdiplus\GdipCreateStringFormat", "Int", 0x5000, "Int", 0, "Ptr*", &f := 0)
            DllCall("gdiplus\GdipSetStringFormatAlign",     "Ptr", f, "Int", 0) ; Near
            DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", f, "Int", 1) ; Center
            fLeft := f
        }
        return fLeft
    }
}

; Mede o retângulo que "text" ocupa nessa fonte, sem desenhar nada —
; usado pelo banner de notificações (lib\hint.ahk) pra dimensionar a
; janela ao texto em vez de usar uma largura fixa pra tudo.
Gdip_MeasureText(text, size, bold := true, maxW := 4000) {
    global _gdipHDCScreen
    if (!_gdipHDCScreen)
        _gdipHDCScreen := DllCall("GetDC", "Ptr", 0, "Ptr")

    DllCall("gdiplus\GdipCreateFromHDC", "Ptr", _gdipHDCScreen, "Ptr*", &g := 0)
    font := Gdip_Font(size, bold)
    fmt  := Gdip_StringFormat(false)

    rc := Buffer(16, 0)
    NumPut("Float", maxW, rc, 8)
    NumPut("Float", 1000, rc, 12)

    out := Buffer(16, 0)
    DllCall("gdiplus\GdipMeasureString", "Ptr", g, "WStr", text, "Int", -1,
        "Ptr", font, "Ptr", rc, "Ptr", fmt, "Ptr", out, "Int*", &chars := 0, "Int*", &lines := 0)

    w := NumGet(out, 8, "Float")
    h := NumGet(out, 12, "Float")
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
    return [w, h]
}

Gdip_DrawText(g, text, size, bold, argb, x, y, w, h, center := true) {
    font  := Gdip_Font(size, bold)
    fmt   := Gdip_StringFormat(center)
    brush := Gdip_BrushSolid(argb)
    rc := Buffer(16)
    NumPut("Float", x, rc, 0)
    NumPut("Float", y, rc, 4)
    NumPut("Float", w, rc, 8)
    NumPut("Float", h, rc, 12)
    DllCall("gdiplus\GdipDrawString", "Ptr", g, "WStr", text, "Int", -1, "Ptr", font, "Ptr", rc, "Ptr", fmt, "Ptr", brush)
    Gdip_DeleteBrush(brush)
}
