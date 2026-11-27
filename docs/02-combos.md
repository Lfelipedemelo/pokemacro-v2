# 2. Combo Principal e Combo Secundário

[⬅ Primeiros passos](01-primeiros-passos.md) · [README](../README.md) · Próximo: [Revive ➡](03-revive.md)

Os combos apertam por você uma sequência de habilidades (ex.: `F3, F4, F5, F6, F7, F8`) com um intervalo fixo entre elas, opcionalmente com **Full Attack** antes e **Full Defense** depois.

O **Combo Principal** e o **Combo Secundário** são idênticos — são só duas configurações independentes, para você ter dois sets de habilidades (ex.: um pokémon de dano em área e outro de alvo único) e alternar entre eles clicando na HUD.

---

## 2.1 O que o combo faz, na ordem

```
[Full Attack]  →  F3  →  espera  →  F4  →  espera  →  …  →  F8  →  espera  →  [Full Defense]
 (opcional)                                                                     (opcional)
```

1. Se **Full Attack** estiver ativado, envia a tecla de Full Attack (definida nas Configurações Gerais).
2. Envia cada tecla do **Botão Inicial** até o **Botão Final**, esperando o **Delay Entre Teclas** depois de cada uma.
3. Se **Full Defense** estiver ativado, envia a tecla de Full Defense no final.

O combo **para na hora** se: você usar o **Revive** / **Combo Revive**, apertar a **Tecla de Pânico**, desligar o macro, ou sair da janela do jogo. Apertar a tecla do combo de novo enquanto ele roda **é ignorado** (não inicia um segundo combo por cima).

---

## 2.2 Configurando

Passe o mouse na HUD e clique no **⚙ abaixo do ícone do Combo Principal** (ou do Secundário):

<p align="center"><img src="img/config-combo.png" width="340" alt="Tela de configuração do combo com marcadores numerados"></p>

| # | Campo | O que configurar |
|:-:|-------|------------------|
| **1** | **Botão Inicial** | A tecla da **primeira** habilidade do combo. Pressione `F3` ou `3` — só o número é usado |
| **2** | **Botão Final** | A tecla da **última** habilidade do combo |
| **3** | **Tecla do Macro** | A tecla/botão que **dispara** o combo no jogo (ex.: `XButton2`, botão lateral do mouse) |
| **4** | **Ligar/Desligar** | Atalho para ligar/desligar este combo sem abrir a HUD (aceita `Ctrl`/`Alt`/`Shift`, ex.: `Alt + 1`) |
| **5** | **Full Attack** | `ATIVAR` envia a tecla de Full Attack **antes** do combo |
| **6** | **Full Defense** | `ATIVAR` envia a tecla de Full Defense **depois** do combo |
| **7** | **Delay Entre Teclas** | Intervalo entre cada tecla (300 a 1000 ms, padrão 450 ms — abaixo de 300 ms o jogo perde teclas). **Vale para todos os combos** |
| **8** | **Contar Stun (6s)** | `SIM` mostra na tela uma contagem de **6 segundos** quando o combo envia o **Botão do Stun** (9). Padrão `NÃO` — veja [2.4](#24-contagem-do-stun) |
| **9** | **Botão do Stun** | A tecla do combo que tem a skill de stun (ex.: `F5`). Clique para escolher entre as teclas do combo |
| **10** | **Contagem do Stun** | Tamanho da contagem: `NORMAL` (número grande, com `STUN` em cima) ou `COMPACTA` (só o número, pequeno). **É o mesmo nos dois combos** |
| **11** | **Posição** | Onde a contagem aparece (`CENTRO` = um pouco abaixo do meio da tela, padrão). Clique para abrir uma prévia e arrastá-la; clique de novo para fechar. **É a mesma nos dois combos** |
| **12** | **Usar a mesma no stun** | Copia a posição e o tamanho da contagem da pausa da [Rotação](06-rotacao.md#pausa-no-meio-do-combo) para a do stun |
| **13** | **Exibir no Mini Menu** | `NÃO` esconde o ícone deste combo da HUD |

Os campos 10 a 12 ficam apagados com **Contar Stun** em `NÃO`.

### Passo a passo

1. **Botão Inicial** (1): clique no cartão e aperte a tecla da primeira habilidade (ex.: `F3`).
2. **Botão Final** (2): clique e aperte a tecla da última habilidade (ex.: `F8`).
3. **Tecla do Macro** (3): clique e aperte a tecla/botão que você vai usar para soltar o combo.
   > 💡 Botões laterais do mouse (`XButton1`/`XButton2`) são práticos: você mira com o mouse e solta o combo sem tirar a mão.
4. *(Opcional)* **Ligar/Desligar** (4): defina um atalho, ex.: `Alt + 1`.
5. *(Opcional)* **Full Attack / Full Defense** (5 e 6): primeiro defina as teclas em [Configurações Gerais](07-configuracoes-gerais.md#passo-6--teclas-de-full-attack-e-full-defense); depois clique em `ATIVAR` aqui.
6. **Delay** (7): comece com o padrão (450 ms). Se habilidades estiverem "falhando", aumente; se estiver sobrando tempo, diminua (até 300 ms).
7. *(Opcional)* **Contagem do stun** (8 a 12): veja [2.4](#24-contagem-do-stun).
8. Feche a tela no **×**.

> ⚠️ **Prefixo F:** o combo envia `F3…F8` ou `3…8` conforme a opção **[Prefixo [F]](07-configuracoes-gerais.md#passo-1--prefixo-f)** das Configurações Gerais. Confira se bate com as teclas das suas habilidades no jogo.

---

## 2.3 Usando no jogo

1. Na HUD, clique no ícone do **Combo Principal** — ele ganha o anel azul (ligado).

   <p align="center"><img src="img/hud.png" width="420" alt="HUD com o Combo Principal ligado"></p>

2. Clique na janela do jogo (ele precisa estar em foco).
3. Aperte a **Tecla do Macro** — o combo roda sozinho.
4. Para trocar para o Combo Secundário, é só clicar no ícone dele: o Principal desliga automaticamente (os combos são exclusivos).

### Exemplo com os valores da imagem

| Configuração | Valor |
|--------------|-------|
| Botão Inicial / Final | `3` / `8` |
| Prefixo [F] | `SIM (F1..F9)` |
| Full Attack | Ativado (tecla `F10`) |
| Full Defense | Desativado |
| Delay | 450 ms |
| Tecla do Macro | `XButton2` |

Ao apertar `XButton2` no jogo: `F10` → `F3` → 450 ms → `F4` → 450 ms → … → `F8`.

---

## 2.4 Contagem do stun

Depois de uma skill de stun, o alvo fica parado por alguns segundos, e é nesse tempo que você troca de pokémon e faz outras ações. A contagem do stun mostra esses **6 segundos** na tela, para você saber quanto tempo ainda tem.

1. Em **Contar Stun** (8), escolha `SIM`.
2. Em **Botão do Stun** (9), escolha a tecla da skill de stun:

   <p align="center"><img src="img/config-combo-stun.png" width="300" alt="Seletor do botão do stun aberto, com as teclas F3 a F8 e o F5 marcado"></p>
3. *(Opcional)* Escolha o tamanho (10) e o lugar (11) da contagem. **Posição** abre uma **prévia** na tela: arraste com o botão esquerdo até onde quiser; a posição é salva ao soltar. Botão direito na prévia volta ao padrão. Clique de novo em **Posição** (`✓ PRONTO`) para fechar a prévia. Ela também fecha junto com a tela. Para deixar a contagem do stun no mesmo lugar e no mesmo tamanho da contagem da pausa da Rotação, use **Usar a mesma no stun** (12). As duas podem aparecer ao mesmo tempo e, nesse caso, ficam uma por cima da outra.

   <p align="center"><img src="img/contagem-previa-stun.png" width="210" alt="Prévia da contagem do stun com contorno tracejado e a legenda ARRASTE · BOTÃO DIREITO = CENTRO"></p>

No jogo, quando o combo envia o botão do stun, a contagem aparece e vai descendo de 6 s. Ela é azul e fica **vermelha nos últimos 2 segundos**:

| Normal | Fim (últimos 2 s) | Compacta |
|:---:|:---:|:---:|
| <img src="img/contagem-stun.png" width="120" alt="Contagem do stun azul, 4,2s"> | <img src="img/contagem-stun-fim.png" width="120" alt="Contagem do stun vermelha, 1,6s"> | <img src="img/contagem-stun-compacta.png" width="70" alt="Contagem do stun compacta, 4,2s"> |

- A contagem começa no instante em que a tecla do stun **sai**. O combo continua normalmente, sem esperar.
- Ela **continua** se você trocar de pokémon, se o combo for interrompido depois da tecla do stun ou se o jogo perder o foco. Se o combo for interrompido **antes** da tecla, ela nem começa.
- Existe **uma contagem de stun só**: enviar a tecla de stun de novo (por este ou pelo outro combo) **recomeça** dos 6 s. A **tecla de pânico** encerra a contagem.
- O macro não sabe se o stun pegou no jogo (ou se a skill estava em cooldown): ele conta sempre que envia a tecla.
- Vale quando você solta o combo pela **Tecla do Macro**. No combo que a [Rotação](06-rotacao.md#contagem-do-stun) solta depois da troca, quem decide é o chip **STUN** de cada passo.
- **Contar Stun** e **Botão do Stun** são de cada combo; o tamanho e a posição da contagem são os mesmos nos dois.

---

## 2.5 Problemas comuns

| Sintoma | Solução |
|---------|---------|
| Nada acontece | O ícone está com anel azul? O jogo está em foco? Botão Inicial/Final e Tecla do Macro não estão `N/A`? |
| Aviso *"COMBO PRINCIPAL: configure os botões INICIAL e FINAL"* (ou SECUNDÁRIO) | O **Botão Inicial** (1) ou o **Final** (2) não está definido, ou o inicial vem depois do final (ex.: `F8` → `F3`). Ao salvar um botão assim, a tela já avisa *"BOTÃO INICIAL (…) está depois do FINAL (…)"* |
| Aviso *"BOTÃO INICIAL: use uma tecla com número"* | Os botões do combo precisam ser teclas com número (`F3` ou `3`) — só o número é usado. A tecla não foi salva |
| Algumas habilidades não saem | Aumente o **Delay Entre Teclas** (o jogo pode estar recusando teclas muito rápidas) |
| Sai a tecla errada (`3` em vez de `F3`) | Ajuste o **Prefixo [F]** nas Configurações Gerais |
| O combo parou no meio | Algo o interrompeu: Revive, Pânico, macro desligado ou você trocou de janela |
| A contagem do stun não apareceu | **Contar Stun** (8) está em `SIM`? O **Botão do Stun** (9) mostra uma tecla (não `—`)? O combo chegou a enviar essa tecla? Pela Rotação, vale o chip **STUN** do passo, não esta opção |

---

[⬅ Primeiros passos](01-primeiros-passos.md) · [README](../README.md) · Próximo: [Revive ➡](03-revive.md)
