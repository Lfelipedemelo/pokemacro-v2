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
; ─── Perfis ──────────────────────────────────────────
; As seções de macro (comboPrincipal, comboSecundario, Revive, comboRevive,
; Cooldown) pertencem ao perfil ativo; [Geral], [MiniMenu] e [Perfis] são
; globais. O perfil padrão usa as seções com o nome de sempre (configs
; antigas continuam valendo); os outros ficam em "<seção>@<perfil>", ex.
; [comboPrincipal@Mew]. Chamadores sempre usam o nome lógico da seção.
;
; GetCfg retorna um Map.
; Acesso correto: cfg["toggleHotkey"]  (colchetes)

global _cfgCache := Map()
global _CFG_NIL  := Chr(1)   ; marca "chave ausente no INI" dentro do cache

global PERFIL_PADRAO_NOME := "Padrão"   ; perfil padrão é salvo como "" (vazio)
global _SECOES_POR_PERFIL := ["comboPrincipal", "comboSecundario", "Revive", "comboRevive", "Cooldown"]

_SecaoEhPorPerfil(secao) {
    for s in _SECOES_POR_PERFIL
        if (s = secao)
            return true
    return false
}

PerfilAtivo() {
    return CfgLer("Geral", "perfilAtivo", "")
}

PerfilNomeExibicao(perfil := unset) {
    p := IsSet(perfil) ? perfil : PerfilAtivo()
    return (p = "") ? PERFIL_PADRAO_NOME : p
}

_SecaoReal(secao, perfil := unset) {
    if !_SecaoEhPorPerfil(secao)
        return secao
    p := IsSet(perfil) ? perfil : PerfilAtivo()
    return (p = "") ? secao : secao "@" p
}

CfgLer(secao, chave, padrao := "") {
    global configFile, _cfgCache, _CFG_NIL
    real := _SecaoReal(secao)
    k := StrLower(real "|" chave)
    if !_cfgCache.Has(k)
        _cfgCache[k] := IniRead(configFile, real, chave, _CFG_NIL)
    v := _cfgCache[k]
    return (v == _CFG_NIL) ? padrao : v
}

; Salva uma chave simples no INI
SalvarCfg(secao, chave, valor) {
    global configFile, _cfgCache
    real := _SecaoReal(secao)
    IniWrite(valor, configFile, real, chave)
    _cfgCache[StrLower(real "|" chave)] := String(valor)
}

; Remove uma seção inteira do INI (do perfil ativo, se for seção de macro)
; e re-registra as hotkeys — as teclas da seção deixam de existir.
ResetarSecao(secao) {
    global configFile, _cfgCache
    try IniDelete(configFile, _SecaoReal(secao))
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
        "tempo1",               _CfgInt("Cooldown", "tempo1",  0),
        "tempo2",               _CfgInt("Cooldown", "tempo2",  0),
        "tempo3",               _CfgInt("Cooldown", "tempo3",  0),
        "tempo4",               _CfgInt("Cooldown", "tempo4",  0)
    )
}

; Lê um inteiro tolerando valor vazio/corrompido no INI (volta ao padrão
; em vez de derrubar o macro com erro de conversão).
_CfgInt(secao, chave, padrao) {
    v := CfgLer(secao, chave, padrao)
    return IsInteger(v) ? Integer(v) : padrao
}

; Atalho para checar se um macro deve aparecer no mini menu.
; secao deve ser a seção exata do INI: "comboPrincipal", "comboSecundario",
; "comboRevive", "Revive" ou "Cooldown"
GetShowInMini(secao) {
    return CfgLer(secao, "showInMini", "true") = "true"
}

; ─── Gerenciamento de perfis ──────────────────────────
; Lista de perfis extras em [Perfis] lista=Mew|Lugia (o padrão, "", é
; sempre o primeiro e não pode ser removido).
PerfisLista() {
    lista := [""]
    raw := CfgLer("Perfis", "lista", "")
    for p in StrSplit(raw, "|")
        if (p != "")
            lista.Push(p)
    return lista
}

_PerfisSalvarLista(lista) {
    extras := ""
    for p in lista
        if (p != "")
            extras .= (extras = "" ? "" : "|") p
    SalvarCfg("Perfis", "lista", extras)
}

; Troca o perfil ativo: desliga todos os macros (as teclas/posições do
; perfil novo podem ser outras), re-registra hotkeys e atualiza a HUD.
TrocarPerfil(perfil) {
    DesligarTodosMacros(false)
    SalvarCfg("Geral", "perfilAtivo", perfil)
    AtualizarHotkeyCombo()
    _RecriarMini()
    _GCfg_Redraw()
    ShowHint("PERFIL: " PerfilNomeExibicao(perfil), 1200, "success")
}

ProximoPerfil(passo := 1) {
    lista := PerfisLista()
    if (lista.Length < 2)
        return
    atual := PerfilAtivo()
    idx := 1
    for i, p in lista
        if (p = atual)
            idx := i
    idx := Mod(idx - 1 + passo + lista.Length, lista.Length) + 1
    TrocarPerfil(lista[idx])
}

; Cria um perfil novo copiando as seções de macro do perfil ativo.
; Devolve "" em caso de sucesso ou a mensagem de erro.
CriarPerfil(nome) {
    global configFile, _cfgCache
    nome := Trim(nome)
    if !(nome ~= "^[A-Za-z0-9 _\-]{1,20}$")
        return "Use só letras, números, espaço, _ ou - (até 20)."
    for p in PerfisLista()
        if (p = nome || nome = PERFIL_PADRAO_NOME)
            return "Já existe um perfil com esse nome."

    origem := PerfilAtivo()
    for s in _SECOES_POR_PERFIL {
        try {
            conteudo := IniRead(configFile, _SecaoReal(s, origem))
            if (conteudo != "")
                IniWrite(conteudo, configFile, _SecaoReal(s, nome))
        }
    }
    _cfgCache.Clear()

    lista := PerfisLista()
    lista.Push(nome)
    _PerfisSalvarLista(lista)
    TrocarPerfil(nome)
    return ""
}

; Remove o perfil ativo (nunca o padrão) e volta para o padrão.
ExcluirPerfilAtivo() {
    global configFile, _cfgCache
    atual := PerfilAtivo()
    if (atual = "")
        return
    for s in _SECOES_POR_PERFIL
        try IniDelete(configFile, _SecaoReal(s, atual))
    _cfgCache.Clear()

    novaLista := []
    for p in PerfisLista()
        if (p != atual)
            novaLista.Push(p)
    _PerfisSalvarLista(novaLista)
    TrocarPerfil("")
}
