; =====================================================
; macros\revive.ahk — Execução do macro de Revive
; =====================================================

; Trava de reentrância: impede que duas execuções da sequência de
; revive (via Revive ou Combo Revive) rodem ao mesmo tempo.
global _reviveOcupado := false

; Envia a sequência de uso do item de revive (clique direito no modo
; legado, ou Ctrl+1 no modo normal). Roda em modo Critical para que
; nenhuma outra hotkey (outro revive, combo, cooldown...) consiga
; intercalar teclas no meio do caminho — sem isso, uma segunda thread
; podia soltar o Ctrl antes da hora (ex.: repeat automático do Windows
; ao segurar a tecla), fazendo o clique/target funcionar mas o item
; não ser usado.
_EnviarSequenciaRevive(cfgRev, modoLegado) {
    if (cfgRev["x"] = "N/A" || cfgRev["y"] = "N/A")
        return false

    delay := IsNumber(cfgRev["delayRevive"]) ? Integer(cfgRev["delayRevive"]) : 50

    alvoX := Integer(cfgRev["x"]), alvoY := Integer(cfgRev["y"])
    xAtual := ""

    Critical("On")
    try {
        ; Só recolhe o pokémon se ele estiver fora: guardado ou morto, o
        ; primeiro Ctrl+1/clique o soltaria e a sequência sairia invertida.
        ; Sem detecção calibrada (-1), mantém o comportamento antigo.
        estado := EstadoPokemonFora()

        MouseGetPos(&xAtual, &yAtual)
        ; Trava o mouse até o fim da sequência: um esbarrão tirava o cursor
        ; do ponto salvo e o revive acabava usado/clicado em outra coisa.
        ; Tudo é desfeito no finally.
        ;  - BlockInput MouseMove: descarta o movimento físico no hook.
        ;  - ClipCursor (_PrenderCursor): prende o cursor no ponto pelo próprio
        ;    Windows. Necessário porque o BlockInput deixa passar movimento
        ;    marcado como "injetado" — e muitos mouses com software próprio
        ;    (G Hub, Synapse...) ou drivers mandam o movimento assim.
        ;  - _TravarBotoesMouse: engole os cliques físicos.
        BlockInput("MouseMove")
        _TravarBotoesMouse(true)
        _FixarCursor(alvoX, alvoY)

        if (estado != 0) {
            _AlternarPokebola(modoLegado, alvoX, alvoY)
            ; Com detecção, espera o jogo de fato recolher antes do item —
            ; o delay sozinho, se muito baixo, atropelava o jogo.
            if (estado = 1)
                EsperarDedoSumir(500)
            Sleep(delay)
        }
        if (cfgRev["teclaInputRevive"] != "N/A") {
            _FixarCursor(alvoX, alvoY)
            SendEvent("{" cfgRev["teclaInputRevive"] " down}")
            SendEvent("{" cfgRev["teclaInputRevive"] " up}")
        }
        _AlternarPokebola(modoLegado, alvoX, alvoY)
    } finally {
        _SoltarCursor()
        if (xAtual != "")
            MouseMove(xAtual, yAtual, 0)
        _TravarBotoesMouse(false)
        BlockInput("MouseMoveOff")
        Critical("Off")
    }

    return true
}

; Leva o cursor ao ponto e o prende lá (retângulo de 1x1 px via ClipCursor).
; Chamado de novo antes de cada ação: o Windows desfaz o ClipCursor quando
; outra janela vem para frente, e o jogo pode chamar ClipCursor por conta
; própria — reaplicar garante que cada tecla/clique sai no ponto certo.
_FixarCursor(x, y) {
    DllCall("ClipCursor", "Ptr", 0)
    MouseMove(x, y, 0)
    DllCall("GetCursorPos", "Int64*", &pt := 0)   ; ponto real em coords de tela
    cx := pt << 32 >> 32, cy := pt >> 32
    rect := Buffer(16)
    NumPut("Int", cx, "Int", cy, "Int", cx + 1, "Int", cy + 1, rect)
    DllCall("ClipCursor", "Ptr", rect)
}

_SoltarCursor() {
    DllCall("ClipCursor", "Ptr", 0)
}

; Liga/desliga hotkeys que engolem os cliques físicos do mouse durante o
; revive. Só o "down" é bloqueado: o hook do AHK já descarta o "up" de um
; down engolido, e um botão que já estava pressionado antes do revive
; continua podendo ser solto normalmente (senão o jogo o veria preso).
; Cliques enviados pelo próprio script (Click("Right") do modo legado)
; não disparam hotkeys, então passam normalmente.
_TravarBotoesMouse(ligar) {
    static botoes := ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
    static engolir := (*) => 0
    HotIf()   ; registra no contexto global, não no HotIf da thread atual
    for b in botoes
        Hotkey("*" b, engolir, ligar ? "On" : "Off")
}

; Recolhe/solta o pokémon: clique direito no alvo (modo legado) ou Ctrl+1.
_AlternarPokebola(modoLegado, alvoX, alvoY) {
    _FixarCursor(alvoX, alvoY)
    if (modoLegado = "true") {
        Click("Right")
    } else {
        SendEvent("{Ctrl down}{1 down}")
        SendEvent("{1 up}{Ctrl up}")
    }
}

ExecutarRevive() {
    global macros, _reviveOcupado

    if !macros["revive"]
        return

    ; Sempre interrompe um combo em andamento, mesmo que esta
    ; execução do revive acabe sendo ignorada por reentrância abaixo.
    InterromperCombo()

    if (_reviveOcupado)
        return

    cfg        := GetCfg("Revive")
    modoLegado := GetModoLegado()

    _reviveOcupado := true
    try {
        if !_EnviarSequenciaRevive(cfg, modoLegado)
            ShowHint("Erro: Defina a posição primeiro!", 1500, "danger")
    } finally {
        _reviveOcupado := false
    }
}
