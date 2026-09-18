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
3. Dê um duplo clique em **`main.ahk`** para iniciar o sistema.
4. A interface aparecerá na tela. Se não aparecer, pressione **Ctrl+F12**.

> O arquivo `config.ini` é criado automaticamente na primeira vez que você salva qualquer configuração. Não é necessário criá-lo manualmente.

---

## Estrutura de Pastas

```
macro_modular/
│
├── main.ahk                     ← Ponto de entrada — execute este arquivo
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
│   ├── globals.ahk              ← Estado global, mapa de macros e sistema de temas
│   ├── config.ahk               ← Leitura/escrita do config.ini
│   ├── hint.ahk                 ← Notificações flutuantes na tela
│   ├── window.ahk               ← Drag e posição da janela
│   └── input.ahk                ← Captura de teclas e posição do mouse
│
├── ui\                          ← Telas da interface gráfica
│   ├── slot.ahk                 ← Componente de botão de macro
│   ├── gui_main.ahk             ← Barra principal com todos os macros
│   ├── config_combo.ahk         ← Tela de configuração dos Combos
│   ├── config_revive.ahk        ← Tela de configuração do Revive
│   ├── config_combo_revive.ahk  ← Tela de configuração do Combo Revive
│   ├── config_cooldown.ahk      ← Tela de configuração do Cooldown
│   └── config_geral.ahk         ← Configurações globais do sistema
│
└── macros\                      ← Lógica de execução dos macros
    ├── hotkeys.ahk              ← Registro e despacho de hotkeys
    ├── combo.ahk                ← Lógica do Combo Principal/Secundário
    ├── revive.ahk               ← Lógica do Revive
    ├── combo_revive.ahk         ← Lógica do Combo Revive
    └── cooldown.ahk             ← Lógica do Cooldown Progressivo
```

---

## Como Usar

### Abrindo e fechando a interface

- Pressione **Ctrl+F12** para abrir ou fechar a barra de macros.
- Você também pode fechar clicando no botão **X** no canto superior direito da barra.
- A interface é flutuante e pode ser **arrastada** para qualquer posição da tela. A posição é salva automaticamente.

### Ativando um macro

1. Clique no **slot** do macro desejado na barra principal.
2. O slot ficará com a cor de destaque do tema quando ativo.
3. Clique novamente para **desativar**.

> 💡 **Exclusividade entre Combos:** Combo Principal, Combo Secundário e Combo Revive são mutuamente exclusivos — ativar um desliga automaticamente os outros.

> 💡 **Miniatura de tecla:** Cada slot exibe a tecla do macro configurada em letras pequenas, para que você saiba qual botão pressionar sem precisar abrir as configurações.

### Configurando um macro

1. Clique no botão **⚙ CFG** ao lado do macro desejado.
2. A tela de configuração será aberta.
3. Configure cada opção conforme descrito nas seções abaixo.
4. Feche com o botão **X** — as configurações são salvas automaticamente.

---

## Interface Principal

```
┌──────────────────────────────────┐
│ ✦ POKÉMACRO ✦           ↑  ⚙  X │  ← Título | Compacto | Config | Fechar
├──────────────────────────────────┤
│  [ícone COMBO PRINC.]  [F3-F8]   │
│  COMBO PRINC.             ⚙ CFG  │
├──────────────────────────────────┤
│  [ícone COMBO SEC.]              │
│  COMBO SEC.               ⚙ CFG  │
├──────────────────────────────────┤
│  [ícone COMBO REVIVE]            │
│  COMBO REVIVE             ⚙ CFG  │
├──────────────────────────────────┤
│  [ícone REVIVE]                  │
│  REVIVE                   ⚙ CFG  │
├──────────────────────────────────┤
│  [ícone COOLDOWN]                │
│  COOLDOWN                 ⚙ CFG  │
├──────────────────────────────────┤
│         CTRL+F12  FECHAR         │
└──────────────────────────────────┘
```

| Botão | Função |
|-------|--------|
| Slot (ícone/texto) | Ativa/desativa o macro |
| Miniatura `[TECLA]` | Indica qual tecla ativa o macro |
| ⚙ CFG | Abre a tela de configuração do macro |
| ↑ / ↓ | Alterna entre modo normal e modo compacto |
| ⚙ (topo direito) | Abre as Configurações Gerais |
| X (topo direito) | Fecha a interface |

### Modo Compacto

Clique no botão **↑** no canto superior direito para ativar o modo compacto.  
Neste modo os slots exibem apenas o nome do macro em texto, sem ícones, ocupando muito menos espaço na tela.  
Clique em **↓** para voltar ao modo normal com ícones.

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
| **Hotkey Ligar/Desligar** | Tecla para ativar/desativar o macro sem abrir a interface |

**Como configurar passo a passo:**

1. Abra a configuração do Combo Principal (botão ⚙ CFG).
2. Clique em **▶ DEFINIR BOTÃO INICIAL** e pressione a tecla da sua primeira habilidade.
3. Clique em **▶ DEFINIR BOTÃO FINAL** e pressione a tecla da sua última habilidade.
4. Clique em **▶ DEFINIR TECLA MACRO** e pressione a tecla/botão que vai disparar o combo.
5. Se quiser Full Attack/Defense, vá em [Configurações Gerais](#configurações-gerais) e defina as teclas globais, depois ative-as aqui com o radio **ATIVAR**.
6. Feche a configuração.
7. Na barra principal, clique no slot do **Combo Principal** para ativá-lo.
8. No jogo, pressione a tecla configurada — o combo será executado automaticamente.

> **Exemplo:** Habilidades de F3 a F8.  
> Botão Inicial: `3` → Botão Final: `8` → com prefixo F ativo, o macro envia F3, F4, F5, F6, F7, F8 em sequência.

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

1. Abra a configuração do Revive (botão ⚙ CFG).
2. Clique em **▶ DEFINIR POSIÇÃO** e depois clique com o botão esquerdo do mouse **sobre o Pokémon** que você quer reviver no jogo.
3. Clique em **▶ DEFINIR HOTKEY** e pressione a tecla que você usa para confirmar/usar o item de revive.
4. Clique em **▶ DEFINIR TECLA MACRO** e pressione a tecla/botão que vai disparar o macro.
5. Ajuste o **Delay** se necessário (padrão: 40ms).
6. Feche e ative o macro na barra principal.

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
| **Tempos de Espera** | Tempo em segundos para cada slot (PKM 1, PKM 2, PKM 3, PKM 4) |
| **Full Defense** | Ativa/desativa o envio de Full Defense ao iniciar |
| **Hotkey Ligar/Desligar** | Tecla para ativar/desativar o macro |

> **Exemplo:** Pokémon Inicial = 3, tempos PKM3 = 10s, PKM2 = 8s, PKM1 = 6s.  
> O macro vai: clicar → Ctrl+3 → 10s → clicar → Ctrl+2 → 8s → clicar → Ctrl+1 → 6s → fim.

---

## Configurações Gerais

Acessado pelo botão **⚙** no canto superior direito da barra principal.  
Estas configurações são **globais** — afetam todos os macros do sistema.

---

### 1. Fonte da Interface

Troca a fonte de todos os textos da interface simultaneamente.

| Opção | Aparência |
|-------|-----------|
| **Courier New** | Padrão, estilo terminal clássico |
| **Consolas** | Moderna, boa legibilidade |
| **Lucida Console** | Espaçada, fácil de ler em telas menores |
| **Fixedsys** | Estilo retrô, pixels quadrados |

> Ao selecionar uma fonte, a interface fecha e reabre automaticamente com a nova fonte aplicada.

---

### 2. Tema de Cores

Altera o esquema de cores de toda a interface simultaneamente.

| Tema | Descrição |
|------|-----------|
| **Pokédex Vermelho** | Tema padrão — vermelho, amarelo e azul clássico Pokémon |
| **Night Blue** | Tons de azul escuro, inspirado na noite |
| **Gold** | Preto e dourado, elegante |
| **Minimal** | Cinza escuro, discreto e limpo |

> Ao selecionar um tema, a interface fecha e reabre automaticamente com as novas cores aplicadas.

---

### 3. Delay Entre Teclas do Combo (ms)

Controla o **intervalo em milissegundos** entre cada tecla enviada nos macros de Combo.

- **Valor menor** = combo mais rápido (ex: 50ms)
- **Valor maior** = combo mais lento, mais seguro (ex: 150ms)
- **Padrão:** 92ms

> Ajuste conforme a latência do servidor. Em servidores com alta latência, aumente o delay para evitar que habilidades sejam perdidas.

---

### 4. Usar Prefixo [F] nas Teclas

Define como as teclas do combo são enviadas ao jogo.

| Opção | Teclas enviadas | Quando usar |
|-------|----------------|-------------|
| **SIM (F1..F9)** | `F1`, `F2`, `F3`... | Quando as habilidades estão mapeadas nas teclas F |
| **NÃO (1..9)** | `1`, `2`, `3`... | Quando as habilidades estão mapeadas nos números |

> **Exemplo:** Botão Inicial `3`, Botão Final `6`:  
> - Com prefixo F: envia `F3`, `F4`, `F5`, `F6`  
> - Sem prefixo F: envia `3`, `4`, `5`, `6`

---

### 5. Modo Legado (Revive)

Altera o comportamento dos macros de **Revive** e **Combo Revive**.

| Modo | Comportamento | Quando usar |
|------|--------------|-------------|
| **INATIVO** (padrão) | Usa `Ctrl+1` para selecionar o slot | Versões mais recentes do jogo |
| **ATIVO** | Usa clique direito do mouse no alvo | Versões mais antigas do jogo |

---

### 6. Tecla Full Attack (Global)

Define a tecla enviada **antes** de iniciar qualquer combo (quando Full Attack está ativado na configuração do combo).

- Compartilhada entre Combo Principal, Combo Secundário e Combo Revive.
- Cada combo tem seu próprio interruptor ATIVAR/DESATIVAR nas configurações individuais.

---

### 7. Tecla Full Defense (Global)

Define a tecla enviada **após** o término de qualquer combo ou ao iniciar o Cooldown (quando Full Defense está ativado).

- Compartilhada entre todos os macros que suportam Full Defense.

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

> ⚠️ **LButton** e **RButton** não são capturáveis para evitar conflitos com o uso normal do mouse.

### Prevenção de conflitos

O sistema possui proteção avançada contra conflito de hotkeys:

- **Mesma tecla no macro e no jogo:** Se a Tecla do Macro for a mesma que uma ação do jogo (ex: `F3` é hotkey e primeira habilidade do combo), o sistema usa supressão de input — a tecla não é enviada ao jogo duas vezes.
- **Re-entrada bloqueada:** Enquanto um combo está em execução, novas execuções do mesmo combo são bloqueadas.
- **Revive interrompe Combo:** Pressionar a tecla do Revive ou Combo Revive durante a execução de um combo **interrompe o combo imediatamente** e executa o revive.
- **Cancelamento do Cooldown:** Pressionar a hotkey do Cooldown durante a execução cancela o macro imediatamente.

### Botão Reset (R)

Cada tela de configuração possui um botão **R** vermelho no canto superior direito.  
Ao confirmar, **apaga todas as configurações** daquele macro e retorna tudo para `N/A`.

> Use com cuidado — esta ação não pode ser desfeita.

---

## Perguntas Frequentes

**O macro não está funcionando. O que verificar?**

1. Verifique se o macro está **ativado** (slot com cor de destaque na barra principal).
2. Verifique se a janela do jogo está em **foco** (em primeiro plano).
3. Verifique se a **Tecla do Macro** está configurada (não deve estar como `N/A`).
4. Verifique se o processo do jogo é `pxgme.exe` — o sistema monitora especificamente este processo.

---

**As teclas do combo não estão chegando no jogo.**

- Tente aumentar o **Delay Entre Teclas** nas Configurações Gerais.
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
- Se a posição foi salva fora da tela (monitor desconectado), delete a seção `[Janela]` do arquivo `config.ini` com um editor de texto.

---

**A interface ficou muito grande na tela. Como reduzir?**

- Clique no botão **↑** no canto superior direito para ativar o **modo compacto**.  
  Neste modo os slots exibem apenas o nome do macro em texto, sem ícones.
- Clique em **↓** para voltar ao modo normal.

---

**Posso usar o sistema em outro jogo?**

O sistema está configurado para detectar a janela `pxgme.exe`. Para usar em outro jogo, edite a linha no arquivo `macros\hotkeys.ahk`:
```autohotkey
JanelaAtiva() => WinActive("ahk_exe pxgme.exe")
```
Substitua `pxgme.exe` pelo nome do executável do seu jogo.

---

**Como alterar o visual da interface?**

Abra as **Configurações Gerais** (botão ⚙ na barra de título) e:
- Troque a **Fonte** entre Courier New, Consolas, Lucida Console e Fixedsys.
- Troque o **Tema de Cores** entre Pokédex Vermelho, Night Blue, Gold e Minimal.

Qualquer alteração é aplicada imediatamente ao fechar e reabrir a interface.

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
4. Volte até a pasta onde está o `main.ahk` do PokéMacro.
5. Segure **Ctrl + Shift** e **arraste** o arquivo `main.ahk` para a pasta de inicialização.  
   *(Isso cria um atalho — não mova o arquivo original)*
6. Pronto. Na próxima vez que o Windows iniciar, o PokéMacro abrirá automaticamente.

> 💡 **Dica:** Para verificar se funcionou, pressione **Win + R**, digite `shell:startup` e confirme que o atalho do `main.ahk` está lá.

---

### Método 2 — Agendador de Tarefas (Mais confiável)

Recomendado se o Método 1 não funcionar ou se você quiser que o macro inicie com permissões de administrador.

1. Pressione **Win + R**, digite `taskschd.msc` e pressione **Enter**.
2. No painel direito, clique em **Criar Tarefa Básica...**.
3. Dê um nome como `PokéMacro` e clique em **Avançar**.
4. Em **Gatilho**, selecione **Ao fazer logon** e clique em **Avançar**.
5. Em **Ação**, selecione **Iniciar um programa** e clique em **Avançar**.
6. Clique em **Procurar** e selecione o arquivo `main.ahk` na pasta do PokéMacro.
7. No campo **Iniciar em**, coloque o caminho completo da pasta do PokéMacro  
   *(ex: `C:\Users\SeuUsuario\Documents\macro_modular`)*
8. Clique em **Avançar** e depois em **Concluir**.

> ✅ Com este método o macro inicia mesmo que o atalho da pasta de inicialização seja ignorado pelo Windows.

---

### Removendo a inicialização automática

**Método 1:** Abra `shell:startup` pelo Win+R e delete o atalho do `main.ahk`.

**Método 2:** Abra o Agendador de Tarefas (`taskschd.msc`), localize a tarefa `PokéMacro` na lista, clique com o botão direito e selecione **Excluir**.

---

*Documentação gerada para PokéMacro v1.0 — AutoHotkey v2.0*
