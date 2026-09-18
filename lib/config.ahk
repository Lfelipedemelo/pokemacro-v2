; =====================================================
; lib\config.ahk — Leitura e escrita de configurações
; =====================================================
;
; GetCfg retorna um Map.
; Acesso correto: cfg["toggleHotkey"]  (colchetes)

GetCfg(tipo) {
    global configFile

    return Map(
        ; --- Revive ---
        "delayRevive",         IniRead(configFile, tipo,      "delayRevive",      "40"),
        "x",                   IniRead(configFile, tipo,      "xRevive",          "N/A"),
        "y",                   IniRead(configFile, tipo,      "yRevive",          "N/A"),
        "teclaInputRevive",    IniRead(configFile, tipo,      "teclaInputRevive", "N/A"),
        "toggleHotkeyRevive",  IniRead(configFile, "Revive",  "toggleHotkey",     "N/A"),

        ; --- Combo ---
        "teclaInicial",  IniRead(configFile, tipo, "teclaInicial", "N/A"),
        "teclaFinal",    IniRead(configFile, tipo, "teclaFinal",   "N/A"),
        "teclaHotkey",   IniRead(configFile, tipo, "teclaHotkey",  "N/A"),
        "toggleHotkey",  IniRead(configFile, tipo, "toggleHotkey", "N/A"),
        "usarFullAtk",   IniRead(configFile, tipo, "usarFullAtk",  "false"),
        "usarFullDef",   IniRead(configFile, tipo, "usarFullDef",  "false"),

        ; --- Full Attack / Defense (teclas globais em [Geral]) ---
        "fullAttack",    IniRead(configFile, "Geral", "fullAttack",  "N/A"),
        "fullDefense",   IniRead(configFile, "Geral", "fullDefense", "N/A"),

        ; --- Combo Revive (só relevante quando tipo = "comboRevive") ---
        "delayCombo",    Integer(IniRead(configFile, tipo, "delayCombo", "500")),

        ; --- Cooldown ---
        "hotkeyCooldown",       IniRead(configFile, "Cooldown", "hotkeyCooldown",  "N/A"),
        "toggleHotkeyCooldown", IniRead(configFile, "Cooldown", "toggleHotkey",    "N/A"),
        "usarFullDefCD",        IniRead(configFile, "Cooldown", "usarFullDefCD",   "false"),
        "pokemonInicial",       Integer(IniRead(configFile, "Cooldown", "pokemonInicial", "1")),
        "clickX",               Integer(IniRead(configFile, "Cooldown", "clickX",  "0")),
        "clickY",               Integer(IniRead(configFile, "Cooldown", "clickY",  "0")),
        "tempo1",               Integer(IniRead(configFile, "Cooldown", "tempo1",  "0")),
        "tempo2",               Integer(IniRead(configFile, "Cooldown", "tempo2",  "0")),
        "tempo3",               Integer(IniRead(configFile, "Cooldown", "tempo3",  "0")),
        "tempo4",               Integer(IniRead(configFile, "Cooldown", "tempo4",  "0"))
    )
}

; Atalho para checar se um macro deve aparecer no mini menu.
; secao deve ser a seção exata do INI: "comboPrincipal", "comboSecundario",
; "comboRevive", "Revive" ou "Cooldown"
GetShowInMini(secao) {
    global configFile
    return IniRead(configFile, secao, "showInMini", "true") = "true"
}

; Salva uma chave simples no INI
SalvarCfg(secao, chave, valor) {
    global configFile
    IniWrite(valor, configFile, secao, chave)
}

; Remove uma seção inteira do INI
ResetarSecao(secao) {
    global configFile
    IniDelete(configFile, secao)
}
