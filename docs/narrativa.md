# Narrativa e contexto: análise e redesenho

Público: duplas de crianças de **10 anos**. Pergunta da análise: em cada momento, a criança sabe
**o que está acontecendo**, **por que** está fazendo aquilo e **como** fazer, sem precisar ler muito?

## Diagnóstico (como estava em 08/11/2026)

| Momento | O que a criança recebia | Problema | Gravidade |
|---|---|---|---|
| Abertura (prefácio Star Wars) | 7 frases rolando em perspectiva | Bonito, mas passivo e longo; repetia o que os quadrinhos contam | média |
| Quadrinhos | 4 quadros: "Oi, Vovó!", "A fazenda perdeu as cores!", "Sozinho não dá… Juntos, sim!", toca aqui | Não diz **por que** a fazenda ficou cinza, **qual é o objetivo** (a festa em 5 dias), nem **o papel dos jogadores**. Os jogadores só assistem | **alta** |
| Começo do dia | Lista de problemas ("O poço quebrou. E o fogão está sem lenha.") | Diz o quê, mas não **por que importa** nem **onde estão as coisas** (a corda está no galpão? as tábuas na mata?) | **alta** |
| Entrar nos círculos | O minijogo abre na hora | Ninguém explica **o que vão fazer** nem **como**. A criança descobre errando. Nas tarefas do mapa, só uma frase de quem faz o quê | **alta** |
| Dentro do minijogo | Rodapé com a tecla ("APERTE Enter para empurrar") | Ensina a tecla, mas não o objetivo ("tirar o trator da lama até a barra encher") | média |
| Tarefas em duas partes (lenha, animais, colher) | Uma frase na troca de fase | Ok, mas sem ligação com o motivo | baixa |
| Fim da tarefa | Elogio da Vovó | Não conecta com a mecânica principal: **a cor voltando** àquela parte da fazenda | média |
| Fim do dia | "Tudo pronto! Os dois na porta, para dormir." | Sem resumo e sem expectativa para amanhã; a contagem para a festa não aparece | média |

## Redesenho

**Princípio:** toda tarefa responde a três perguntas, nesta ordem e em frases de até ~8 palavras:
1. **Por quê?** (o problema da fazenda, dito pela Vovó)
2. **O quê?** (o que cada um faz, com ícone e tecla desenhada)
3. **Pronto?** (os dois apertam AÇÃO: só começa quando os dois leram)

1. **A cena Star Wars sai do caminho do jogo.** O arquivo continua no projeto (`cenas/prefacio.tscn`)
   para quem quiser reaproveitar, mas Jogar → **quadrinhos** → tela inicial.
2. **Quadrinhos em 2 páginas (8 quadros)** com começo, problema, objetivo, regra e convite:
   - Página 1, *A carta*: a carta da Vovó → a chegada → a fazenda cinza (por quê) → a festa em 5 dias (objetivo).
   - Página 2, *O segredo da roça*: "aqui ninguém faz nada sozinho" → sozinho não dá / juntos sim →
     cada tarefa traz a cor de volta (mecânica) → **"Vocês topam?"**: os dois apertam AÇÃO juntos para aceitar.
3. **Cartão de missão** antes de toda tarefa (`cenas/objetos/cartao_missao.tscn`): a Vovó diz o porquê,
   cada jogador vê o seu papel (neto, ícone, verbo e tecla) e os dois confirmam com AÇÃO.
   Textos em `Textos.MISSOES`.
4. **Começo do dia**: o problema, o porquê e onde ir. Ex.: "A corda está no galpão. As tábuas, na mata."
5. **Fim da tarefa**: o elogio fala da cor que voltou ("Olhem! O quintal ganhou cor!").
6. **Fim do dia**: o que conseguiram e quantos dias faltam para a festa.

## Como checar

- Teste: toda tarefa de `Jogo.NOMES` tem missão em `Textos.MISSOES`.
- Teste: nenhuma fala passa de 9 palavras.
- Revisão independente: alguém (ou um agente) que não escreveu os textos joga as capturas e responde,
  para cada tarefa: "a criança sabe por quê, o quê e como?".
