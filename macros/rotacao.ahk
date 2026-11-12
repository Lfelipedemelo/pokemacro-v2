; =====================================================
; macros\rotacao.ahk — Execução do macro de Rotação
; =====================================================
;
; Uma tecla só que vai trocando de pokémon numa ordem salva: cada
; pressionamento envia o Ctrl+N do passo atual e avança para o próximo.
; A sequência é uma rotação após a outra (passos vazios são pulados) e
; volta ao começo depois do último passo — ex.: 1-2-3-4 | 1-2-5-6 (2x4)
; ou 1-2-3 | 1-4-5 | 1-—-6 (3x3).
; A HUD mostra no ícone qual Ctrl+N sai no próximo pressionamento.
; Cada pressionamento também interrompe o combo em andamento; se o passo
; tiver Pokestop ligado, aperta a tecla Pokestop logo depois da troca, e
; se tiver um combo marcado (Combo 1/2), solta esse combo em seguida.
;
; Passo de ITEM (ex.: 2º da 3ª rotação no 3x3 — 1, item, 6): alterna a
; cada volta da sequência entre o elixir de ataque e o revive, ambos no
; pokémon anterior ao ITEM (normalmente o 1º, puxado à mão):
;  - volta ímpar = ELIXIR: o passo é pulado pela tecla da Rotação; o
;    elixir sai no 1º Combo Principal/Secundário apertado com a posição
;    parada no ITEM, antes das skills (RotacaoUsarElixir).
;  - volta par = REVIVE: a tecla da Rotação faz o revive do macro Revive
;    (recolhe, usa o item, solta) e, se o passo tiver, Pokestop e combo.
; Cada um pode ficar "à mão" (elixirModo/reviveModo = mao): o macro não
; faz nada naquela volta e o passo é pulado.

global _rotacaoPos := 1   ; índice, na sequência, do próximo passo a enviar
global _rotacaoCiclo := 1   ; volta da sequência (1, 2, ...): ímpar = vez do elixir, par = do revive
global _rotacaoElixirUsado := false   ; elixir já usado nesta posição (um 2º combo não repete)
global _rotacaoComboPendente := 0   ; { combo, gen, elixir } a soltar pelo timer (ver _RodarComboRotacao) ou 0

; Sequência completa (todas as rotações, em ordem), sem os passos vazios.
; Formato 2x4 (2 rotações de 4) ou 3x3 (3 de 3) — ver GetFormatoRotacao.
; Cada item: { slot: N do Ctrl+N (ou ROTACAO_ITEM), rot: 1..3, passo: 1..4,
; combo: 0..2, stop: aperta a tecla Pokestop depois da troca, item: passo
; de ITEM }.
; Com "1º POKÉMON = PULAR" (padrão) o 1º passo de CADA rotação
; fica de fora: o jogador puxa esse pokémon à mão no começo de toda
; rotação, então o macro só chama do 2º em diante — ex.: 2-3-4 | 2-5-6.
RotacaoSequencia() {
    pularPrimeiro := !RotacaoEnviarPrimeiro()
    fmt := GetFormatoRotacao()
    seq := []
    Loop fmt.rotacoes {
        rot := A_Index
        Loop fmt.passos {
            if (pularPrimeiro && A_Index = 1)
                continue
            slot := _CfgSlotRotacao(rot, A_Index)
            if (slot > 0)
                seq.Push({ slot: slot, rot: rot, passo: A_Index, combo: _CfgComboRotacao(rot, A_Index),
                    stop: _CfgPokestopRotacao(rot, A_Index), item: slot = ROTACAO_ITEM })
        }
    }
    return seq
}

RotacaoEnviarPrimeiro() {
    return CfgLer("Rotacao", "enviarPrimeiro", "false") = "true"
}

RotacaoVezDoElixir() {
    global _rotacaoCiclo
    return Mod(_rotacaoCiclo, 2) = 1
}

; Passo de ITEM que a tecla da Rotação pula na volta 'ciclo': na vez do
; elixir (que sai na tecla do combo, não aqui) ou na do revive à mão.
_RotacaoPulaItem(e, ciclo) {
    return e.item && (Mod(ciclo, 2) = 1 || !RotacaoRevivePeloMacro())
}

; Passo que a tecla da Rotação vai de fato enviar, a partir da posição
; atual, pulando os de ITEM que não saem na volta. Devolve { e, pos, ciclo }
; (onde a posição e a volta param), ou 0 se não há nada a enviar.
; A sequência pode ter encolhido desde o último envio (config editada),
; então a posição é reduzida à faixa válida aqui em vez de confiar nela.
_RotacaoAlvo() {
    global _rotacaoPos, _rotacaoCiclo
    seq := RotacaoSequencia()
    if !seq.Length
        return 0
    if (_rotacaoPos > seq.Length || _rotacaoPos < 1)
        _rotacaoPos := 1
    pos := _rotacaoPos, ciclo := _rotacaoCiclo
    ; duas voltas: um ITEM pulado numa volta sai na seguinte
    Loop seq.Length * 2 {
        if !_RotacaoPulaItem(seq[pos], ciclo)
            return { e: seq[pos], pos: pos, ciclo: ciclo }
        if (pos >= seq.Length)
            pos := 1, ciclo++
        else
            pos++
    }
    return 0   ; só passos de ITEM, com o revive à mão
}

; Próximo passo que será enviado, ou 0 se não houver nenhum configurado.
RotacaoProxima() {
    alvo := _RotacaoAlvo()
    return alvo ? alvo.e : 0
}

ExecutarRotacao() {
    global _rotacaoPos, _rotacaoComboPendente
    alvo := _RotacaoAlvo()
    if !alvo {
        ShowHint("ROTAÇÃO: nenhum pokémon configurado", 1600, "danger")
        return
    }
    prox := alvo.e
    ; Para o combo que estiver rodando (inclusive o pós-troca de um
    ; aperto anterior): sem isso as skills restantes — e o Full Defense —
    ; sairiam no pokémon que acabou de entrar.
    gen := InterromperCombo()
    if (prox.item) {
        ; Revive falhou (sem posição, ou outro revive rodando): a posição
        ; fica no ITEM para o próximo aperto tentar de novo.
        if !_RotacaoRevive()
            return
    } else {
        SendEvent("^" prox.slot)
    }
    ; Pokestop do passo: sai logo depois de soltar o pokémon e antes do
    ; combo pós-troca (que só começa depois da Espera antes do combo).
    if (prox.stop) {
        teclaStop := GetTeclaPokestop()
        if (teclaStop = "N/A" || teclaStop = "")
            ShowHint("ROTAÇÃO: configure a tecla POKESTOP", 1800, "danger")
        else {
            ; Espera o jogo processar a troca antes do Pokestop: apertado
            ; logo após o Ctrl+N o jogo ignorava. Rotacao/delayPokestop no
            ; config.ini (ms) ajusta; sem tela própria.
            Sleep(Integer(CfgLer("Rotacao", "delayPokestop", "400")))
            SendEvent("{" teclaStop "}")
        }
    }
    seq := _RotacaoAvancar(alvo)
    _HudRedraw()

    ; O combo pós-troca roda num timer, não nesta thread de hotkey: com
    ; #MaxThreadsPerHotkey 2, apertos rápidos durante o combo seriam
    ; descartados. Um timer ainda rodando (suspenso por esta thread) vê a
    ; geração mudar, sai, e o timer dispara de novo com o pendente novo.
    ; 'elixir': o passo seguinte é o ITEM da mesma rotação (ex.: 1º com
    ; "1º POKÉMON = SOLTAR") — o combo deste pokémon usa o elixir antes.
    ; Pokémon de outra rotação (ex.: o 5º antes do ITEM da 3ª) não usa.
    seguinte := seq[_rotacaoPos]
    _rotacaoComboPendente := prox.combo ? { combo: prox.combo, gen: gen,
        elixir: seguinte.item && seguinte.rot = prox.rot } : 0
    if prox.combo
        SetTimer(_RodarComboRotacao, -1)
}

; Avança a partir do passo enviado (os ITEM pulados ficam para trás);
; passar do último volta ao começo e troca a vez elixir/revive. Devolve a
; sequência.
_RotacaoAvancar(alvo) {
    global _rotacaoPos, _rotacaoCiclo, _rotacaoElixirUsado
    seq := RotacaoSequencia()
    if (alvo.pos >= seq.Length)
        _rotacaoPos := 1, _rotacaoCiclo := alvo.ciclo + 1
    else
        _rotacaoPos := alvo.pos + 1, _rotacaoCiclo := alvo.ciclo
    _rotacaoElixirUsado := false
    return seq
}

; Revive do passo de ITEM: a mesma sequência do macro Revive (posição,
; hotkey e delay da tela dele — não precisa que o Revive esteja ligado).
_RotacaoRevive() {
    global _reviveOcupado
    if (_reviveOcupado)
        return false
    _reviveOcupado := true
    try {
        ok := _EnviarSequenciaRevive(GetCfg("Revive"), GetModoLegado())
    } finally {
        _reviveOcupado := false
    }
    if !ok
        ShowHint("ROTAÇÃO: defina a posição do REVIVE", 1800, "danger")
    return ok
}

; Elixir de ataque, chamado antes de um combo soltar as skills. Na vez do
; elixir, com a posição da Rotação parada no passo de ITEM (o pokémon de
; antes do ITEM está fora), envia a tecla Elixir e espera
; Rotacao/delayElixir (ms, padrão 300, só no config.ini) para o jogo
; aplicar antes da 1ª skill. Uma vez por posição: um 2º combo no mesmo
; pokémon não repete. Devolve false se o combo foi interrompido na espera.
RotacaoUsarElixir(gen) {
    global _rotacaoElixirUsado
    if !_RotacaoElixirArmado()
        return true
    tecla := CfgLer("Rotacao", "teclaElixir", "N/A")
    if (tecla = "N/A" || tecla = "") {
        ShowHint("ROTAÇÃO: configure a tecla ELIXIR", 1800, "danger")
        return true
    }
    _rotacaoElixirUsado := true
    SendEvent(_TeclaParaSend(tecla))   ; pode ter Ctrl/Alt/Shift (ex.: "^XButton2")
    return EsperarInterrompivel(_CfgInt("Rotacao", "delayElixir", 300), gen)
}

_RotacaoElixirArmado() {
    global macros, _rotacaoPos, _rotacaoElixirUsado
    if (!macros["rotacao"] || _rotacaoElixirUsado || !RotacaoVezDoElixir() || !RotacaoElixirPeloMacro())
        return false
    seq := RotacaoSequencia()
    return _rotacaoPos >= 1 && _rotacaoPos <= seq.Length && seq[_rotacaoPos].item
}

; Espera o pokémon sair (GetDelayComboRotacao) e solta o Combo 1
; (Principal) ou 2 (Secundário) com os botões configurados nele — não
; precisa que aquele combo esteja ligado na HUD.
; Conta como combo em andamento (_macroExecutando): as teclas dos combos
; Principal/Secundário são ignoradas enquanto ele roda, como em qualquer
; combo; a da Rotação (interrompível) continua valendo.
_RodarComboRotacao() {
    global _rotacaoComboPendente, COMBOS_ROTACAO, MACROS_INFO, _macroExecutando
    p := _rotacaoComboPendente
    _rotacaoComboPendente := 0
    if !p
        return
    _macroExecutando := true
    try {
        if !EsperarInterrompivel(GetDelayComboRotacao(), p.gen)
            return
        if (p.elixir && !RotacaoUsarElixir(p.gen))
            return
        secao := COMBOS_ROTACAO[p.combo]
        if !_RodarSequenciaCombo(GetCfg(secao), p.gen)
            ShowHint("ROTAÇÃO: configure os botões do " MACROS_INFO[secao].label, 1800, "danger")
    } finally {
        _macroExecutando := false
    }
}

; Volta ao início da rotação. Chamado ao ligar o macro, pela tecla de
; reiniciar e quando a config é editada.
; Põe a posição no 1º passo enviado da rotação 'rot' — para quando o
; jogador fez uma rotação à mão e o macro ficou para trás (ou à frente).
; A volta (vez do elixir/revive) não muda. false se a rotação não tem
; nenhum passo que o macro envie.
RotacaoIrPara(rot) {
    global _rotacaoPos, _rotacaoElixirUsado
    for i, e in RotacaoSequencia() {
        if (e.rot = rot) {
            _rotacaoPos := i
            _rotacaoElixirUsado := false
            _HudRedraw()
            return true
        }
    }
    return false
}

; Escolhe a vez do passo de ITEM nesta volta (true = elixir, false =
; revive) — usado junto do "COMEÇAR AQUI" quando o jogador se perdeu na
; alternância. Só a paridade da volta importa.
RotacaoDefinirVez(elixir) {
    global _rotacaoCiclo, _rotacaoElixirUsado
    _rotacaoCiclo := elixir ? 1 : 2
    _rotacaoElixirUsado := false
    _HudRedraw()
}

; A rotação 'rot' tem passo de ITEM?
RotacaoTemItemNa(rot) {
    for e in RotacaoSequencia()
        if (e.rot = rot && e.item)
            return true
    return false
}

; Volta também à 1ª volta (vez do elixir no passo de ITEM).
ReiniciarRotacao(avisar := false) {
    global _rotacaoPos, _rotacaoCiclo, _rotacaoElixirUsado
    _rotacaoPos := 1, _rotacaoCiclo := 1
    _rotacaoElixirUsado := false
    _HudRedraw()
    if (avisar && (prox := RotacaoProxima()))
        ShowHint("ROTAÇÃO REINICIADA — próximo: " (prox.item ? "REVIVE" : "Ctrl+" prox.slot), 1200, "info")
}
