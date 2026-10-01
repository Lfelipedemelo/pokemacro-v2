; =====================================================
; lib\config.ahk — Leitura e escrita de configurações
; =====================================================
;
; Todo acesso ao config.ini passa por CfgLer/SalvarCfg, que mantêm um
; cache em memória: IniRead é I/O de arquivo, e antes cada tecla de macro
; pressionada relia 100+ chaves do disco (GetCfg várias vezes por tecla)
; bem no momento em que a latência importa. Agora o disco só é lido na
; primeira vez que cada chave é pedida; escrever/resetar atualiza o cache.
;
; GetCfg retorna um Map.
; Acesso correto: cfg["toggleHotkey"]  (colchetes)

global _cfgCache := Map()
global _CFG_NIL  := Chr(1)   ; marca "chave ausente no INI" dentro do cache

global TEMPO_COOLDOWN_MAX := 60   ; segundos — faixa dos tempos de espera do Cooldown
global TECLA_POKEMON_MAX  := 6    ; pokémons do time (Ctrl+1..Ctrl+6) — faixa das teclas do Cooldown e dos passos da Rotação

CfgLer(secao, chave, padrao := "") {
    global configFile, _cfgCache, _CFG_NIL
    k := StrLower(secao "|" chave)
    if !_cfgCache.Has(k)
        _cfgCache[k] := IniRead(configFile, secao, chave, _CFG_NIL)
    v := _cfgCache[k]
    return (v == _CFG_NIL) ? padrao : v
}

; Salva uma chave simples no INI
SalvarCfg(secao, chave, valor) {
    global configFile, _cfgCache
    IniWrite(valor, configFile, secao, chave)
    _cfgCache[StrLower(secao "|" chave)] := String(valor)
}

; Remove uma seção inteira do INI e re-registra as hotkeys — as teclas
; da seção deixam de existir.
ResetarSecao(secao) {
    global configFile, _cfgCache
    try IniDelete(configFile, secao)
    _cfgCache.Clear()
    AtualizarHotkeyCombo()
}

GetCfg(tipo) {
    return Map(
        ; --- Revive ---
        "delayRevive",         CfgLer(tipo,      "delayRevive",      "50"),
        "x",                   CfgLer(tipo,      "xRevive",          "N/A"),
        "y",                   CfgLer(tipo,      "yRevive",          "N/A"),
        "teclaInputRevive",    CfgLer(tipo,      "teclaInputRevive", "N/A"),
        "toggleHotkeyRevive",  CfgLer("Revive",  "toggleHotkey",     "N/A"),

        ; --- Combo ---
        "teclaInicial",  CfgLer(tipo, "teclaInicial", "N/A"),
        "teclaFinal",    CfgLer(tipo, "teclaFinal",   "N/A"),
        "teclaHotkey",   CfgLer(tipo, "teclaHotkey",  "N/A"),
        "toggleHotkey",  CfgLer(tipo, "toggleHotkey", "N/A"),
        "usarFullAtk",   CfgLer(tipo, "usarFullAtk",  "false"),
        "usarFullDef",   CfgLer(tipo, "usarFullDef",  "false"),

        ; --- Full Attack / Defense (teclas globais em [Geral]) ---
        "fullAttack",    CfgLer("Geral", "fullAttack",  "N/A"),
        "fullDefense",   CfgLer("Geral", "fullDefense", "N/A"),

        ; --- Combo Revive (só relevante quando tipo = "comboRevive") ---
        "delayCombo",    _CfgInt(tipo, "delayCombo", 500),

        ; --- Cooldown ---
        "hotkeyCooldown",       CfgLer("Cooldown", "hotkeyCooldown",  "N/A"),
        "toggleHotkeyCooldown", CfgLer("Cooldown", "toggleHotkey",    "N/A"),
        "usarFullDefCD",        CfgLer("Cooldown", "usarFullDefCD",   "false"),
        "pokemonInicial",       _CfgInt("Cooldown", "pokemonInicial", 1),
        "tempo1",               _CfgTempoCooldown(1),
        "tempo2",               _CfgTempoCooldown(2),
        "tempo3",               _CfgTempoCooldown(3),
        "tempo4",               _CfgTempoCooldown(4),
        "tecla1",               _CfgTeclaCooldown(1),
        "tecla2",               _CfgTeclaCooldown(2),
        "tecla3",               _CfgTeclaCooldown(3),
        "tecla4",               _CfgTeclaCooldown(4)
    )
}

; Lê um inteiro tolerando valor vazio/corrompido no INI (volta ao padrão
; em vez de derrubar o macro com erro de conversão).
_CfgInt(secao, chave, padrao) {
    v := CfgLer(secao, chave, padrao)
    return IsInteger(v) ? Integer(v) : padrao
}

; Tempo de espera do Cooldown (segundos) do pokémon n, dentro da faixa do
; slider da tela de config — um valor antigo acima dela (a faixa já foi
; 0–180) passa a valer o máximo, igual ao que a tela mostra.
_CfgTempoCooldown(n) {
    return Max(0, Min(TEMPO_COOLDOWN_MAX, _CfgInt("Cooldown", "tempo" n, 0)))
}

; Tecla (Ctrl+N) enviada na posição n da sequência do Cooldown — permite
; que o usuário mapeie cada posição para o slot real do pokémon no jogo
; (ex.: ordem do time trocada, "pokémon inicial" 2 chamado com Ctrl+4).
; Padrão é n, igual ao comportamento antigo (posição = slot).
_CfgTeclaCooldown(n) {
    return Max(1, Min(TECLA_POKEMON_MAX, _CfgInt("Cooldown", "tecla" n, n)))
}

; Formato da Rotação: "2x4" (2 rotações de 4 pokémons, padrão) ou "3x3"
; (3 rotações de 3). Devolve { modo, rotacoes, passos }.
GetFormatoRotacao() {
    modo := CfgLer("Rotacao", "formato", "2x4") = "3x3" ? "3x3" : "2x4"
    return (modo = "3x3") ? { modo: "3x3", rotacoes: 3, passos: 3 } : { modo: "2x4", rotacoes: 2, passos: 4 }
}

; Pokémon (Ctrl+N) do passo 'passo' da rotação 'rot' do macro Rotação, no
; formato atual. 0 = passo vazio (pulado). Cada formato tem suas próprias
; chaves no INI ("r1p1".. no 2x4, "t1p1".. no 3x3), então trocar de
; formato não perde a configuração do outro. Padrões:
;   2x4: 1-2-3-4 | 1-2-5-6
;   3x3: 1-2-3 | 1-4-5 | 1-—-6 — na 3ª rotação o 2º passo seria repetir
;        um pokémon antes do 6º; vazio por padrão, então do 1º vai direto
;        ao 3º (o usuário põe um Ctrl+N ali se quiser a repetição).
_CfgSlotRotacao(rot, passo) {
    static padroes := Map(
        "2x4", [[1, 2, 3, 4], [1, 2, 5, 6]],
        "3x3", [[1, 2, 3], [1, 4, 5], [1, 0, 6]])
    modo := GetFormatoRotacao().modo
    return Max(0, Min(TECLA_POKEMON_MAX, _CfgInt("Rotacao", _ChaveSlotRotacao(rot, passo), padroes[modo][rot][passo])))
}

; Chave do INI do passo, no formato atual (ver _CfgSlotRotacao).
_ChaveSlotRotacao(rot, passo) {
    return ((GetFormatoRotacao().modo = "3x3") ? "t" : "r") rot "p" passo
}

; Atalho para checar se um macro deve aparecer no mini menu.
; secao deve ser a seção exata do INI: "comboPrincipal", "comboSecundario",
; "comboRevive", "Revive", "Cooldown" ou "Rotacao"
GetShowInMini(secao) {
    return CfgLer(secao, "showInMini", "true") = "true"
}
