; =====================================================
; lib\atualizacao.ahk — Atualização pelo GitHub (Releases)
; =====================================================
;
; Só roda quando o usuário pede, pela tela Configurações Gerais:
;   1. "VERIFICAR" consulta a última Release do repositório e compara a
;      tag dela (ex.: v2.1.0) com VERSAO_APP (lib\globals.ahk);
;   2. se houver versão nova, o botão "ATUALIZAR" é liberado — ele baixa
;      o .zip da Release, extrai numa pasta temporária, copia tudo por
;      cima da pasta do app (menos os arquivos do usuário, ver
;      _ATUALIZ_PRESERVAR) e reinicia o script.
;
; As requisições são assíncronas (WinHttp + SetTimer), então a tela e as
; hotkeys dos macros não travam enquanto o GitHub responde. O estado fica
; em _atualiz (só em memória) e é lido pela tela a cada redesenho.
;
; Cada tentativa (verificar ou atualizar) é registrada em atualizacao.log
; na pasta do app (ou no %TEMP%, se a pasta não aceitar gravação): versão,
; Windows, cada etapa e, num erro, a mensagem técnica e o arquivo
; envolvido — é o arquivo que o usuário manda quando algo dá errado.

global ATUALIZ_REPO := "Lfelipedemelo/pokemacro-v2"

; Arquivos do usuário que nunca são sobrescritos (caminho relativo à
; pasta do app). Hoje nem vêm no .zip (estão no .gitignore), mas a lista
; protege contra alguém publicá-los por engano.
global _ATUALIZ_PRESERVAR := ["config.ini", "revive_dedo.bmp", "atualizacao.log"]

; estado: "ocioso" | "verificando" | "atual" | "disponivel" | "baixando"
;         | "instalando" | "erro"
global _atualiz := { estado: "ocioso", nova: "", zip: "", msg: "", req: 0, inicio: 0, limite: 0, aoTerminar: 0 }

AtualizacaoOcupada() {
    global _atualiz
    e := _atualiz.estado
    return (e = "verificando" || e = "baixando" || e = "instalando")
}

; Libera o botão ATUALIZAR: há versão nova conhecida e nada em andamento
; (um erro no download/instalação mantém a versão nova — dá para tentar
; de novo sem verificar outra vez).
AtualizacaoPodeInstalar() {
    global _atualiz
    e := _atualiz.estado
    return _atualiz.nova != "" && (e = "disponivel" || e = "erro")
}

; ── 1. Verificar ────────────────────────────────────────
VerificarAtualizacao(*) {
    global _atualiz
    if (AtualizacaoOcupada())
        return
    _AtualizLogInicio("VERIFICAR")
    _atualiz.nova := "", _atualiz.zip := ""
    _AtualizEstado("verificando")
    url := "https://api.github.com/repos/" ATUALIZ_REPO "/releases/latest"
    _AtualizRequisitar(url, _AtualizRespostaVerificar)
}

_AtualizRespostaVerificar(req) {
    global _atualiz
    status := req.Status
    if (status = 404) {
        _AtualizLog("Nenhuma Release publicada no repositório")
        return _AtualizEstado("atual", "NENHUMA VERSÃO PUBLICADA AINDA")
    }
    if (status = 403 || status = 429)
        return _AtualizErro("GITHUB OCUPADO — TENTE DAQUI A POUCO", "HTTP " status " (limite de consultas). Resposta: " SubStr(req.ResponseText, 1, 300))
    if (status != 200)
        return _AtualizErro("ERRO DO GITHUB (" status ")", "Resposta: " SubStr(req.ResponseText, 1, 300))

    txt := req.ResponseText
    if (!RegExMatch(txt, '"tag_name"\s*:\s*"([^"]+)"', &mTag)
     || !RegExMatch(txt, '"zipball_url"\s*:\s*"([^"]+)"', &mZip))
        return _AtualizErro("RESPOSTA INESPERADA DO GITHUB", "Sem tag_name/zipball_url. Início da resposta: " SubStr(txt, 1, 300))

    if (CompararVersao(mTag[1], VERSAO_APP) > 0) {
        _atualiz.nova := LTrim(mTag[1], "vV")
        _atualiz.zip  := mZip[1]
        _AtualizLog("Última versão: " mTag[1] " (instalada: " VERSAO_APP ") → versão nova disponível")
        _AtualizEstado("disponivel")
    } else {
        _AtualizLog("Última versão: " mTag[1] " (instalada: " VERSAO_APP ") → já está atualizado")
        _AtualizEstado("atual")
    }
}

; ── 2. Atualizar ────────────────────────────────────────
InstalarAtualizacao(*) {
    global _atualiz
    if (!AtualizacaoPodeInstalar())
        return
    _AtualizLogInicio("ATUALIZAR para " _atualiz.nova)
    ; Pasta de desenvolvimento (clone do git): sobrescrever os arquivos
    ; bagunçaria o repositório — ali o certo é "git pull".
    if (DirExist(A_ScriptDir "\.git"))
        return _AtualizErro("PASTA DO GIT — USE GIT PULL", "Existe " A_ScriptDir "\.git")
    if (!_AtualizPastaGravavel(&erroGravar))
        return _AtualizErro("SEM PERMISSÃO PARA GRAVAR NA PASTA", "Teste de escrita falhou", erroGravar)
    _AtualizLog("Pasta aceita gravação")
    _AtualizEstado("baixando")
    _AtualizRequisitar(_atualiz.zip, _AtualizRespostaDownload, 120000)
}

_AtualizRespostaDownload(req) {
    if (req.Status != 200)
        return _AtualizErro("FALHA NO DOWNLOAD (" req.Status ")", "Resposta: " SubStr(req.ResponseText, 1, 300))
    zip := _AtualizPastaTemp() ".zip"
    try {
        stream := ComObject("ADODB.Stream")
        stream.Type := 1   ; binário
        stream.Open()
        stream.Write(req.ResponseBody)
        stream.SaveToFile(zip, 2)   ; 2 = sobrescrever
        stream.Close()
    } catch as e {
        return _AtualizErro("NÃO CONSEGUI SALVAR O DOWNLOAD", "Destino: " zip, e)
    }
    _AtualizLog("Download salvo: " zip " (" Round(FileGetSize(zip) / 1024) " KB)")
    _AtualizEstado("instalando")
    ; Num timer: deixa a tela mostrar "INSTALANDO..." antes do RunWait
    ; (a extração bloqueia esta thread por alguns segundos).
    SetTimer(_AtualizExtrairECopiar.Bind(zip), -50)
}

_AtualizExtrairECopiar(zip) {
    ; Qualquer erro não previsto também vai para o log, em vez de virar
    ; a caixa de erro padrão do AutoHotkey.
    try
        _AtualizExtrairECopiarPassos(zip)
    catch as e
        _AtualizErro("ERRO INESPERADO NA INSTALAÇÃO", "", e)
}

_AtualizExtrairECopiarPassos(zip) {
    global _atualiz
    pasta := _AtualizPastaTemp()
    errPs := pasta "_erro.txt"
    try DirDelete(pasta, true)
    try FileDelete(errPs)
    try {
        DirCreate(pasta)
        z := StrReplace(zip, "'", "''"), p := StrReplace(pasta, "'", "''"), ep := StrReplace(errPs, "'", "''")
        cmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "'
             . "try { Expand-Archive -LiteralPath '" z "' -DestinationPath '" p "' -Force -ErrorAction Stop } "
             . "catch { $_ | Out-String | Out-File -LiteralPath '" ep "' -Encoding utf8; exit 1 }" '"'
        codigo := RunWait(cmd, , "Hide")
    } catch as e {
        return _AtualizErro("NÃO CONSEGUI EXTRAIR O ARQUIVO", "Não consegui rodar o PowerShell", e)
    }
    if (codigo != 0) {
        detalhe := "PowerShell saiu com código " codigo
        try detalhe .= ". Erro: " Trim(FileRead(errPs, "UTF-8"), " `t`r`n")
        return _AtualizErro("NÃO CONSEGUI EXTRAIR O ARQUIVO", detalhe)
    }
    _AtualizLog("Extraído em " pasta)

    ; O .zip do GitHub tem uma pasta única na raiz (usuario-repo-commit\).
    raiz := ""
    Loop Files pasta "\*", "D" {
        raiz := A_LoopFileFullPath
        break
    }
    if (raiz = "" || !FileExist(raiz "\pokemacro.ahk"))
        return _AtualizErro("PACOTE DA ATUALIZAÇÃO INVÁLIDO", "Pasta raiz: '" raiz "' (sem pokemacro.ahk)")

    ; Antes de copiar qualquer coisa, confere se todo arquivo que vai ser
    ; substituído pode ser gravado (nenhum aberto/travado por outro
    ; programa). Assim uma falha nunca deixa a pasta com metade dos
    ; arquivos da versão nova e metade da antiga.
    total := 0
    Loop Files raiz "\*", "FR" {
        total++
        rel := SubStr(A_LoopFileFullPath, StrLen(raiz) + 2)
        if (_AtualizPreservado(rel) || !FileExist(A_ScriptDir "\" rel))
            continue
        try FileSetAttrib("-R", A_ScriptDir "\" rel)
        try {
            f := FileOpen(A_ScriptDir "\" rel, "a")
            f.Close()
        } catch as e {
            try DirDelete(pasta, true)
            return _AtualizErro("ARQUIVO EM USO: " StrUpper(rel), "Não consegui abrir para gravação: " A_ScriptDir "\" rel, e)
        }
    }
    _AtualizLog("Checagem ok: " total " arquivos no pacote, nenhum travado")

    copiados := 0, rel := ""
    try {
        Loop Files raiz "\*", "FR" {
            rel := SubStr(A_LoopFileFullPath, StrLen(raiz) + 2)
            if (_AtualizPreservado(rel))
                continue
            destino := A_ScriptDir "\" rel
            SplitPath(destino, , &dirDestino)
            if (!DirExist(dirDestino))
                DirCreate(dirDestino)
            FileCopy(A_LoopFileFullPath, destino, true)
            copiados++
        }
    } catch as e {
        return _AtualizErro("FALHA AO COPIAR OS ARQUIVOS", "Parou em: " rel " (" copiados " já copiados)", e)
    }
    _AtualizLog("Copiados " copiados " arquivos")

    try DirDelete(pasta, true)
    try FileDelete(zip)

    ; Lido na próxima inicialização para avisar que deu certo
    ; (ver AvisarAtualizacaoConcluida).
    SalvarCfg("Geral", "atualizadoPara", _atualiz.nova)
    _AtualizLog("Reiniciando o macro...")
    Reload()
}

; Chamado na inicialização (pokemacro.ahk): se a última execução acabou
; numa atualização, mostra o aviso de sucesso uma vez só.
AvisarAtualizacaoConcluida() {
    if (CfgLer("Geral", "atualizadoPara", "") = "")
        return
    SalvarCfg("Geral", "atualizadoPara", "")
    _AtualizLog("Reiniciado na versão " VERSAO_APP " — atualização concluída")
    ShowHint("Atualizado para a versão " VERSAO_APP, 3000, "success")
}

; ── Texto de status para a tela ─────────────────────────
; Devolve { texto, tipo } — tipo: "normal" | "nova" (versão nova achada)
; | "destaque" | "erro".
AtualizacaoStatus() {
    global _atualiz
    switch _atualiz.estado {
        case "verificando": return { texto: "PROCURANDO VERSÃO NOVA...", tipo: "normal" }
        case "atual":       return { texto: _atualiz.msg != "" ? _atualiz.msg : "VERSÃO " VERSAO_APP " · JÁ É A MAIS RECENTE", tipo: "normal" }
        case "disponivel":  return { texto: "NOVA VERSÃO " _atualiz.nova " DISPONÍVEL!", tipo: "nova" }
        case "baixando":    return { texto: "BAIXANDO " _atualiz.nova "...", tipo: "destaque" }
        case "instalando":  return { texto: "INSTALANDO — O MACRO VAI REINICIAR", tipo: "destaque" }
        case "erro":        return { texto: _atualiz.msg, tipo: "erro" }
        default:            return { texto: "VERSÃO INSTALADA: " VERSAO_APP, tipo: "normal" }
    }
}

; ── Log (atualizacao.log) ───────────────────────────────

; Onde o log é gravado: na pasta do app; se ela não aceitar gravação (o
; próprio motivo de alguns erros), no %TEMP%. O caminho usado de fato é
; o que aparece no aviso de erro.
_AtualizLogArquivo() {
    static arq := ""
    if (arq != "")
        return arq
    for cand in [A_ScriptDir "\atualizacao.log", A_Temp "\pokemacro_atualizacao.log"] {
        try {
            FileAppend("", cand, "UTF-8")
            return arq := cand
        }
    }
    return arq := A_Temp "\pokemacro_atualizacao.log"
}

_AtualizLog(msg) {
    try FileAppend("[" FormatTime(, "HH:mm:ss") "] " msg "`r`n", _AtualizLogArquivo(), "UTF-8")
}

; Cabeçalho de cada tentativa, com o ambiente — o bastante para entender
; um log que chegou de outra máquina.
_AtualizLogInicio(acao) {
    arq := _AtualizLogArquivo()
    ; Não deixa crescer sem limite: passou de 256 KB, recomeça.
    try {
        if (FileGetSize(arq) > 256 * 1024)
            FileDelete(arq)
    }
    try FileAppend("`r`n==================== " FormatTime(, "yyyy-MM-dd HH:mm:ss") " — " acao " ====================`r`n", arq, "UTF-8")
    _AtualizLog("PokéMacro " VERSAO_APP " | AutoHotkey " A_AhkVersion (A_PtrSize = 8 ? " 64-bit" : " 32-bit")
        . " | Windows " A_OSVersion " | administrador: " (A_IsAdmin ? "sim" : "não"))
    _AtualizLog("Pasta do app: " A_ScriptDir)
}

; Detalhes técnicos de uma exceção do AutoHotkey (mensagem do Windows,
; código de erro, onde aconteceu).
_AtualizDescreverExcecao(e) {
    txt := Type(e) ": " e.Message
    if (e.HasProp("Extra") && e.Extra != "")
        txt .= " | extra: " e.Extra
    if (e.HasProp("Number"))
        txt .= " | código: " e.Number
    txt .= " | A_LastError: " A_LastError
    if (e.HasProp("What") && e.What != "")
        txt .= " | em: " e.What
    if (e.HasProp("Line"))
        txt .= " (linha " e.Line ")"
    return txt
}

; ── Utilitários ─────────────────────────────────────────

; Compara "v2.1.0" com "2.0.3" etc. Devolve 1 (a > b), 0 ou -1. Partes
; que faltam contam como 0; sufixos ("-beta") são ignorados.
CompararVersao(a, b) {
    pa := StrSplit(LTrim(a, "vV"), "."), pb := StrSplit(LTrim(b, "vV"), ".")
    Loop Max(pa.Length, pb.Length) {
        na := (A_Index <= pa.Length && RegExMatch(pa[A_Index], "^\d+", &m)) ? Integer(m[0]) : 0
        nb := (A_Index <= pb.Length && RegExMatch(pb[A_Index], "^\d+", &m)) ? Integer(m[0]) : 0
        if (na != nb)
            return na > nb ? 1 : -1
    }
    return 0
}

_AtualizEstado(estado, msg := "") {
    global _atualiz
    _atualiz.estado := estado
    _atualiz.msg := msg
    _GCfg_Redraw()
}

; msg: texto curto do cartão. detalhe/e (exceção): só vão para o log.
_AtualizErro(msg, detalhe := "", e := 0) {
    _AtualizLog("ERRO: " msg)
    if (detalhe != "")
        _AtualizLog("  detalhe: " detalhe)
    if (IsObject(e))
        _AtualizLog("  exceção: " _AtualizDescreverExcecao(e))
    _AtualizEstado("erro", msg)
    SplitPath(_AtualizLogArquivo(), &nomeLog)
    ShowHint("Erro na atualização — detalhes salvos em " nomeLog, 3500, "danger")
}

_AtualizPastaTemp() {
    return A_Temp "\pokemacro_atualizacao"
}

_AtualizPreservado(rel) {
    for p in _ATUALIZ_PRESERVAR
        if (rel = p)   ; comparação sem diferenciar maiúsculas
            return true
    return false
}

_AtualizPastaGravavel(&erro := 0) {
    teste := A_ScriptDir "\.teste_escrita.tmp"
    try {
        FileAppend("", teste)
        FileDelete(teste)
        return true
    } catch as e {
        erro := e
    }
    return false
}

; GET assíncrono: chama aoTerminar(req) quando a resposta chegar; erro de
; rede ou demora acima de 'limite' ms viram estado "erro".
_AtualizRequisitar(url, aoTerminar, limite := 15000) {
    global _atualiz
    _AtualizLog("GET " url)
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", url, true)
        req.SetRequestHeader("User-Agent", "PokeMacro/" VERSAO_APP)
        req.SetRequestHeader("Accept", "application/vnd.github+json")
        req.Send()
    } catch as e {
        return _AtualizErro("SEM CONEXÃO COM O GITHUB", "Falha ao enviar a requisição", e)
    }
    _atualiz.req := req
    _atualiz.aoTerminar := aoTerminar
    _atualiz.inicio := A_TickCount
    _atualiz.limite := limite
    SetTimer(_AtualizAguardar, 100)
}

_AtualizAguardar() {
    global _atualiz
    req := _atualiz.req
    try {
        pronto := req.WaitForResponse(0)
    } catch as e {
        SetTimer(_AtualizAguardar, 0)
        _atualiz.req := 0
        return _AtualizErro("SEM CONEXÃO COM O GITHUB", "Falha ao receber a resposta", e)
    }
    if (!pronto) {
        if (A_TickCount - _atualiz.inicio > _atualiz.limite) {
            SetTimer(_AtualizAguardar, 0)
            try req.Abort()
            _atualiz.req := 0
            _AtualizErro("O GITHUB DEMOROU DEMAIS", "Sem resposta em " _atualiz.limite " ms")
        }
        return
    }
    SetTimer(_AtualizAguardar, 0)
    _atualiz.req := 0
    _AtualizLog("Resposta HTTP " req.Status " em " (A_TickCount - _atualiz.inicio) " ms")
    fn := _atualiz.aoTerminar
    try
        fn.Call(req)
    catch as e
        _AtualizErro("ERRO INESPERADO NA ATUALIZAÇÃO", "", e)
}
