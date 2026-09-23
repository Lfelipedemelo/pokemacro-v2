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
        "clickX",               _CfgInt("Cooldown", "clickX",  0),
        "clickY",               _CfgInt("Cooldown", "clickY",  0),
        "tempo1",               _CfgTempoCooldown(1),
        "tempo2",               _CfgTempoCooldown(2),
        "tempo3",               _CfgTempoCooldown(3),
        "tempo4",               _CfgTempoCooldown(4)
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

; Atalho para checar se um macro deve aparecer no mini menu.
; secao deve ser a seção exata do INI: "comboPrincipal", "comboSecundario",
; "comboRevive", "Revive" ou "Cooldown"
GetShowInMini(secao) {
    return CfgLer(secao, "showInMini", "true") = "true"
}
