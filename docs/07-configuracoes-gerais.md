# 7. Configurações Gerais

[⬅ Rotação](06-rotacao.md) · [README](../README.md) · Início: [Primeiros passos](01-primeiros-passos.md)

Opções **globais**, que valem para todos os macros. Para abrir: passe o mouse na HUD e clique no **⚙ geral** (o da direita, abaixo do **✕**).

<p align="center"><img src="img/hud-hover.png" width="480" alt="HUD com o ⚙ geral marcado com o número 3"></p>

<p align="center"><img src="img/config-geral.png" width="340" alt="Tela de Configurações Gerais com marcadores numerados"></p>

| # | Opção | Resumo |
|:-:|-------|--------|
| **1** | Prefixo [F] | Combos enviam `F3, F4…` ou `3, 4…` |
| **2** | Modo Legado | Revive usa clique direito em vez de `Ctrl + 1` |
| **3** | Tamanho da Interface | Pequeno / Normal / Grande (HUD e telas) |
| **4** | Ícones da HUD | Barra horizontal ou vertical |
| **5** | Tecla de Pânico | Desliga tudo de uma vez |
| **6** | Full Attack | Tecla de Full Attack usada pelos combos |
| **7** | Full Defense | Tecla de Full Defense usada pelos combos e pelo Cooldown |
| **8** | Macros exibidos na interface | Mostra/esconde cada ícone da HUD |
| **9** | Atualizações | Mostra a versão instalada; **VERIFICAR** procura uma versão nova |
| **10** | Atualizar | Só fica clicável quando há versão nova — baixa, instala e reinicia |

---

### Passo 1 — Prefixo [F]

Define como os combos enviam as teclas das habilidades:

| Opção | Botão Inicial `3`, Final `6` envia | Use quando |
|-------|-----------------------------------|-----------|
| **F1..F9** (padrão) | `F3, F4, F5, F6` | Suas habilidades estão nas teclas F |
| **1..9** | `3, 4, 5, 6` | Suas habilidades estão nos números |

### Passo 2 — Modo Legado

Muda como o [Revive](03-revive.md) e o [Combo Revive](04-combo-revive.md) recolhem/soltam o pokémon:

| Opção | Comportamento |
|-------|---------------|
| **INATIVO** (padrão) | Usa `Ctrl + 1` |
| **ATIVO** | Usa **clique direito** na posição configurada |

Deixe **INATIVO**, a menos que o revive não funcione no seu cliente do jogo.

### Passo 3 — Tamanho da Interface

`PEQUENO`, `NORMAL` ou `GRANDE`. Muda o tamanho da HUD e de todas as telas de configuração na hora.

### Passo 4 — Ícones da HUD (horizontal ou vertical)

| HORIZ. (padrão) | VERT. |
|:---:|:---:|
| <img src="img/hud-desligada.png" width="380" alt="HUD horizontal"> | <img src="img/hud-vertical.png" width="90" alt="HUD vertical"> |

### Passo 5 — Tecla de Pânico

Clique no cartão e aperte uma tecla ou combinação (ex.: `Ctrl + Q`). Com o jogo em foco, ela:

- **desliga todos os macros**;
- **interrompe** o combo ou a rotação de Cooldown que estiver rodando;
- mostra o aviso *"TODOS OS MACROS DESLIGADOS"*.

> 💡 Configure uma! É o jeito mais rápido de parar tudo se algo sair do controle.

### Passo 6 — Teclas de Full Attack e Full Defense

Clique em **FULL ATTACK** (6) e aperte a tecla de Full Attack do jogo; faça o mesmo em **FULL DEFENSE** (7).

Essas teclas são **definidas uma vez aqui** e cada macro decide se usa ou não:

| Macro | Onde ativar |
|-------|-------------|
| Combo Principal / Secundário | Pílulas **Full Attack** / **Full Defense** na [tela do combo](02-combos.md#22-configurando) |
| Combo Revive | Pílulas **Full Attack** / **Full Defense** na [tela do Combo Revive](04-combo-revive.md#42-configurando) |
| Cooldown | Pílula **Full Defense (Cooldown)** na [tela do Cooldown](05-cooldown.md#52-configurando) |

### Passo 7 — Macros exibidos na interface

Um cartão `SIM | NÃO` para cada macro. Com `NÃO`, o ícone some da HUD — útil para esconder macros que você não usa. É a mesma opção **Exibir no Mini Menu** que existe em cada tela de macro.

### Passo 8 — Atualizações

Não precisa mais baixar a pasta inteira do GitHub a cada versão nova:

1. Clique em **VERIFICAR** (9). O macro consulta o GitHub (leva um segundo ou dois) e a linha de cima do cartão mostra o resultado:
   - *"VERSÃO 2.0.0 · JÁ É A MAIS RECENTE"* — está tudo em dia;
   - *"NOVA VERSÃO 2.1.0 DISPONÍVEL!"* (em verde) — o botão **ATUALIZAR** acende.
2. Clique em **ATUALIZAR** (10). O macro baixa a versão nova, troca os arquivos e **reinicia sozinho**. Ao voltar, aparece o aviso *"Atualizado para a versão 2.1.0"*.

<p align="center"><img src="img/config-geral-atualizacao.png" width="340" alt="Cartão de atualizações com versão nova encontrada e o botão ATUALIZAR liberado"></p>

O que é mantido na atualização: suas **configurações** (`config.ini`) e o **ícone do dedo** capturado para o Revive (`revive_dedo.bmp`). Nada é verificado nem baixado sem você clicar.

Se algo der errado, a mensagem aparece em vermelho no cartão:

| Mensagem | O que fazer |
|----------|-------------|
| SEM CONEXÃO COM O GITHUB / O GITHUB DEMOROU DEMAIS | Confira a internet e clique em **VERIFICAR** de novo |
| GITHUB OCUPADO — TENTE DAQUI A POUCO | O GitHub limita consultas seguidas; espere alguns minutos |
| SEM PERMISSÃO PARA GRAVAR NA PASTA | A pasta do macro está protegida (ex.: dentro de `Arquivos de Programas`). Mova-a para `Documentos` ou rode o macro como administrador |
| ARQUIVO EM USO: … | Outro programa está com esse arquivo aberto (ex.: um editor ou visualizador de imagem). Feche-o e clique em **ATUALIZAR** de novo — nada foi alterado na pasta |
| PASTA DO GIT — USE GIT PULL | A pasta é um clone do repositório; atualize com `git pull` |

#### Log da atualização (`atualizacao.log`)

Cada vez que você clica em **VERIFICAR** ou **ATUALIZAR**, o macro anota o que fez no arquivo **`atualizacao.log`**, na pasta do macro: data e hora, versão instalada, versão do Windows, cada etapa e, se der erro, a mensagem técnica e o arquivo envolvido. Quando dá erro, um aviso na tela lembra que os detalhes foram salvos.

Se a atualização falhar, **mande esse arquivo** para quem mantém o macro: é com ele que dá para entender onde e por que falhou. Se a pasta do macro não aceitar gravação, o log vai para `%TEMP%\pokemacro_atualizacao.log`. Para abrir, digite esse caminho na barra do Explorador de Arquivos. O arquivo recomeça sozinho quando passa de 256 KB e nunca é apagado pela atualização.

---

[⬅ Rotação](06-rotacao.md) · [README](../README.md) · Início: [Primeiros passos](01-primeiros-passos.md)
