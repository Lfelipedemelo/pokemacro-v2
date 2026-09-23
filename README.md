# 🎮 PokéMacro — Documentação Completa

> Sistema de macros para jogos Pokémon MMO, desenvolvido em **AutoHotkey v2.0**.  
> Interface visual com tema Pokémon, totalmente configurável sem editar código.

---

> ### ✅ Uso Autorizado pela Equipe PXG
>
> O uso de macros no **PokéXGames** foi oficialmente autorizado pela equipe do jogo.  
> Confira o comunicado oficial no fórum:  
> 🔗 [Mass Ban por uso Ilegal de Software — Posicionamento Oficial da Equipe PXG](https://forum.pokexgames.com/threads/248931-Mass-Ban-por-uso-Ilegal-de-Software?p=4586067)

---

> ### ⚠️ Disclaimer
>
> Este projeto foi desenvolvido com o auxílio do **Claude AI** (Anthropic).  
> O código, a arquitetura modular, a interface gráfica e esta documentação foram criados em colaboração entre o desenvolvedor e a IA.  
> O uso é de responsabilidade exclusiva do usuário. Verifique sempre as regras do servidor/jogo antes de utilizar macros.

---

## 📋 Índice

1. [Requisitos](#requisitos)
2. [Instalação](#instalação)
3. [Estrutura de Pastas](#estrutura-de-pastas)
4. [Como Usar](#como-usar)
5. [Interface Principal](#interface-principal)
6. [Macros Disponíveis](#macros-disponíveis)
   - [Combo Principal](#combo-principal)
   - [Combo Secundário](#combo-secundário)
   - [Revive](#revive)
   - [Combo Revive](#combo-revive)
   - [Cooldown](#cooldown)
7. [Configurações Gerais](#configurações-gerais)
8. [Sistema de Hotkeys](#sistema-de-hotkeys)
9. [Perguntas Frequentes](#perguntas-frequentes)
10. [Iniciar Automaticamente com o Windows](#-iniciar-automaticamente-com-o-windows)

---

## Requisitos

| Requisito | Versão mínima |
|-----------|--------------|
| AutoHotkey | **v2.0** (não funciona com v1.x) |
| Windows | 7 / 10 / 11 |

> ⚠️ **Importante:** Certifique-se de instalar o AutoHotkey **v2.0** e não v1.1.  
> Download oficial: https://www.autohotkey.com/

---

## Instalação

1. Baixe ou clone este repositório para uma pasta de sua escolha.
2. Certifique-se de que a pasta `icons\` existe e contém os arquivos `.png` dos macros.
3. Dê um duplo clique em **`pokemacro.ahk`** para iniciar o sistema.
4. A interface aparecerá na tela. Se não aparecer, pressione **Ctrl+F12**.

> O arquivo `config.ini` é criado automaticamente na primeira vez que você salva qualquer configuração. Não é necessário criá-lo manualmente.

---

## Estrutura de Pastas

```
macro_modular/
│
├── pokemacro.ahk                ← Ponto de entrada — execute este arquivo
├── config.ini                   ← Gerado automaticamente com suas configurações
│
├── icons\                       ← Ícones PNG exibidos na interface
│   ├── combo_principal.png
│   ├── combo_secundario.png
│   ├── revive.png
│   ├── combo_revive.png
│   └── cooldown.png
│
├── lib\                         ← Utilitários internos (não edite)
│   ├── globals.ahk              ← Estado global, mapa de macros e tema de cores
│   ├── config.ahk               ← Leitura/escrita do config.ini (com cache)
│   ├── gdip.ahk                 ← Wrapper GDI+ usado para desenhar a HUD
│   ├── hint.ahk                 ← Notificações flutuantes na tela
│   ├── window.ahk               ← Helpers de janela, detecção do jogo e checagem de admin
│   └── input.ahk                ← Captura de teclas e posição do mouse
│
├── ui\                          ← Telas da interface gráfica
│   ├── mini_menu.ahk            ← HUD flutuante — interface principal (Ctrl+F12)
│   ├── config_combo.ahk         ← Tela de configuração dos Combos
│   ├── config_revive.ahk        ← Tela de configuração do Revive
│   ├── config_combo_revive.ahk  ← Tela de configuração do Combo Revive
│   ├── config_cooldown.ahk      ← Tela de configuração do Cooldown
│   └── config_geral.ahk         ← Configurações globais do sistema
│
└── macros\                      ← Lógica de execução dos macros
    ├── hotkeys.ahk              ← Estado dos macros, registro e despacho de hotkeys
    ├── combo.ahk                ← Lógica do Combo Principal/Secundário
    ├── revive.ahk               ← Lógica do Revive
    ├── combo_revive.ahk         ← Lógica do Combo Revive
    └── cooldown.ahk             ← Lógica do Cooldown Progressivo
```

---

## Como Usar

### Abrindo e fechando a interface

- Pressione **Ctrl+F12** para abrir ou fechar a HUD flutuante.
- Você também pode fechar clicando no botão **✕** dentro da própria barra.
- A HUD pode ser **arrastada** para qualquer posição da tela. A posição é salva automaticamente.

### Ativando um macro

1. Clique no **ícone** do macro desejado na barra da HUD.
2. O ícone ganha um anel/brilho na cor de destaque do tema quando ativo.
3. Clique novamente para **desativar**.

> 💡 **Exclusividade entre Combos:** Combo Principal, Combo Secundário e Combo Revive são mutuamente exclusivos — ativar um desliga automaticamente os outros.

> 💡 **Dica de tecla:** Passe o mouse sobre um ícone da barra para ver em um tooltip o nome do macro e a tecla configurada para ele.

### Configurando um macro

1. Passe o mouse sobre a barra da HUD — aparece um botão **⚙** abaixo de cada ícone (ou ao lado, com a barra na vertical).
2. Clique no **⚙** do macro desejado.
3. A tela de configuração será aberta.
4. Configure cada opção conforme descrito nas seções abaixo.
5. Feche com o botão **X** — as configurações são salvas automaticamente.

---

## Interface Principal

A interface é uma **HUD flutuante compacta**, desenhada com GDI+ (cantos arredondados, hover animado e transições suaves). Normalmente ela mostra só os ícones dos macros; com o mouse sobre a barra aparecem os botões de configuração.

```
┌──────────────────────┐
│ (◉)(◉)(◉)(◉)(◉) │ ✕  │  ← ícones dos macros | fechar
│  ⚙  ⚙  ⚙  ⚙  ⚙  │ ⚙  │  ← config de cada macro | config geral (só no hover)
└──────────────────────┘
```

Com os ícones na vertical (Configurações Gerais → ÍCONES DA HUD), vira uma coluna de ícones (com o ✕ no fim) e, à direita dela, uma coluna de ⚙ (com o ⚙ geral ao lado do ✕).

| Elemento | Função |
|----------|--------|
| Ícone do macro | Ativa/desativa o macro. Hover mostra tooltip com o nome |
| ⚙ do macro (abaixo/ao lado do ícone) | Abre a tela de configuração daquele macro. Fica apagado e acende com o mouse sobre o ícone ou o próprio ⚙ |
| ⚙ geral | Abre as Configurações Gerais |
| ✕ | Fecha a HUD |

---

## Macros Disponíveis

---

### Combo Principal

**O que faz:** Pressiona automaticamente uma sequência de teclas de habilidade (ex: F3 até F8), com um intervalo configurável entre cada uma. Opcionalmente envia Full Attack antes e Full Defense depois.

**Como funciona:**
1. Ao pressionar a **Tecla do Macro**, o sistema envia as teclas da sequência uma por uma.
2. Cada tecla fica configurável entre usar prefixo `F` (ex: `F3`) ou só o número (ex: `3`) — veja [Configurações Gerais](#configurações-gerais).
3. Pressionar a **Tecla do Macro** novamente enquanto executa **interrompe** o combo.

#### Opções de Configuração

| Campo | O que configura |
|-------|----------------|
| **Botão Inicial** | Número da primeira tecla da sequência (ex: `F3` → número `3`) |
| **Botão Final** | Número da última tecla da sequência (ex: `F8` → número `8`) |
| **Tecla do Macro** | Tecla ou botão do mouse que dispara o combo |
| **Full Attack** | Ativa/desativa o envio da tecla de Full Attack (global) antes do combo |
| **Full Defense** | Ativa/desativa o envio da tecla de Full Defense (global) após o combo |
| **Delay Entre Teclas (ms)** | Intervalo entre cada tecla do combo — valor **compartilhado por todos os combos** (veja abaixo) |
| **Hotkey Ligar/Desligar** | Tecla para ativar/desativar o macro sem abrir a interface |

**Como configurar passo a passo:**

1. Abra a configuração do Combo Principal (passe o mouse na HUD e clique no ⚙ do ícone do Combo Principal).
2. Clique em **▶ DEFINIR BOTÃO INICIAL** e pressione a tecla da sua primeira habilidade.
3. Clique em **▶ DEFINIR BOTÃO FINAL** e pressione a tecla da sua última habilidade.
4. Clique em **▶ DEFINIR TECLA MACRO** e pressione a tecla/botão que vai disparar o combo.
5. Se quiser Full Attack/Defense, vá em [Configurações Gerais](#configurações-gerais) e defina as teclas globais, depois ative-as aqui com o radio **ATIVAR**.
6. Feche a configuração.
7. Na barra da HUD, clique no ícone do **Combo Principal** para ativá-lo.
8. No jogo, pressione a tecla configurada — o combo será executado automaticamente.

> **Exemplo:** Habilidades de F3 a F8.  
> Botão Inicial: `3` → Botão Final: `8` → com prefixo F ativo, o macro envia F3, F4, F5, F6, F7, F8 em sequência.

#### Delay Entre Teclas (ms)

Controla o **intervalo em milissegundos** entre cada tecla enviada no combo. Aparece nas telas do **Combo Principal**, **Combo Secundário** e **Combo Revive**, mas é **um valor só**: mexer em uma tela altera para todos os combos (e resetar um combo não apaga esse valor).

- **Valor menor** = combo mais rápido (ex: 400ms)
- **Valor maior** = combo mais lento, mais seguro (ex: 700ms)
- **Padrão:** 550ms (ajustável de 300 a 800ms)
- O intervalo real entre as teclas é o valor configurado (com ~10ms de margem).

> Ajuste conforme a latência do servidor. Em servidores com alta latência, aumente o delay para evitar que habilidades sejam perdidas.

---

### Combo Secundário

Funciona exatamente igual ao **Combo Principal**, mas é uma configuração separada e independente.

> Útil para ter dois sets de habilidades diferentes e alternar entre eles rapidamente.

---

### Revive

**O que faz:** Move o mouse até uma posição configurada na tela, executa a ação de revive (clique direito ou Ctrl+1 dependendo do modo), e retorna o mouse à posição original.

**Como funciona:**
1. Ao pressionar a **Tecla do Macro**, o mouse se move instantaneamente para a posição do Pokémon a ser revivido.
2. Executa o comando de revive conforme o **Modo Legado** configurado.
3. Aguarda o **Delay** configurado.
4. Pressiona a tecla de confirmação (Hotkey Revive).
5. Repete o comando de revive para confirmar.
6. O mouse retorna à posição original.

> 💡 **Interrupção de Combo:** Ao pressionar a tecla do Revive durante a execução de um Combo, o combo é interrompido imediatamente e o revive é executado.

#### Opções de Configuração

| Campo | O que configura |
|-------|----------------|
| **Posição do Clique** | Coordenadas X,Y na tela onde está o Pokémon a reviver |
| **Hotkey Revive** | Tecla de confirmação pressionada durante o revive |
| **Tecla do Macro** | Tecla ou botão que dispara o revive |
| **Delay entre Cliques (ms)** | Tempo em milissegundos entre o primeiro e segundo comando |
| **Hotkey Ligar/Desligar** | Tecla para ativar/desativar o macro |

**Como configurar passo a passo:**

1. Abra a configuração do Revive (passe o mouse na HUD e clique no ⚙ do ícone do Reviver).
2. Clique em **▶ DEFINIR POSIÇÃO** e depois clique com o botão esquerdo do mouse **sobre o Pokémon** que você quer reviver no jogo.
3. Clique em **▶ DEFINIR HOTKEY** e pressione a tecla que você usa para confirmar/usar o item de revive.
4. Clique em **▶ DEFINIR TECLA MACRO** e pressione a tecla/botão que vai disparar o macro.
5. Ajuste o **Delay** se necessário (padrão: 40ms).
6. Feche e ative o macro na barra da HUD.

> **Dica:** Use um botão extra do mouse (XButton1 ou XButton2) como Tecla do Macro para maior praticidade.

---

### Combo Revive

**O que faz:** Macro combinado que executa o **Revive** e em seguida executa um **Combo** de habilidades. Ideal para situações onde você precisa reviver um Pokémon e imediatamente entrar em combate.

**Como funciona:**
1. Ao pressionar a **Tecla do Macro**, executa o revive completo (usando as configurações da tela de Revive).
2. Aguarda o **Delay Após Revive** configurado.
3. Executa o combo de habilidades configurado nesta tela.

> ⚠️ **Importante:** O Combo Revive usa automaticamente a posição, delay e hotkey configurados na tela do **Revive**. Configure o Revive primeiro.

#### Opções de Configuração

| Campo | O que configura |
|-------|----------------|
| **Botão Inicial** | Primeira tecla do combo após o revive |
| **Botão Final** | Última tecla do combo após o revive |
| **Tecla do Macro** | Tecla que dispara o Combo Revive completo |
| **Full Attack** | Ativa/desativa Full Attack antes do combo |
| **Full Defense** | Ativa/desativa Full Defense após o combo |
| **Delay Após Revive (ms)** | Tempo de espera entre o fim do revive e o início do combo |
| **Delay Entre Teclas (ms)** | Intervalo entre as teclas do combo — compartilhado com os outros combos |
| **Hotkey Ligar/Desligar** | Tecla para ativar/desativar o macro |

> **Delay recomendado:** 500ms a 1500ms dependendo da velocidade do servidor.

---

### Cooldown

**O que faz:** Macro de rotação progressiva que clica em uma posição da tela e pressiona `Ctrl+N` para cada Pokémon (do configurado até o 1), aguardando um tempo específico entre cada um.

**Como funciona:**
1. Ao pressionar a **Hotkey Cooldown**, o macro inicia.
2. Opcionalmente envia a tecla de **Full Defense** antes de começar.
3. Para cada Pokémon (do inicial até o 1):
   - Move o mouse para a posição configurada e clica.
   - Pressiona `Ctrl+N` (onde N é o número do Pokémon).
   - Aguarda o tempo configurado para aquele Pokémon.
4. Pressionar a **Hotkey Cooldown** novamente durante a execução **cancela** o macro imediatamente.

#### Opções de Configuração

| Campo | O que configura |
|-------|----------------|
| **Hotkey Cooldown** | Tecla que inicia/cancela o macro |
| **Posição do Clique** | Coordenadas onde o mouse clica antes de cada `Ctrl+N` |
| **Pokémon Inicial** | De qual Pokémon (1-4) começa a rotação |
| **Tempos de Espera** | Tempo em segundos (0 a 60) para cada slot (PKM 1, PKM 2, PKM 3, PKM 4). Ajuste arrastando a barra ou clicando no valor para digitar (Enter salva, Esc cancela) |
| **Full Defense** | Ativa/desativa o envio de Full Defense ao iniciar |
| **Hotkey Ligar/Desligar** | Tecla para ativar/desativar o macro |

> **Exemplo:** Pokémon Inicial = 3, tempos PKM3 = 10s, PKM2 = 8s, PKM1 = 6s.  
> O macro vai: clicar → Ctrl+3 → 10s → clicar → Ctrl+2 → 8s → clicar → Ctrl+1 → 6s → fim.

---

## Configurações Gerais

Acessado pelo botão **⚙** na barra da HUD (ao lado do ✕, visível com o mouse sobre a barra).  
Estas configurações são **globais** — afetam todos os macros do sistema.

---

### 1. Usar Prefixo [F] nas Teclas

Define como as teclas do combo são enviadas ao jogo.

| Opção | Teclas enviadas | Quando usar |
|-------|----------------|-------------|
| **SIM (F1..F9)** | `F1`, `F2`, `F3`... | Quando as habilidades estão mapeadas nas teclas F |
| **NÃO (1..9)** | `1`, `2`, `3`... | Quando as habilidades estão mapeadas nos números |

> **Exemplo:** Botão Inicial `3`, Botão Final `6`:  
> - Com prefixo F: envia `F3`, `F4`, `F5`, `F6`  
> - Sem prefixo F: envia `3`, `4`, `5`, `6`

---

### 2. Modo Legado (Revive)

Altera o comportamento dos macros de **Revive** e **Combo Revive**.

| Modo | Comportamento | Quando usar |
|------|--------------|-------------|
| **INATIVO** (padrão) | Usa `Ctrl+1` para selecionar o slot | Versões mais recentes do jogo |
| **ATIVO** | Usa clique direito do mouse no alvo | Versões mais antigas do jogo |

---

### 3. Tecla Full Attack (Global)

Define a tecla enviada **antes** de iniciar qualquer combo (quando Full Attack está ativado na configuração do combo).

- Compartilhada entre Combo Principal, Combo Secundário e Combo Revive.
- Cada combo tem seu próprio interruptor ATIVAR/DESATIVAR nas configurações individuais.

---

### 4. Tecla Full Defense (Global)

Define a tecla enviada **após** o término de qualquer combo ou ao iniciar o Cooldown (quando Full Defense está ativado).

- Compartilhada entre todos os macros que suportam Full Defense.

---

### 5. Tecla de Pânico

Uma tecla que **desliga todos os macros de uma vez** e interrompe o que estiver rodando (combo, cooldown). Só funciona com o jogo em foco.

---

## Sistema de Hotkeys

### Tipos de hotkey

O sistema possui dois tipos distintos de hotkey para cada macro:

| Tipo | Função | Restrição |
|------|--------|-----------|
| **Tecla do Macro** | Executa o macro quando pressionada | Só funciona com o jogo em foco e macro ativado |
| **Hotkey Ligar/Desligar** | Ativa ou desativa o macro | Só funciona com o jogo em foco |

> ⚠️ **Todas as hotkeys** — tanto de execução quanto de ligar/desligar — **só funcionam quando o jogo está em foco**. Isso evita acionamentos acidentais ao usar outras janelas.

### Teclas suportadas

Ao pressionar **▶ DEFINIR** em qualquer campo de tecla, o sistema aguarda você pressionar:

- Qualquer tecla do teclado (letras, números, F1-F12, etc.)
- Botões extras do mouse: **XButton1**, **XButton2**, **MButton**

> ⚠️ **LButton** e **RButton** são recusados na captura — virariam hotkey e o clique normal deixaria de chegar ao jogo.

### Prevenção de conflitos

O sistema possui proteção avançada contra conflito de hotkeys:

- **Tecla já usada:** ao definir uma hotkey (tecla do macro, ligar/desligar ou pânico) que já pertence a outra, o sistema avisa e não salva. A única exceção é a tecla do macro dos três combos, que pode ser a mesma (só um combo fica ligado por vez).
- **Mesma tecla no macro e no jogo:** Se a Tecla do Macro for a mesma que uma ação do jogo (ex: `F3` é hotkey e primeira habilidade do combo), o sistema usa supressão de input — a tecla não é enviada ao jogo duas vezes.
- **Re-entrada bloqueada:** Enquanto um combo está em execução, novas execuções do mesmo combo são bloqueadas.
- **Revive interrompe Combo:** Pressionar a tecla do Revive ou Combo Revive durante a execução de um combo **interrompe o combo imediatamente** e executa o revive.
- **Cancelamento do Cooldown:** Pressionar a hotkey do Cooldown durante a execução cancela o macro imediatamente.

### Botão Reset (↺)

Cada tela de configuração possui um botão **↺** vermelho no canto superior direito.  
Ao confirmar, **apaga todas as configurações** daquele macro e retorna tudo para `N/A`.

> Use com cuidado — esta ação não pode ser desfeita.

---

## Perguntas Frequentes

**O macro não está funcionando. O que verificar?**

1. Verifique se o macro está **ativado** (ícone com anel/brilho de destaque na barra da HUD).
2. Verifique se a janela do jogo está em **foco** (em primeiro plano).
3. Verifique se a **Tecla do Macro** está configurada (não deve estar como `N/A`).
4. Verifique se o processo do jogo é `pxgme.exe` — o sistema monitora especificamente este processo.
5. Se o jogo roda **como administrador**, o macro também precisa rodar assim (o Windows bloqueia as teclas enviadas por um programa sem privilégio). O macro detecta isso sozinho e oferece reiniciar como administrador.

---

**As teclas do combo não estão chegando no jogo.**

- Tente aumentar o **Delay Entre Teclas** na configuração de qualquer combo (vale para todos).
- Verifique se a opção **Prefixo [F]** está correta para o seu jogo.

---

**O revive não está funcionando corretamente.**

- Verifique se a **Posição do Clique** está correta (clique exatamente sobre o Pokémon).
- Aumente o **Delay entre Cliques** na configuração do Revive.
- Tente alternar o **Modo Legado** nas Configurações Gerais.

---

**O Combo Revive executa o revive mas não executa o combo.**

- Aumente o **Delay Após Revive** na configuração do Combo Revive (tente 1000ms ou mais).
- Verifique se o **Botão Inicial** e **Botão Final** estão configurados.

---

**A interface sumiu da tela.**

- Pressione **Ctrl+F12** para reabrir.
- Se a posição foi salva fora da tela (monitor desconectado), delete a seção `[MiniMenu]` do arquivo `config.ini` com um editor de texto.

---

**Posso usar o sistema em outro jogo?**

O sistema está configurado para detectar a janela `pxgme.exe`. Para usar em outro jogo, edite a linha no arquivo `macros\hotkeys.ahk`:
```autohotkey
JanelaAtiva() => WinActive("ahk_exe pxgme.exe")
```
Substitua `pxgme.exe` pelo nome do executável do seu jogo.

---

*Documentação gerada para PokéMacro v1.0 — AutoHotkey v2.0*

---

## 🚀 Iniciar Automaticamente com o Windows

Para que o PokéMacro abra automaticamente toda vez que o computador ligar, siga um dos métodos abaixo:

---

### Método 1 — Pasta de Inicialização (Recomendado)

Este é o método mais simples e não requer permissões de administrador.

1. Pressione **Win + R** para abrir o menu Executar.
2. Digite `shell:startup` e pressione **Enter**.
3. Uma pasta do Windows Explorer será aberta — esta é a **pasta de inicialização automática**.
4. Volte até a pasta onde está o `pokemacro.ahk` do PokéMacro.
5. Segure **Ctrl + Shift** e **arraste** o arquivo `pokemacro.ahk` para a pasta de inicialização.  
   *(Isso cria um atalho — não mova o arquivo original)*
6. Pronto. Na próxima vez que o Windows iniciar, o PokéMacro abrirá automaticamente.

> 💡 **Dica:** Para verificar se funcionou, pressione **Win + R**, digite `shell:startup` e confirme que o atalho do `pokemacro.ahk` está lá.

---

### Método 2 — Agendador de Tarefas (Mais confiável)

Recomendado se o Método 1 não funcionar ou se você quiser que o macro inicie com permissões de administrador.

1. Pressione **Win + R**, digite `taskschd.msc` e pressione **Enter**.
2. No painel direito, clique em **Criar Tarefa Básica...**.
3. Dê um nome como `PokéMacro` e clique em **Avançar**.
4. Em **Gatilho**, selecione **Ao fazer logon** e clique em **Avançar**.
5. Em **Ação**, selecione **Iniciar um programa** e clique em **Avançar**.
6. Clique em **Procurar** e selecione o arquivo `pokemacro.ahk` na pasta do PokéMacro.
7. No campo **Iniciar em**, coloque o caminho completo da pasta do PokéMacro  
   *(ex: `C:\Users\SeuUsuario\Documents\macro_modular`)*
8. Clique em **Avançar** e depois em **Concluir**.

> ✅ Com este método o macro inicia mesmo que o atalho da pasta de inicialização seja ignorado pelo Windows.

---

### Removendo a inicialização automática

**Método 1:** Abra `shell:startup` pelo Win+R e delete o atalho do `pokemacro.ahk`.

**Método 2:** Abra o Agendador de Tarefas (`taskschd.msc`), localize a tarefa `PokéMacro` na lista, clique com o botão direito e selecione **Excluir**.

---

*Documentação gerada para PokéMacro v1.0 — AutoHotkey v2.0*
