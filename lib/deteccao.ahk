; =====================================================
; lib\deteccao.ahk — Detecção do pokémon fora da pokébola
; =====================================================
;
; Com o pokémon fora, o jogo mostra a barra de habilidades, que tem um
; ícone de dedo apontando na ponta. Com ele guardado (ou morto) a barra
; some. O Revive usa isso para decidir se precisa recolher o pokémon
; antes de usar o item — sem saber o estado, o primeiro Ctrl+1 soltava
; um pokémon que já estava guardado e a sequência saía invertida.
;
; Um pixel só não serve: a barra é semitransparente (a cor muda com o
; chão do mapa atrás), muda de largura conforme o número de habilidades
; e pode ser arrastada. Então o usuário captura o ícone do dedo uma vez
; e o macro procura por ele com ImageSearch (nativo, rápido) na janela
; do jogo. Na captura, os pixels escuros do recorte (o fundo
; translúcido) viram magenta e o ImageSearch os ignora (*Trans), então
; só a forma clara do dedo precisa bater.

global ARQ_ICONE_DEDO := A_ScriptDir "\revive_dedo.bmp"
global DEDO_LADO      := 14        ; lado do recorte do ícone, em px
global DEDO_VARIACAO  := 50        ; tolerância de cor do ImageSearch (0–255)
global _dedoUltX      := ""        ; último lugar onde o dedo foi achado —
global _dedoUltY      := ""        ; procurado primeiro, antes da janela toda

; Estado do pokémon: 1 = fora (dedo visível), 0 = guardado/morto,
; -1 = detecção não calibrada ou falhou (quem chama decide o fallback).
EstadoPokemonFora() {
    global ARQ_ICONE_DEDO, DEDO_VARIACAO, DEDO_LADO, JOGO_EXE, _dedoUltX, _dedoUltY

    if (CfgLer("Revive", "detectarDedo", "false") != "true" || !FileExist(ARQ_ICONE_DEDO))
        return -1

    opts := "*" DEDO_VARIACAO " *TransFF00FF " ARQ_ICONE_DEDO
    try {
        ; 1) Perto de onde estava da última vez (caso comum: barra parada)
        if (_dedoUltX != "") {
            m := 24
            if ImageSearch(&fx, &fy, _dedoUltX - m, _dedoUltY - m,
                    _dedoUltX + DEDO_LADO + m, _dedoUltY + DEDO_LADO + m, opts) {
                _dedoUltX := fx, _dedoUltY := fy
                return 1
            }
        }

        ; 2) Janela do jogo inteira (barra arrastada/redimensionada)
        if !_AreaDoJogo(&x1, &y1, &x2, &y2)
            return -1
        if ImageSearch(&fx, &fy, x1, y1, x2, y2, opts) {
            _dedoUltX := fx, _dedoUltY := fy
            return 1
        }
        return 0
    } catch
        return -1
}

; Espera o dedo sumir (pokémon recolhido) por até 'timeoutMs'.
; Devolve true se sumiu. Procura só na área onde ele foi visto por último.
EsperarDedoSumir(timeoutMs) {
    global ARQ_ICONE_DEDO, DEDO_VARIACAO, DEDO_LADO, _dedoUltX, _dedoUltY
    if (_dedoUltX = "")
        return false
    opts := "*" DEDO_VARIACAO " *TransFF00FF " ARQ_ICONE_DEDO
    m := 24
    fim := A_TickCount + timeoutMs
    while (A_TickCount < fim) {
        try {
            if !ImageSearch(&fx, &fy, _dedoUltX - m, _dedoUltY - m,
                    _dedoUltX + DEDO_LADO + m, _dedoUltY + DEDO_LADO + m, opts)
                return true
        } catch
            return false
        Sleep(10)
    }
    return false
}

_AreaDoJogo(&x1, &y1, &x2, &y2) {
    global JOGO_EXE
    try {
        WinGetPos(&wx, &wy, &ww, &wh, "ahk_exe " JOGO_EXE)
        x1 := wx, y1 := wy, x2 := wx + ww - 1, y2 := wy + wh - 1
        return true
    }
    return false
}

; Fluxo de calibração (tela de config do Revive): o usuário clica no
; centro do dedo; a captura só acontece depois que o mouse se afasta,
; para não pegar algum efeito de hover do jogo sobre o ícone.
CapturarIconeDedo() {
    global ARQ_ICONE_DEDO, DEDO_LADO, _dedoUltX, _dedoUltY
    CoordMode("Mouse", "Screen")

    ShowHint("Com o pokémon FORA, clique no centro do ícone do dedo (ESC cancela)", 999999)

    while GetKeyState("LButton", "P")
        Sleep(10)
    Loop {
        Sleep(10)
        if GetKeyState("Escape", "P") {
            ShowHint("Cancelado", 1200, "warn")
            return
        }
        if GetKeyState("LButton", "P") {
            MouseGetPos(&cx, &cy)
            break
        }
    }

    ShowHint("Agora afaste o mouse do ícone", 999999)
    fim := A_TickCount + 5000
    Loop {
        Sleep(20)
        MouseGetPos(&mx, &my)
        if (!GetKeyState("LButton", "P") && (Abs(mx - cx) > 40 || Abs(my - cy) > 40))
            break
        if (A_TickCount > fim)
            break
    }
    Sleep(150)

    x0 := cx - DEDO_LADO // 2
    y0 := cy - DEDO_LADO // 2
    px := _CapturarPixelsTela(x0, y0, DEDO_LADO, DEDO_LADO)

    ; Só os pixels claros (o dedo) entram; o fundo escuro vira magenta.
    lumMin := 255, lumMax := 0
    lums := []
    for c in px {
        l := _Luminancia(c)
        lums.Push(l)
        lumMin := Min(lumMin, l), lumMax := Max(lumMax, l)
    }
    if (lumMax - lumMin < 50) {
        ShowHint("Pouco contraste — clique bem no centro do dedo", 2200, "danger")
        return
    }
    limiar := lumMin + (lumMax - lumMin) * 0.55
    mantidos := 0
    for i, l in lums {
        if (l >= limiar)
            mantidos++
        else
            px[i] := 0xFF00FF
    }
    if (mantidos < 10) {
        ShowHint("Ícone não reconhecido — clique bem no centro do dedo", 2200, "danger")
        return
    }

    _SalvarBmp24(ARQ_ICONE_DEDO, px, DEDO_LADO, DEDO_LADO)
    SalvarCfg("Revive", "detectarDedo", "true")
    _dedoUltX := x0, _dedoUltY := y0

    if (EstadoPokemonFora() = 1)
        ShowHint("Ícone do dedo capturado!", 1500, "success")
    else
        ShowHint("Capturado, mas não reconhecido na tela — tente de novo", 2500, "warn")
}

; Botão "testar" da tela de config: roda a mesma detecção usada pelo
; revive e mostra o resultado (e quanto tempo levou).
TestarDeteccaoDedo() {
    global _dedoUltX, _dedoUltY
    t0 := A_TickCount
    estado := EstadoPokemonFora()
    ms := A_TickCount - t0
    if (estado = 1)
        ShowHint("DEDO ENCONTRADO em " _dedoUltX ", " _dedoUltY " (" ms " ms) — pokémon FORA", 2500, "success")
    else if (estado = 0)
        ShowHint("DEDO NÃO ENCONTRADO (" ms " ms) — pokémon guardado/morto", 2500, "warn")
    else if (CfgLer("Revive", "detectarDedo", "false") != "true")
        ShowHint("Capture o ícone do dedo primeiro", 2000, "danger")
    else
        ShowHint("Erro na detecção — jogo aberto? Recapture o ícone", 2500, "danger")
}

RemoverIconeDedo() {
    global ARQ_ICONE_DEDO, _dedoUltX, _dedoUltY
    try FileDelete(ARQ_ICONE_DEDO)
    _dedoUltX := "", _dedoUltY := ""
}

_Luminancia(rgb) {
    return ((rgb >> 16 & 0xFF) * 299 + (rgb >> 8 & 0xFF) * 587 + (rgb & 0xFF) * 114) // 1000
}

; Copia um retângulo da tela e devolve um Array de cores 0xRRGGBB,
; linha a linha de cima para baixo.
_CapturarPixelsTela(x, y, w, h) {
    hdcTela := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem  := DllCall("CreateCompatibleDC", "Ptr", hdcTela, "Ptr")

    bmi := Buffer(40, 0)
    NumPut("UInt",   40, bmi, 0)
    NumPut("Int",    w,  bmi, 4)
    NumPut("Int",   -h,  bmi, 8)    ; topo-para-baixo
    NumPut("UShort", 1,  bmi, 12)
    NumPut("UShort", 32, bmi, 14)
    hbm := DllCall("CreateDIBSection", "Ptr", hdcMem, "Ptr", bmi,
        "UInt", 0, "Ptr*", &bits := 0, "Ptr", 0, "UInt", 0, "Ptr")
    old := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hbm, "Ptr")

    DllCall("BitBlt", "Ptr", hdcMem, "Int", 0, "Int", 0, "Int", w, "Int", h,
        "Ptr", hdcTela, "Int", x, "Int", y, "UInt", 0x00CC0020)   ; SRCCOPY

    px := []
    Loop w * h
        px.Push(NumGet(bits, (A_Index - 1) * 4, "UInt") & 0xFFFFFF)   ; BGRA → 0xRRGGBB

    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", old)
    DllCall("DeleteObject", "Ptr", hbm)
    DllCall("DeleteDC", "Ptr", hdcMem)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcTela)
    return px
}

; Grava um BMP 24 bits (formato que o ImageSearch lê) a partir de um
; Array de cores 0xRRGGBB de cima para baixo.
_SalvarBmp24(caminho, px, w, h) {
    stride := (w * 3 + 3) & ~3
    tamPix := stride * h
    buf := Buffer(54 + tamPix, 0)

    NumPut("UShort", 0x4D42,        buf, 0)    ; "BM"
    NumPut("UInt",   54 + tamPix,   buf, 2)
    NumPut("UInt",   54,            buf, 10)   ; offset dos pixels
    NumPut("UInt",   40,            buf, 14)
    NumPut("Int",    w,             buf, 18)
    NumPut("Int",    h,             buf, 22)   ; positivo = de baixo para cima
    NumPut("UShort", 1,             buf, 26)
    NumPut("UShort", 24,            buf, 28)
    NumPut("UInt",   tamPix,        buf, 34)

    Loop h {
        linha := A_Index - 1
        base := 54 + (h - 1 - linha) * stride
        Loop w {
            c := px[linha * w + A_Index]
            o := base + (A_Index - 1) * 3
            NumPut("UChar", c & 0xFF,       buf, o)       ; B
            NumPut("UChar", c >> 8 & 0xFF,  buf, o + 1)   ; G
            NumPut("UChar", c >> 16 & 0xFF, buf, o + 2)   ; R
        }
    }

    f := FileOpen(caminho, "w")
    f.RawWrite(buf)
    f.Close()
}
