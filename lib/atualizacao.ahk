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

global ATUALIZ_REPO := "Lfelipedemelo/pokemacro-v2"

; Arquivos do usuário que nunca são sobrescritos (caminho relativo à
; pasta do app). Hoje nem vêm no .zip (estão no .gitignore), mas a lista
; protege contra alguém publicá-los por engano.
global _ATUALIZ_PRESERVAR := ["config.ini", "revive_dedo.bmp"]

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
    _atualiz.nova := "", _atualiz.zip := ""
    _AtualizEstado("verificando")
    url := "https://api.github.com/repos/" ATUALIZ_REPO "/releases/latest"
    _AtualizRequisitar(url, _AtualizRespostaVerificar)
}

_AtualizRespostaVerificar(req) {
    global _atualiz
    status := req.Status
    if (status = 404)
        return _AtualizEstado("atual", "NENHUMA VERSÃO PUBLICADA AINDA")
    if (status = 403 || status = 429)
        return _AtualizErro("GITHUB OCUPADO — TENTE DAQUI A POUCO")
    if (status != 200)
        return _AtualizErro("ERRO DO GITHUB (" status ")")

    txt := req.ResponseText
    if (!RegExMatch(txt, '"tag_name"\s*:\s*"([^"]+)"', &mTag)
     || !RegExMatch(txt, '"zipball_url"\s*:\s*"([^"]+)"', &mZip))
        return _AtualizErro("RESPOSTA INESPERADA DO GITHUB")

    if (CompararVersao(mTag[1], VERSAO_APP) > 0) {
        _atualiz.nova := LTrim(mTag[1], "vV")
        _atualiz.zip  := mZip[1]
        _AtualizEstado("disponivel")
    } else {
        _AtualizEstado("atual")
    }
}

; ── 2. Atualizar ────────────────────────────────────────
InstalarAtualizacao(*) {
    global _atualiz
    if (!AtualizacaoPodeInstalar())
        return
    ; Pasta de desenvolvimento (clone do git): sobrescrever os arquivos
    ; bagunçaria o repositório — ali o certo é "git pull".
    if (DirExist(A_ScriptDir "\.git"))
        return _AtualizErro("PASTA DO GIT — USE GIT PULL")
    if (!_AtualizPastaGravavel())
        return _AtualizErro("SEM PERMISSÃO PARA GRAVAR NA PASTA")
    _AtualizEstado("baixando")
    _AtualizRequisitar(_atualiz.zip, _AtualizRespostaDownload, 120000)
}

_AtualizRespostaDownload(req) {
    if (req.Status != 200)
        return _AtualizErro("FALHA NO DOWNLOAD (" req.Status ")")
    zip := _AtualizPastaTemp() ".zip"
    try {
        stream := ComObject("ADODB.Stream")
        stream.Type := 1   ; binário
        stream.Open()
        stream.Write(req.ResponseBody)
        stream.SaveToFile(zip, 2)   ; 2 = sobrescrever
        stream.Close()
    } catch {
        return _AtualizErro("NÃO CONSEGUI SALVAR O DOWNLOAD")
    }
    _AtualizEstado("instalando")
    ; Num timer: deixa a tela mostrar "INSTALANDO..." antes do RunWait
    ; (a extração bloqueia esta thread por alguns segundos).
    SetTimer(_AtualizExtrairECopiar.Bind(zip), -50)
}

_AtualizExtrairECopiar(zip) {
    global _atualiz
    pasta := _AtualizPastaTemp()
    try DirDelete(pasta, true)
    try {
        DirCreate(pasta)
        z := StrReplace(zip, "'", "''"), p := StrReplace(pasta, "'", "''")
        cmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "'
             . "Expand-Archive -LiteralPath '" z "' -DestinationPath '" p "' -Force" '"'
        RunWait(cmd, , "Hide")
    } catch {
        return _AtualizErro("NÃO CONSEGUI EXTRAIR O ARQUIVO")
    }

    ; O .zip do GitHub tem uma pasta única na raiz (usuario-repo-commit\).
    raiz := ""
    Loop Files pasta "\*", "D" {
        raiz := A_LoopFileFullPath
        break
    }
    if (raiz = "" || !FileExist(raiz "\pokemacro.ahk"))
        return _AtualizErro("PACOTE DA ATUALIZAÇÃO INVÁLIDO")

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
        }
    } catch {
        return _AtualizErro("FALHA AO COPIAR OS ARQUIVOS")
    }

    try DirDelete(pasta, true)
    try FileDelete(zip)

    ; Lido na próxima inicialização para avisar que deu certo
    ; (ver AvisarAtualizacaoConcluida).
    SalvarCfg("Geral", "atualizadoPara", _atualiz.nova)
    Reload()
}

; Chamado na inicialização (pokemacro.ahk): se a última execução acabou
; numa atualização, mostra o aviso de sucesso uma vez só.
AvisarAtualizacaoConcluida() {
    if (CfgLer("Geral", "atualizadoPara", "") = "")
        return
    SalvarCfg("Geral", "atualizadoPara", "")
    ShowHint("Atualizado para a versão " VERSAO_APP, 3000, "success")
}

; ── Texto de status para a tela ─────────────────────────
; Devolve { texto, tipo } — tipo: "normal" | "destaque" | "erro".
AtualizacaoStatus() {
    global _atualiz
    switch _atualiz.estado {
        case "verificando": return { texto: "PROCURANDO VERSÃO NOVA...", tipo: "normal" }
        case "atual":       return { texto: _atualiz.msg != "" ? _atualiz.msg : "VERSÃO " VERSAO_APP " · JÁ É A MAIS RECENTE", tipo: "normal" }
        case "disponivel":  return { texto: "NOVA VERSÃO " _atualiz.nova " DISPONÍVEL!", tipo: "destaque" }
        case "baixando":    return { texto: "BAIXANDO " _atualiz.nova "...", tipo: "destaque" }
        case "instalando":  return { texto: "INSTALANDO — O MACRO VAI REINICIAR", tipo: "destaque" }
        case "erro":        return { texto: _atualiz.msg, tipo: "erro" }
        default:            return { texto: "VERSÃO INSTALADA: " VERSAO_APP, tipo: "normal" }
    }
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

_AtualizErro(msg) {
    _AtualizEstado("erro", msg)
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

_AtualizPastaGravavel() {
    teste := A_ScriptDir "\.teste_escrita.tmp"
    try {
        FileAppend("", teste)
        FileDelete(teste)
        return true
    }
    return false
}

; GET assíncrono: chama aoTerminar(req) quando a resposta chegar; erro de
; rede ou demora acima de 'limite' ms viram estado "erro".
_AtualizRequisitar(url, aoTerminar, limite := 15000) {
    global _atualiz
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", url, true)
        req.SetRequestHeader("User-Agent", "PokeMacro/" VERSAO_APP)
        req.SetRequestHeader("Accept", "application/vnd.github+json")
        req.Send()
    } catch {
        return _AtualizErro("SEM CONEXÃO COM O GITHUB")
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
    } catch {
        SetTimer(_AtualizAguardar, 0)
        _atualiz.req := 0
        return _AtualizErro("SEM CONEXÃO COM O GITHUB")
    }
    if (!pronto) {
        if (A_TickCount - _atualiz.inicio > _atualiz.limite) {
            SetTimer(_AtualizAguardar, 0)
            try req.Abort()
            _atualiz.req := 0
            _AtualizErro("O GITHUB DEMOROU DEMAIS")
        }
        return
    }
    SetTimer(_AtualizAguardar, 0)
    _atualiz.req := 0
    fn := _atualiz.aoTerminar
    fn.Call(req)
}
