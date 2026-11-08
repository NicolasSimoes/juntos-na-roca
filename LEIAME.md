# Juntos na Roça — Grupo AmendoBobos

Jogo cooperativo local para duas crianças do 3º ano. São 5 dias na fazenda da Vovó Zefa,
e nenhuma tarefa pode ser feita sozinha. O jogo acaba na Festa da Colheita.

## Como abrir

1. Instale o **Godot 4.3 ou mais novo** (foi testado no 4.3 e no 4.5.1).
2. No Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** (ou o botão de "play") para jogar.

Na primeira vez, o Godot leva alguns segundos importando as imagens e os sons.

## O começo do jogo

1. **Menu** (estilo Zelda): o título dourado e a caixa com o vaga-lume. Os dois jogadores
   mexem no menu. Opções: **Jogar**, **Como jogar** (com as teclas desenhadas) e **Créditos**.
   Esc fecha os painéis.
2. **Prefácio** (inspirado na abertura de Star Wars, mas na roça): devagar, com letras grandes
   e frases curtas, o texto amarelo vai deitado no pasto até a casa da Vovó.
   **AÇÃO ou Esc pula** a qualquer momento.
3. **Quadrinhos**: 4 quadros contam a história (os netos chegam, a fazenda perdeu as cores,
   "Sozinho não dá... Juntos, sim!", toca aqui). AÇÃO avança, Esc pula.
4. **Tela inicial**: o jogo começa quando os dois apertam AÇÃO. Esc volta ao menu.

Depois da festa, o jogo volta para o menu.

## Controles

| | Jogador 1 (laranja) | Jogador 2 (azul) |
|---|---|---|
| Andar | W A S D | Setas |
| Ação | Espaço | Enter |
| Controle | Controle 1 | Controle 2 |

- **Esc**: pausa (no menu, fecha o painel; no prefácio e nos quadrinhos, pula).
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
| O desenho do mapa (chão, casa, árvores, cercas) | abrir `cenas/fazenda.tscn` no editor |
| Onde fica cada coisa que as tarefas usam (estações, destinos) | `scripts/lugares.gd` |
| As tarefas de cada dia, os nomes e os ícones | `scripts/autoload/jogo.gd` |
| O que a Vovó fala, os elogios e os créditos | `scripts/textos.gd` |
| Qual imagem é cada neto e a Vovó | `scripts/aparencia.gd` (animações em `assets/animacoes/`) |
| O visual de um minijogo | `cenas/minijogos/minijogo_*.tscn` (no editor) |
| A regra de um minijogo (vez, força, pontos) | `scripts/minijogos/regras/regra_*.gd` |
| Como o minijogo liga a regra à tela | `scripts/minijogos/minijogo_*.gd` |
| Uma tarefa (o que cada papel faz, a dica) | `scripts/tarefas/tarefa_*.gd` |
| O prefácio e os quadrinhos | `scripts/telas/prefacio.gd`, `cenas/quadrinhos.tscn` |
| Menu, Como jogar e Créditos | `scripts/telas/menu_principal.gd`, `cenas/como_jogar.tscn`, `cenas/creditos.tscn` |
| Cores, painéis e barras | `assets/tema/tema_jogo.tres` |
| As teclas | Projeto > Configurações do Projeto > Mapa de Entrada (ações `p1_` e `p2_`) |

## Testes

```
godot --headless --path . -s testes/rodar_testes.gd
```

As regras dos minijogos ficam separadas da tela justamente para poderem ser testadas assim.
Para ver as telas sem jogar: `godot --path . -s ferramentas/capturar_telas.gd`
(minijogos), `ferramentas/capturar_menus.gd` e `ferramentas/capturar_fazenda.gd` (salvam em `capturas/`).

## Arte e sons

O cenário, os netos e a Vovó usam o pacote **Super Retro World – Farming**, por Gif
(licença em `assets/SuperRetroWorld_Farming/`). Vaca, galinhas, trator, os sons e as músicas
foram feitos pelo grupo por código, então vocês podem trocar à vontade.
Para trocar uma imagem ou um som, salve o seu arquivo com o **mesmo nome** por cima do antigo.
A "voz" da Vovó é um bipe (`assets/sons/fala.wav`). Se gravarem a voz de alguém do grupo,
é só colocar no lugar.

As músicas do menu (`musica_menu.ogg`) e do prefácio (`musica_prefacio.ogg`) também são
originais, feitas por código no mesmo clima de aventura. Nenhuma música de Zelda ou de
Star Wars foi usada, só o estilo.

As duas fontes são livres (SIL Open Font License): **Cinzel Decorative** (títulos) e
**Pixelify Sans** (menus e prefácio). As licenças estão em `assets/fontes/`.
