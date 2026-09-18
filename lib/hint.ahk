; =====================================================
; lib\hint.ahk — Notificações flutuantes (tema Pokémon)
; =====================================================
;
; Estilo: caixa de diálogo Pokémon
;   Fundo    : azul-noite  0x1A1A2E
;   Borda    : amarelo     0xFFCC00
;   Texto    : branco      0xF5F5F5
;   Fonte    : Courier New Bold (pixel-art feel)

ShowHint(text, time := 1200) {
    static hint := 0
    static tmr  := 0

    if (tmr)
        SetTimer(tmr, 0)

    if IsObject(hint) {
        try hint.Destroy()
    }

    if (text = "")
        return

    hint := Gui("+AlwaysOnTop -Caption +ToolWindow")
    hint.BackColor := T()["BG"]

    hint.AddText("x0 y0 w420 h5 Background" T()["ACCENT"])

    txt := hint.AddText("x0 y5 Center c" T()["TEXT"] " w420 h44 +0x200", text)
    txt.SetFont(GF() " Bold")

    hint.AddText("x0 y49 w420 h5 Background" T()["ACCENT"])

    hint.Show("AutoSize Center")

    tmr := (*) => hint.Destroy()
    SetTimer(tmr, -time)
}
