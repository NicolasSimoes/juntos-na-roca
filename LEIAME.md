# Juntos na Roça — Grupo AmendoBobos

Jogo cooperativo local para duas crianças do 3º ano. São 5 dias na fazenda da Vovó Zefa,
e nenhuma tarefa pode ser feita sozinha. O jogo acaba na Festa da Colheita.

## Como abrir

1. Instale o **Godot 4.3 ou mais novo** (foi testado no 4.3 e no 4.5.1).
2. No Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** (ou o botão de "play") para jogar.

Na primeira vez, o Godot leva alguns segundos importando as imagens e os sons.

## O começo do jogo

1. **Menu** (estilo Zelda): o título dourado, "Aperte Espaço ou Enter" e a caixa com o
   vaga-lume. Os dois jogadores mexem no menu. Opções: **Começar**, **Prefácio**, **Como jogar**
   e **Créditos**. Esc fecha os painéis.
2. **Prefácio** (inspirado na abertura de Star Wars, mas na roça): o dia amanhecendo e o galo
   cantando, a frase "Há pouco tempo, numa roça não muito, muito distante....", o título que vai
   embora para o horizonte e o texto amarelo deitado no pasto, indo em perspectiva até a casa da
   Vovó. No fim a câmera chega na casa, onde a Vovó e os netos esperam.
   Em "Começar" ele passa antes do jogo; em "Prefácio" ele passa e volta para o menu.
   **AÇÃO ou Esc pula** a qualquer momento.
3. **Tela inicial**: o jogo começa quando os dois apertam AÇÃO. Esc volta ao menu.

Depois da festa, o jogo volta para o menu.

## Controles

| | Jogador 1 (laranja) | Jogador 2 (azul) |
|---|---|---|
| Andar | W A S D | Setas |
| Ação | Espaço | Enter |
| Controle | Controle 1 | Controle 2 |

- **Esc**: pausa (no menu, fecha o painel; no prefácio, pula).
- **F1 a F5**: começa direto no dia escolhido. Serve para testar um dia sem jogar os anteriores.

## Como o jogo funciona

- Toda tarefa tem **dois círculos no chão**. Ela só começa com cada jogador em um círculo.
  O círculo da esquerda é um papel e o da direita é outro. A cor da borda mostra quem a Vovó
  sugere para cada papel, para os dois revezarem.
- A **setinha amarela** mostra para onde ir.
- No fim de cada tarefa vem o **"Toca aqui!"**: os dois apertam AÇÃO ao mesmo tempo.
- A fazenda começa **cinza**. Cada tarefa feita deixa a sua parte do mapa colorida.
- Errar só faz um "tóim" e repete o passo. Depois de 3 erros seguidos, ou se a dupla ficar
  parada muito tempo, a Vovó aparece com uma dica.
- Na festa, o álbum mostra uma "foto" de cada tarefa, tirada durante o jogo.

| Dia | Tarefas |
|---|---|
| 1 | Consertar o poço (buscar a corda e as tábuas, encaixar as tábuas e martelar no tempo certo) e lenha (serra alternada e carregar a tora juntos) |
| 2 | Desatolar o trator (um acelera, o outro empurra) e arar a terra (um dirige, o outro tira as pedras) |
| 3 | Plantar a horta (um semeia, o outro rega) e recolher as galinhas (cercar juntos) |
| 4 | Cuidar dos animais (milho e água, depois a ordenha), pescar (linha e puçá) e cuidar da horta (regar e tirar o mato) |
| 5 | Colher e levar o jerimum gigante até a porteira, e a festa |

## Onde mexer

| Quero mudar... | Arquivo |
|---|---|
| Onde fica cada coisa no mapa | `scripts/lugares.gd` |
| O chão do mapa (está escrito como texto) | `MAPA` em `scripts/fazenda.gd` |
| As tarefas de cada dia, os nomes e os ícones | `scripts/autoload/jogo.gd` |
| O que a Vovó fala no começo do dia e os elogios | `FALAS_DO_DIA` e `ELOGIOS` em `scripts/fazenda.gd` |
| O texto do prefácio (a história) | `INTRO`, `TITULO` e `PARAGRAFOS` em `scripts/telas/prefacio.gd` |
| Os tempos do prefácio (quando cada parte entra) | as constantes `T_...` em `scripts/telas/prefacio.gd` |
| As opções do menu, "Como jogar" e "Créditos" | `scripts/telas/menu_principal.gd` |
| O desenho de fundo do menu | `scripts/telas/paisagem.gd` e `assets/sprites/menu/` |
| Uma tarefa (o que cada papel faz, a dica) | `scripts/tarefas/tarefa_*.gd` |
| Um minijogo que abre por cima do mapa | `scripts/minijogos/minijogo_*.gd` |
| As teclas | Projeto > Configurações do Projeto > Mapa de Entrada (ações `p1_` e `p2_`) |

## Pastas

```
cenas/          menu_principal, prefacio, tela_inicial, fazenda, festa e o jogador
scripts/
  autoload/     Jogo (dia, tarefas feitas, cesta, horta, fotos) e Sons
  tarefas/      uma tarefa por arquivo (todas herdam de tarefa.gd)
  minijogos/    poço, serra, trator, ordenha e pesca (herdam de minijogo.gd)
  telas/        menu, paisagem do menu, prefácio, fontes, toca aqui, tela inicial e festa
  fazenda.gd    monta o mapa e cuida da ordem: estação, tarefa, toca aqui, cor e dormir
  estacao.gd    os dois círculos
  jogador.gd, galinha.gd, horta.gd, carregar_juntos.gd, coletavel.gd, trator_dirigivel.gd, hud.gd
assets/
  sprites/      pixel art: netos e Vovó em 16 x 24, o resto em 16 x 16
  sons/         efeitos (.wav) e músicas (.ogg)
  fontes/       Cinzel Decorative e Pixelify Sans (com as licenças OFL)
  shaders/      cinza (área cinza até a tarefa ser feita), logo_ouro (título dourado com brilho)
                e letreiro (o pasto do prefácio em perspectiva, com o texto deitado nele)
```

## Arte e sons

Toda a arte e todos os sons foram gerados por código, então vocês podem trocar à vontade.
Para trocar uma imagem ou um som, salve o seu arquivo com o **mesmo nome** por cima do antigo.
A "voz" da Vovó é um bipe (`assets/sons/fala.wav`). Se gravarem a voz de alguém do grupo,
é só colocar no lugar.

As músicas do menu (`musica_menu.ogg`) e do prefácio (`musica_prefacio.ogg`) também são
originais, feitas por código no mesmo clima de aventura. Nenhuma música de Zelda ou de
Star Wars foi usada, só o estilo.

As duas fontes são livres (SIL Open Font License): **Cinzel Decorative** (títulos) e
**Pixelify Sans** (menus e prefácio). As licenças estão em `assets/fontes/`.
