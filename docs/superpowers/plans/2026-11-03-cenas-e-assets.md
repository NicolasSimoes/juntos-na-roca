# Refatoração: cenas e assets no lugar de desenho em código — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trocar o desenho feito em código (`_draw()`, `draw_rect`, nós criados com `.new()`) por cenas `.tscn` montadas com os sprites do projeto, e separar a **regra** de cada minijogo (lógica pura, testável) da **tela** (nós na cena).

**Architecture:** Cada minijogo vira três peças: uma `Regra*` (`RefCounted`, sem nós, sem `Input`), uma cena `.tscn` herdada de `minijogo_base.tscn` com os sprites e um script "cola" que lê o controle, chama a regra e atualiza os nós. O mapa da fazenda, o HUD, o "Toca aqui" e as telas viram cenas editáveis no editor do Godot. Estilos (painéis, rótulos, barras) saem de `Hud.estilo()`/`Hud.rotulo()` e vão para um `Theme` único.

**Tech Stack:** Godot 4.5.1 (GDScript, GL Compatibility), Python 3 + Pillow 12 + NumPy para gerar os sprites que faltam.

**Spec:** não há documento separado; o pedido é "separar lógica e visual usando os assets corretos" (conversa de 2026-11-03). O inventário abaixo é a base factual.

## Inventário (feito antes do plano)

**Assets que já existem e servem ampliados** (pixel art, filtro *nearest*): `objetos/tora.png` (24×16), `objetos/serra.png` (serra de dois cabos, 24×16), `extras/trator.png` (32×24), `extras/puca.png`, `extras/vara.png`, `extras/boia.png`, `extras/sombra_peixe.png`, `objetos/peixe.png`, `extras/balde_vazio.png`, `extras/balde_leite.png`, `objetos/poco.png`, `objetos/prego.png`, `objetos/martelo.png`, `personagens/vaca_mimosa.png`, `extras/capim.png`, `extras/coracao.png`, `estruturas/pier.png`, `tiles/agua.png`, `tiles/lama.png`, `tiles/grama.png`, `extras/pixel.png` e `extras/bolinha.png` (partículas), `extras/gota.png`, netos `p1_*`/`p2_*`.

**Sprites que faltam (13), gerados no mesmo estilo e paleta:**

| Arquivo | Tamanho | Uso |
|---|---|---|
| `objetos/tabua_quadrado.png`, `tabua_triangulo.png`, `tabua_circulo.png`, `tabua_losango.png` | 16×16 | Poço: tábuas na pilha e, com `modulate` escuro, os espaços vazios da tampa |
| `extras/tampa_poco.png` | 16×16, 9-slice com margem 4 | Poço: tampa de pedra (`NinePatchRect`) |
| `extras/moldura.png` | 16×16, 9-slice com margem 3, borda branca de 2 px | Cursor do poço e alvo da horta (`modulate` = cor do jogador) |
| `extras/trator_2.png` | 32×24 | Segundo quadro do trator com as rodas giradas |
| `extras/sombra.png` | 16×8, elipse preta com alfa 0.25 | Sombra de coletável, galinha, carga e netos do "Toca aqui" |
| `extras/circulo.png` | 24×24, disco branco | Estação: preenchimento (`modulate`) |
| `extras/anel.png` | 24×24, anel branco de 2 px | Estação: borda e carga (`TextureProgressBar` radial) |
| `extras/impacto.png` | 32×32, anel branco | "Toca aqui": onda do "PÁ!" (escala + alfa por animação) |
| `extras/estrela.png` | 16×16, estrela branca | "Toca aqui": brilhos |
| `extras/bandeirinha.png` | 16×16, triângulo branco | Festa: varal (`modulate` por cor) |

O que **não** precisa de asset: céu e faixas (`ColorRect`), linha de pesca (`Line2D`), barras (`ProgressBar` com estilo do tema), textos (`Label`), serragem/respingos/gotas (`CPUParticles2D` com `pixel.png`/`bolinha.png`).

## Global Constraints

- Godot **4.5.1** para trabalhar (versão em que o grupo já testou). O código deve continuar abrindo no **4.3**: nada de `Dictionary` tipado nem outro recurso de 4.4+. Não alterar `config/features` no `project.godot`.
- Comportamento do jogo **igual ao atual**: mesmas regras, números, textos, sons e ordem das tarefas. Os valores numéricos de cada regra estão na tarefa correspondente e saem do código atual.
- Nenhum `_draw()`/`draw_*` nos arquivos migrados. Exceção mantida: `scripts/telas/prefacio.gd` e `scripts/telas/paisagem.gd` (perspectiva e céu animado do prefácio/menu são efeito de câmera, não peça de cenário — fora do escopo).
- Texto, nomes de arquivos, nós e variáveis em português, como o resto do projeto.
- Cada cena tem os nós que o script usa marcados como **nome único** (`%Nome`) — o script nunca usa caminho tipo `$A/B/C`.
- Sprites novos saem de `ferramentas/gerar_assets_cenas.py` (script novo; o `gerar_assets.py` atual depende de uma pasta de sprites antigos que não está no repositório).
- Trabalhar no branch `refatoracao/cenas-e-assets`, um commit por tarefa. O repositório é do grupo: abrir PR por fase (Fases A–D abaixo), não um PR gigante.

## Review Focus

1. **Papéis trocados (jogador 2 no papel A).** As telas pintam cada papel com `Jogo.COR[na]`/`Jogo.COR[nb]`, nunca laranja/azul fixos. Teste em cada minijogo: instanciar com `na = 2, nb = 1` e conferir a cor do rótulo A.
2. **Recarregar a fazenda** (dormir, F1–F5). Com o mapa em `.tscn`, o estado do dia (poço consertado, trator, pedras, zonas cinza, cocho cheio) ainda tem que vir de `Jogo`. Teste: para cada dia via `Jogo.pular_para_dia(d)`, instanciar a fazenda e conferir esses estados.
3. **Foto do álbum.** `tirar_foto()` esconde o HUD e captura com o minijogo aberto; a cena nova do minijogo precisa continuar visível nessa hora. Coberto no checklist manual da Tarefa 14.
4. **Pausa.** O HUD roda com `PROCESS_MODE_ALWAYS`; as cenas novas de minijogo têm que continuar com o modo padrão (pausam junto). Teste na Tarefa 3.
5. **Apertos no mesmo quadro.** A regra recebe booleanos por quadro; dois jogadores apertando no mesmo quadro precisa dar o mesmo resultado de hoje (serra: o código atual processa A e depois B, então quem tem a vez corta, a vez passa e o outro também corta — **2 cortes**; Toca aqui: janela de 0,45 s). Testes nas Tarefas 5 e 12.

---

## Fase A — Base (Tarefas 1–3)

### Task 1: Ferramentas de teste e captura

**Files:**
- Create: `testes/caso_de_teste.gd`, `testes/rodar_testes.gd`, `testes/test_fumaca.gd`
- Create: `ferramentas/capturar_telas.gd`

**Interfaces:**
- Produces: `class_name CasoDeTeste extends RefCounted` com `afirmar(cond: bool, msg := "")`, `afirmar_igual(obtido, esperado, msg := "")`, `afirmar_perto(a: float, b: float, tol := 0.001)`. O executor roda todo método `test_*` de todo `testes/test_*.gd`.
- Produces: comando de teste `godot --headless --path . -s testes/rodar_testes.gd` → imprime `OK: <n> testes` e sai com código 0; com falha, imprime arquivo/método/mensagem e sai com 1.
- Produces: `ferramentas/capturar_telas.gd` (rodar **com janela**: `godot --path . -s ferramentas/capturar_telas.gd`) que abre cada minijogo sozinho (`fazenda = null`), espera 20 quadros e salva `capturas/<nome>.png`. Tem um dicionário `TELAS := {"trator": func(): return ...}` que cada tarefa de minijogo atualiza.

- [ ] **Step 1:** Instalar Godot 4.5.1 (download do release oficial no GitHub, `Godot_v4.5.1-stable_macos.universal.zip`) e criar o branch `refatoracao/cenas-e-assets`.
- [ ] **Step 2:** Importar os assets uma vez: `godot --headless --path . --import`. Esperado: termina sem `ERROR`.
- [ ] **Step 3:** Escrever `test_fumaca.gd` com `test_todas_as_cenas_carregam()`: para cada `.tscn` em `cenas/`, `load()` não é `null` e `instantiate()` não é `null`. Rodar o executor. Esperado: `OK: 1 testes`.
- [ ] **Step 4:** Rodar `capturar_telas.gd` e guardar `capturas/` (fora do git: adicionar `capturas/` ao `.gitignore`) como **referência visual de antes**.
- [ ] **Step 5:** Commit `test: executor de testes headless e captura das telas dos minijogos`.

### Task 2: Tema e sprites que faltam

**Files:**
- Create: `ferramentas/gerar_assets_cenas.py`, `assets/tema/tema_jogo.tres`, os 13 PNGs da tabela do inventário
- Test: `testes/test_assets.gd`

**Interfaces:**
- Produces: `tema_jogo.tres` aplicado como tema do projeto (`gui/theme/custom` no `project.godot`), com estas variações de tipo, valores copiados de `Hud.estilo()`/`Hud.rotulo()`:
  - `PainelMadeira` (`PanelContainer`): fundo `Color(0.42, 0.27, 0.14, 0.92)`, borda `Color(0.24, 0.15, 0.08)`, borda 2, raio 3, margens 6/3.
  - `PainelMinijogo` (`Panel`): fundo `Color(0.55, 0.78, 0.95)`, borda `Color(0.2, 0.15, 0.1)`, raio 8.
  - `Rotulo` (`Label`): contorno 3, cor do contorno `Color(0.1, 0.07, 0.05)`; `RotuloTitulo`: tamanho 14, cor `Color(1, 0.9, 0.5)`, contorno 4.
  - `BarraJogo` (`ProgressBar`): fundo `Color(0.3, 0.25, 0.2)`, borda `Color(0.15, 0.1, 0.06)` de 2 px, sem texto de porcentagem. A cor do preenchimento é definida por instância.
- Produces: os 13 PNGs, com a paleta copiada do topo de `gerar_assets.py` (`PRETO = (34, 32, 52, 255)` etc.).

- [ ] **Step 1:** Escrever `test_assets.gd` com `test_sprites_novos_existem_com_tamanho_certo()`: para cada linha da tabela, `load()` funciona e `get_size()` bate (ex.: `extras/trator_2.png` → `Vector2(32, 24)`). Rodar. Esperado: FAIL (arquivos não existem).
- [ ] **Step 2:** Escrever `gerar_assets_cenas.py` (uso: `python3 ferramentas/gerar_assets_cenas.py .`), gerar os PNGs e reimportar (`--import`).
- [ ] **Step 3:** Rodar o teste. Esperado: PASS. Abrir uma folha de contato dos PNGs novos ao lado dos antigos e conferir o estilo a olho.
- [ ] **Step 4:** Criar `tema_jogo.tres` e ligar no `project.godot`. Adicionar `test_tema_tem_variacoes()` (as 5 variações existem). Rodar. Esperado: PASS.
- [ ] **Step 5:** Commit `feat: tema do jogo e sprites para as cenas dos minijogos`.

### Task 3: Cena base dos minijogos

**Files:**
- Create: `cenas/minijogos/minijogo_base.tscn`
- Modify: `scripts/minijogos/minijogo.gd`
- Test: `testes/test_minijogo_base.gd`

**Interfaces:**
- Produces: `minijogo_base.tscn`, raiz `CanvasLayer` (layer 4) com `minijogo.gd`, e os nós únicos `%Fundo` (`ColorRect` `Color(0.05, 0.04, 0.08, 0.6)`), `%Painel` (`Panel` em `Rect2(40, 4, 560, 290)`, tema `PainelMinijogo`), `%Conteudo` (`Control` do tamanho do painel, `clip_contents = true`; **é aqui que cada minijogo põe seus nós**), `%Titulo`, `%Mensagem`, `%Faixa`, `%RotuloA`, `%RotuloB`.
- Produces: `minijogo.gd` mantém a API pública atual (`signal concluido`; `na`, `nb`, `dica`, `fazenda`, `tarefa`, `titulo`, `texto_a`, `texto_b`, `acabou`, `tempo`; `montar()`, `atualizar(delta)`, `mensagem()`, `erro()`, `acerto()`, `terminar()`). `_ready()` só preenche os nós da cena em vez de criá-los. Os ajudantes de desenho (`desenhar`, `texto_centro`, `textura`, `barra`, `_desenhar_painel`) **ficam até a Tarefa 8** e saem lá.
- Produces: em `tarefa.gd`, sem mudança de assinatura: `abrir_minijogo(mj: Minijogo)` recebe uma instância de cena.

- [ ] **Step 1:** `test_minijogo_base.gd`: `test_rotulos_usam_a_cor_de_cada_papel()` instancia a cena base com `na = 2, nb = 1`, `texto_a = "x"`, adiciona à árvore e confere que `%RotuloA` tem `font_color == Jogo.COR[2].lightened(0.35)` e texto `"Jogador 2: x"`. `test_pausa_para_o_minijogo()` confere `process_mode == PROCESS_MODE_INHERIT`. Rodar. Esperado: FAIL.
- [ ] **Step 2:** Criar a cena e adaptar `minijogo.gd`. Rodar. Esperado: PASS, e `test_fumaca` continua PASS.
- [ ] **Step 3:** Commit `refactor: cena base dos minijogos com nós em vez de desenho`.

**Fim da Fase A — abrir PR 1.**

---

## Fase B — Os cinco minijogos (Tarefas 4–8)

Padrão de todas as tarefas desta fase:

- `scripts/minijogos/regras/regra_<nome>.gd`: `class_name Regra<Nome> extends RefCounted`, sinais `acertou`, `errou(texto: String)`, `terminou(texto: String)`, um método `passo(delta: float, ...)` que recebe o controle **como booleanos/números** e atualiza o estado. Sem `Input`, `Jogo.apertou`, `Sons` nem nós.
- `cenas/minijogos/minijogo_<nome>.tscn`: herdada de `minijogo_base.tscn`, nós dentro de `%Conteudo`.
- `scripts/minijogos/minijogo_<nome>.gd`: cria a regra em `montar()`, liga `acertou → acerto()` + som, `errou → erro(texto)`, `terminou → terminar(texto)`; em `atualizar()` lê `Jogo.apertou/segurando/direcao`, chama `passo()` e copia o estado para os nós. Sem `desenhar()`.
- A tarefa troca `MinijogoX.new()` por `preload("res://cenas/minijogos/minijogo_x.tscn").instantiate()`.
- Ao fim de cada tarefa: atualizar `TELAS` em `capturar_telas.gd`, capturar e comparar com a referência de antes.

### Task 4: Trator (piloto — parar e mostrar ao grupo antes de seguir)

**Files:**
- Create: `scripts/minijogos/regras/regra_trator.gd`, `cenas/minijogos/minijogo_trator.tscn`
- Modify: `scripts/minijogos/minijogo_trator.gd`, `scripts/tarefas/tarefa_trator.gd:21`
- Test: `testes/test_regra_trator.gd`

**Interfaces:**
- Produces: `RegraTrator.passo(delta: float, acelerando: bool, empurrou: bool)`; estado `forca: float`, `girando: bool`. Valores do código atual: empurrão com acelerador `forca += 0.075`; empurrão sem acelerador → `errou("O trator está desligado! Acelera aí!")`; acelerando sem empurrão há mais de 1.2 s acumula tempo e a cada 2.2 s → `errou("Sozinho, a roda só gira! Empurra!")`; perda `0.04/s`; `forca >= 1.0` → `terminou("Saiu da lama!")`.
- Cena: `%Lama` (`TextureRect` tile com `tiles/lama.png`), `%Trator` (`AnimatedSprite2D` com `trator.png` e `trator_2.png`, escala 4), `%Empurrador` e `%Motorista` (netos, `p<n>_lado_parado.png`), `%Respingos` (`CPUParticles2D`), `%Forca` (`ProgressBar` `BarraJogo`, preenchimento `Color(0.95, 0.55, 0.2)`), `%Vrum` (`Label`).

- [ ] **Step 1:** Testes: `test_empurrar_com_acelerador_sobe_forca` (um passo com `true, true` → `forca ≈ 0.075` menos a perda do delta), `test_empurrar_sem_acelerador_da_erro` (sinal `errou` com o texto exato), `test_sozinho_por_muito_tempo_da_erro` (3.5 s de `true, false` → `errou` uma vez), `test_chega_a_um_e_termina`, `test_forca_cai_sem_ninguem`. Rodar. Esperado: FAIL.
- [ ] **Step 2:** Implementar a regra. Rodar. Esperado: PASS.
- [ ] **Step 3:** Montar a cena, reescrever `minijogo_trator.gd` como cola, trocar a criação em `tarefa_trator.gd`. Rodar todos os testes. Esperado: PASS.
- [ ] **Step 4:** Capturar e comparar com a referência. Jogar com F2 (os dois papéis, inclusive trocados).
- [ ] **Step 5:** Commit `refactor(trator): regra separada e cena com sprites`. **Mostrar ao grupo antes da Tarefa 5.**

### Task 5: Serra

**Files:** Create `regras/regra_serra.gd`, `cenas/minijogos/minijogo_serra.tscn`, `testes/test_regra_serra.gd`; Modify `minijogo_serra.gd`, `tarefa_lenha.gd:26`.

**Interfaces:**
- `RegraSerra.passo(delta: float, apertou_a: bool, apertou_b: bool)`; estado `vez: int` (0 = A), `cortes: int`, `travada: float`, `lado: float` (-1/1, para onde a serra foi puxada). Valores: `CORTES = 12`; aperto fora da vez → `travada = 0.7` e `errou("A serra agarrou! Um de cada vez.")`; apertos durante `travada > 0` são ignorados; `cortes >= 12` → `terminou("A tora está serrada!")`. A e B no mesmo quadro: processar A primeiro e depois B, como hoje (`for k in 2`).
- Cena: `%Tora` (`tora.png` escala 12), `%Corte` (`ColorRect` cuja altura = `66 * cortes / 12`), `%Serra` (`serra.png` escala 14, posição x = `lado * 34`), `%NetoA`, `%NetoB`, `%SetaVez` (`seta.png` com a cor de quem tem a vez), `%Serragem` (partículas), `%Progresso` (`BarraJogo`, `Color("eb8931")`), `%Contador` (`"%d de %d puxadas"`).

- [ ] **Step 1:** Testes: `test_alternar_conta_corte`, `test_fora_da_vez_trava`, `test_aperto_durante_travada_e_ignorado`, `test_os_dois_no_mesmo_quadro_contam_dois` (A tem a vez → A corta, a vez passa para B, B corta: 2 cortes e a vez volta para A — comportamento atual), `test_doze_cortes_termina`. Rodar: FAIL.
- [ ] **Step 2:** Implementar a regra → PASS. **Step 3:** Cena + cola + tarefa → todos PASS. **Step 4:** Captura + F1. **Step 5:** Commit `refactor(serra): regra separada e cena com sprites`.

### Task 6: Ordenha

**Files:** Create `regras/regra_ordenha.gd`, `cenas/minijogos/minijogo_ordenha.tscn`, `testes/test_regra_ordenha.gd`; Modify `minijogo_ordenha.gd`, `tarefa_animais.gd:76`.

**Interfaces:**
- `RegraOrdenha.passo(delta: float, dando_capim: bool, ordenhou: bool)`; estado `calma: float`, `leite: float`, `coice: float`. Valores: calma sobe `3.0/s` segurando e cai `1.5/s` soltando; ordenhar com `calma > 0.6` → `leite += 0.07` e `acertou`; senão `coice = 0.5` e `errou("A Mimosa não quer! Dá capim para ela.")`; `leite >= 1.0` → `terminou("Leite fresquinho!")`.
- Cena: `%Vaca` (escala 6, tremor quando `coice > 0`), `%NetoA` (virado), `%Capim` (visível segurando), `%NetoB`, `%Balde` (`TextureProgressBar` de baixo para cima: `under = balde_vazio.png`, `progress = balde_leite.png`), `%Gotas` (partículas brancas), `%Coracao` (alfa `0.4 + 0.6 * calma`), `%Calma` e `%Leite` (`BarraJogo`).

- [ ] **Step 1:** Testes: `test_sem_capim_da_coice`, `test_com_capim_tira_leite`, `test_calma_cai_ao_soltar`, `test_balde_cheio_termina`. FAIL. **Step 2:** Regra → PASS. **Step 3:** Cena + cola + tarefa → PASS. **Step 4:** Captura + F4. **Step 5:** Commit `refactor(ordenha): regra separada e cena com sprites`.

### Task 7: Pesca

**Files:** Create `regras/regra_pesca.gd`, `cenas/minijogos/minijogo_pesca.tscn`, `testes/test_regra_pesca.gd`; Modify `minijogo_pesca.gd`, `tarefa_pesca.gd:24`.

**Interfaces:**
- `RegraPesca.passo(delta: float, puxou: bool, mover_puca: float, pegou: bool)`; estado `estado: String` (`"esperando"`, `"fisgado"`, `"pulando"`), `dist`, `puca_x`, `peixe_x`, `pulo`, `pegos`. Valores: espera inicial 1.5 s e 1.2 s entre peixes; puxar `dist -= 0.07`; a linha volta `0.06/s`; `dist <= 0.22` → pula; janela do pulo 1.2 s; acerto se `|puca_x - peixe_x| < 30`; `puca_x` anda `170 * mover_puca * delta`, limitado a `[160, 540]`; `peixe_x = 190 + dist * 320 + sin(tempo * 2.3) * 26` (a regra guarda o próprio `tempo`); erro ou fim da janela → volta para `"fisgado"` com `dist = 0.45`; `META = 3` → `terminou("3 peixes! Que almoço!")`. Textos de erro: `"Errou! Siga a sombra do peixe."`, `"Ele voltou para a água!"`. Mensagens que não são erro (`"Fisgou! Puxa a linha!"`, `"Pulou! Pega com o puçá!"`, `"Pegou! Mais %d."`) saem por um quarto sinal `aviso(texto: String)`.
- Cena: `%Ceu` (`ColorRect`), `%Agua` (`TextureRect` tile `agua.png`), `%Pier` (fileira de `pier.png`), `%Pescador`, `%Vara`, `%Linha` (`Line2D` da ponta da vara até a boia/peixe), `%Boia`, `%Sombra`, `%Peixe`, `%Puca` (neto + `puca.png`), `%Placar` (3 `TextureRect` de peixe), `%Distancia` (`BarraJogo`, `Color(0.3, 0.5, 0.95)`).

- [ ] **Step 1:** Testes: `test_fisga_depois_da_espera`, `test_puxar_ate_pular`, `test_pegar_com_puca_alinhado`, `test_puca_longe_erra_e_volta_para_045`, `test_janela_do_pulo_expira`, `test_tres_peixes_termina`. FAIL. **Step 2:** Regra → PASS. **Step 3:** Cena + cola + tarefa → PASS. **Step 4:** Captura + F4. **Step 5:** Commit `refactor(pesca): regra separada e cena com sprites`.

### Task 8: Poço (o mais complexo) e limpeza da base

**Files:** Create `regras/regra_poco.gd`, `cenas/minijogos/minijogo_poco.tscn`, `testes/test_regra_poco.gd`; Modify `minijogo_poco.gd`, `tarefa_poco.gd:58`, `minijogo.gd` (remover os ajudantes de desenho).

**Interfaces:**
- `RegraPoco.new(vagas: Array, pilha: Array)` (a cola embaralha `FORMAS`; os testes passam ordens fixas). `passo(delta: float, a_esq: bool, a_dir: bool, a_acao: bool, b_acao: bool)`; estado `vagas`, `pilha` (`""` = usada), `pregos: Dictionary` (espaço → pregos que faltam), `cursor_pilha`, `cursor_vaga`, `segurando: String`, `vaga_pregando: int`, `marcador: float`. Valores: `PREGOS_POR_TABUA = 2`; `ZONA = 0.11` em volta de 0.5; marcador vai e volta a `0.8/s`. Mensagens de erro exatamente como em `minijogo_poco.gd` hoje (`"Espere o martelo pregar!"`, `"Essa já foi usada."`, `"Esse espaço já está pronto."`, `"Não é esse formato!"`, `"Errou o prego!"`). Avisos sem erro (`"Encaixou! Agora o martelo."`, `"Espere a tábua ser encaixada!"`) pelo sinal `aviso`. 4 espaços pregados → `terminou("Poço consertado!")`.
- Cena: `%Tampa` (`NinePatchRect` `tampa_poco.png`), `%Vagas` (4 `TextureRect` com `tabua_<forma>.png` escala 3: `modulate Color(0.12, 0.1, 0.1)` vazio, branco encaixado), `%Pregos` (2 `prego.png` por vaga), `%Pilha` (4 tábuas), `%CursorPilha` e `%CursorVaga` (`NinePatchRect` `moldura.png` na cor de `na`), `%TabuaNaMao`, `%Martelo` (`Sprite2D` `martelo.png` escala 3, girado `-0.9`/`0.4` rad), `%Batida` (`ProgressBar` com uma `ColorRect` filha para a zona do prego e outra para o marcador na cor de `nb`), `%Agora` (`Label`).

- [ ] **Step 1:** Testes: `test_encaixe_certo_libera_martelo`, `test_formato_errado_devolve_para_pilha`, `test_nao_pega_tabua_enquanto_prega`, `test_martelo_fora_da_zona_erra`, `test_dois_pregos_liberam_proxima_tabua`, `test_quatro_vagas_terminam`. FAIL.
- [ ] **Step 2:** Regra → PASS. **Step 3:** Cena + cola + tarefa → PASS. **Step 4:** Captura + F1.
- [ ] **Step 5:** Remover de `minijogo.gd` os métodos `desenhar`, `_desenhar_painel`, `texto_centro`, `textura` e `barra`. Conferir `rtk grep "draw_" scripts/minijogos` → nenhum resultado. Todos os testes PASS.
- [ ] **Step 6:** Commit `refactor(poco): regra separada e cena; base dos minijogos sem desenho`.

**Fim da Fase B — abrir PR 2.**

---

## Fase C — Mapa (Tarefas 9–11)

### Task 9: Peças do mapa (estação, carga, coletável)

**Files:** Create `cenas/objetos/estacao.tscn`, `carregar_juntos.tscn`, `coletavel.tscn`; Modify `scripts/estacao.gd`, `scripts/carregar_juntos.gd`, `scripts/coletavel.gd` e quem as cria (`fazenda.gd:_criar_tarefas`, `_criar_estacao_dormir`, `tarefa_poco.gd`, `tarefa_animais.gd`, `tarefa_lenha.gd`, `tarefa_colher.gd`); Test `testes/test_pecas_mapa.gd`.

**Interfaces:**
- `estacao.tscn`: `%CirculoA`/`%CirculoB` (`circulo.png` + `anel.png` a ±18 px), `%IconeA`/`%IconeB`, `%TextoA`/`%TextoB`/`%TextoUnico` (`Label` tamanho 7), `%Carga` (`TextureProgressBar` radial com `anel.png`). Sinal e propriedades públicas iguais (`prontos`, `papel_a`, `papel_b`, `icone_a`, `icone_b`, `sugerir`, `ativa`). Carga em 0,6 s; volta a `2.0/s`.
- `carregar_juntos.tscn`: `%Sombra` (`sombra.png`), `%Objeto` (`Sprite2D`, textura passada por `configurar()`), `%MaoA`/`%MaoB` (`bolinha.png` nas cores 1 e 2), `%Dica` (`"os dois: AÇÃO"`), `%Destino` (`ColorRect` piscando). `configurar()` mantém a assinatura e retorna `self`. Valores: `PERTO = 28`, `DISTANCIA_MAXIMA = 64`, janela 0,6 s.
- `coletavel.tscn`: `%Sombra`, `%Item`, `%Dica`. `configurar()` mantém a assinatura.
- Criação: `preload("res://cenas/objetos/<x>.tscn").instantiate()`.

- [ ] **Step 1:** Testes de lógica que hoje não existem: `test_estacao_dispara_com_dois_jogadores_em_circulos_diferentes` (dois `Jogador` falsos em ±18 px, 0,7 s de processo → `prontos`), `test_estacao_nao_dispara_com_um_so`, `test_carga_cai_se_os_dois_se_afastam`, `test_coletavel_so_pega_com_mao_livre`. Rodar contra o código **atual**: PASS (os testes protegem o comportamento antes da troca).
- [ ] **Step 2:** Criar as cenas, tirar `_draw()` dos três scripts, trocar a criação. Rodar: PASS. Jogar com F1 e F5 (tora e jerimum).
- [ ] **Step 3:** Commit `refactor: estação, carga e coletável como cenas`.

### Task 10: Personagens e horta

**Files:** Create `assets/animacoes/neto_1.tres`, `neto_2.tres`, `galinha.tres`, `cenas/objetos/galinha.tscn`, `trator_dirigivel.tscn`, `horta.tscn`; Modify `scripts/jogador.gd`, `cenas/jogador.tscn`, `scripts/galinha.gd`, `scripts/trator_dirigivel.gd`, `scripts/horta.gd`, `fazenda.gd`, `tarefa_arar.gd`; Test `testes/test_horta.gd`, `testes/test_galinha.gd`.

**Interfaces:**
- `jogador.gd`: `_montar_animacoes()` sai; as animações vão para `neto_<n>.tres` (`SpriteFrames` com as mesmas animações e quadros) e o jogador carrega `load("res://assets/animacoes/neto_%d.tres" % numero)`.
- `galinha.tscn`: `AnimatedSprite2D` com `galinha.tres`, `%Sombra`, `%Coracao` (visível em `CERCADA`). Constantes iguais.
- `trator_dirigivel.tscn`: `AnimatedSprite2D` (`trator.png`/`trator_2.png`), `%Cabeca`, `%Alerta` (`Label` `"!"` visível quando `bloqueado`).
- `horta.tscn`: **12 instâncias de `cenas/objetos/cova.tscn`** posicionadas nas `COLUNAS = [4, 6, 8, 10]` × `LINHAS = [15, 17, 19]` (centro `(c*16+8, l*16+8)`), cada uma com `%Planta`, `%Mato`, `%Sede` (`gota.png`), `%Brilho`, `%Alvo` (`moldura.png`). `horta.gd` mantém `centro()`, `tipo()`, `cova()`, `cova_perto()`, `atualizar_chao()`, `alvos`, `mostrar_sede`, e ganha `atualizar_covas()`, que copia `Jogo.horta[i]` para cada cova.

- [ ] **Step 1:** Testes de proteção contra o código atual: `test_cova_perto_acha_a_mais_proxima_dentro_de_13px`, `test_tipo_por_fileira` (0–3 milho, 4–7 feijão, 8–11 jerimum), `test_galinha_sozinha_foge` e `test_galinha_com_dois_perto_fica_cercada`. PASS.
- [ ] **Step 2:** Migrar os quatro. Teste novo `test_cova_mostra_a_fase_certa` (fase 3 de milho → `%Planta.texture` = `milho_fase2.png`). Todos PASS. Jogar F2 (arar), F3 (plantar e galinhas), F4 (cuidar da horta).
- [ ] **Step 3:** Commit `refactor: netos, galinha, trator e horta como cenas`.

### Task 11: A fazenda como cena

**Files:** Create `ferramentas/exportar_fazenda.gd` (roda uma vez); Modify `cenas/fazenda.tscn` (passa a ter o mapa todo), `scripts/fazenda.gd` (sai `MAPA` e tudo de `_montar_chao`, `_montar_construcoes`, `_sprite`, `_parede`, `_cerca_h`, `_cerca_v`, `_montar_zonas`); Test `testes/test_fazenda.gd`.

**Interfaces:**
- `exportar_fazenda.gd` (`extends SceneTree`): instancia a fazenda **atual**, roda as funções de montagem com `Jogo.novo_jogo()`, marca `owner` em todos os nós e salva com `PackedScene.pack()` + `ResourceSaver.save()`. Depois de rodar, o arquivo é apagado. Assim o mapa sai idêntico ao de hoje sem ser redesenhado à mão.
- `fazenda.tscn` resultante: `%Chao` (`TileMapLayer` com o atlas e o `MAPA` pintado), `%Mundo` com `Casa`, `Arvores`, `Galpao`, `Galinheiro`, `Poco`, `Cercas`, `Curral`, `Vaca`, `Cocho`, `Bebedouro`, `Porteira`, `Pier`, `Paredes` e `Vovo`; `%Zonas` com um `ColorRect` cinza por nome de `Lugares.ZONAS`; `%Seta`; `%Fumaca`; `%PilhaLenha`; `Hud` (ainda criado por código até a Tarefa 12).
- `fazenda.gd` fica só com a ordem das coisas e o estado do dia: `_aplicar_estado_do_dia()` lê `Jogo` e ajusta textura do poço, cocho/bebedouro, trator atolado/parado, pedras, galinhas, campo arado (atlas 2 vs 7 nas células `c`), zonas já coloridas (`queue_free`), fumaça e lenha.
- `lugares.gd` **continua** como fonte das posições usadas pela lógica (estações, destinos, áreas). As posições dos nós de cenário na cena têm que bater com ele (teste abaixo).
- `LEIAME.md`: a linha "O chão do mapa (está escrito como texto)" passa a apontar para "abrir `cenas/fazenda.tscn` e pintar no `Chao`".

- [ ] **Step 1:** Testes: `test_cenario_bate_com_lugares` (`Casa.position == Lugares.CASA`, `Poco.position == Lugares.POCO`, `Galpao`, `Galinheiro`, `Porteira`, `Vaca`, `Cocho`, `Bebedouro`), `test_chao_tem_os_blocos_do_mapa` (quantidade de células de água, lama, caminho e campo igual à contagem no `MAPA` atual: copiar os números da contagem antes de apagar), `test_estado_de_cada_dia` (para `d` de 1 a 5: `Jogo.pular_para_dia(d)`, instanciar, conferir pedras = 6 só antes do arar, trator atolado só no dia ≤ 2, zonas coloridas = `Jogo.zonas_coloridas()`). Rodar contra o código atual adaptando o acesso aos nós: o 3º deve passar já; os dois primeiros falham.
- [ ] **Step 2:** Rodar `exportar_fazenda.gd`, limpar `fazenda.gd`. Todos os testes PASS.
- [ ] **Step 3:** Jogar o dia 1 inteiro até dormir e conferir que o dia 2 abre certo. F1–F5.
- [ ] **Step 4:** Commit `refactor: mapa da fazenda em cena editável`.

**Fim da Fase C — abrir PR 3.**

---

## Fase D — HUD e telas (Tarefas 12–14)

### Task 12: HUD e "Toca aqui"

**Files:** Create `cenas/hud.tscn`, `cenas/toca_aqui.tscn`, `scripts/telas/regra_toca_aqui.gd`; Modify `scripts/hud.gd`, `scripts/telas/toca_aqui.gd`, `scripts/fazenda.gd` (instanciar as cenas), todos os usos de `Hud.estilo()`/`Hud.rotulo()` (`rtk grep "Hud\.\(estilo\|rotulo\)" scripts`); Test `testes/test_toca_aqui.gd`, `testes/test_hud.gd`.

**Interfaces:**
- `hud.tscn`: `%Quadro` (`PainelMadeira` + `VBoxContainer`), `%Cesta`, `%Balao` + `%TextoBalao` + `%DicaAcao`, `%Aviso`, `%Cortina` + `%TituloDia` + `%SubDia`, `%Pausa`. Os métodos públicos não mudam: `falar`, `conversa`, `aviso`, `mostrar_dia`, `escurecer`, `mostrar_topo`, `atualizar`. `estilo()` e `rotulo()` são **removidos**; quem usava passa a usar as variações do tema.
- `RegraTocaAqui.passo(agora: float, apertou_1: bool, apertou_2: bool) -> bool` (true quando os dois apertos ficam a menos de `JANELA = 0.45` s).
- `toca_aqui.tscn`: os dois netos (`AnimatedSprite2D` escala 5), `%Sombra1`/`%Sombra2`, `%Impacto` (`impacto.png`), `%Estrelas` (`estrela.png`), `%Pa` (`Label` "PÁ!"), `%Confete`, `%Titulo`, `%Sub`, e um `AnimationPlayer` com a animação `toque` nos tempos atuais: correr 0,40 s, subir 0,62 s, segurar 0,80 s, descer 1,00 s, fim 2,30 s. O sinal `pronto` sai no fim da animação.

- [ ] **Step 1:** Testes: `test_toca_aqui_aceita_dentro_da_janela` (0,30 s → true), `test_toca_aqui_recusa_fora` (0,50 s → false), `test_mesmo_quadro_conta` (os dois `true` no mesmo `passo` → true), `test_hud_aviso_mostra_texto`. FAIL.
- [ ] **Step 2:** Regra + cenas + troca dos usos de `Hud.estilo/rotulo`. Todos PASS. Conferir `rtk grep "draw_" scripts/hud.gd scripts/telas/toca_aqui.gd` → nada.
- [ ] **Step 3:** Jogar uma tarefa até o fim: balão, aviso, "Toca aqui" com animação, foto, pausa com Esc.
- [ ] **Step 4:** Commit `refactor: HUD e toca aqui como cenas com tema`.

### Task 13: Festa, tela inicial e menu

**Files:** Modify `cenas/festa.tscn`, `cenas/tela_inicial.tscn`, `cenas/menu_principal.tscn` e os scripts `festa.gd`, `tela_inicial.gd`, `menu_principal.gd`; Test `testes/test_telas.gd`.

**Interfaces:**
- Festa: `%Mesa` (`mesa.png`), `%Varal` com bandeirinhas (`bandeirinha.png` com `modulate` alternado), `%Cesta` (um ícone + `Label` por item de `Jogo.ITENS`), `%Album` (`TextureRect` + `%Legenda`). Lógica do álbum igual.
- Tela inicial: os dois cartões viram uma cena `cenas/objetos/cartao_jogador.tscn` instanciada duas vezes (`numero`, `andar`, `acao`).
- Menu: a caixa de opções usa o tema (`PainelMadeira` com borda dourada `Color(0.62, 0.45, 0.14)`); o vaga-lume é um `AnimatedSprite2D` (`vagalume1/2.png`) com `PointLight2D` ou um `Sprite2D` `bolinha.png` para o brilho; o fundo continua sendo `paisagem.gd` (fora do escopo).

- [ ] **Step 1:** Teste `test_festa_mostra_um_item_por_tipo_da_cesta` (com `Jogo.cesta` preenchida, a cena tem 7 itens com as quantidades certas) e `test_album_tem_uma_foto_por_tarefa`. Rodar contra o atual adaptando o acesso: o segundo passa.
- [ ] **Step 2:** Migrar as três. Todos PASS. Abrir o menu, ver Prefácio/Como jogar/Créditos, começar, F5, levar o jerimum e ver a festa até voltar ao menu.
- [ ] **Step 3:** Commit `refactor: festa, tela inicial e menu como cenas`.

### Task 14: Documentação e conferência final

**Files:** Modify `LEIAME.md` (tabelas "Onde mexer" e "Pastas"); Create `docs/arquitetura.md` (uma página: regra → cena → cola, com o Trator de exemplo).

- [ ] **Step 1:** Atualizar o LEIAME: minijogo = `cenas/minijogos/*.tscn` (visual) + `scripts/minijogos/regras/*.gd` (regra); mapa = `cenas/fazenda.tscn`; estilo = `assets/tema/tema_jogo.tres`; sprites novos = `ferramentas/gerar_assets_cenas.py`.
- [ ] **Step 2:** Conferência: `rtk grep "draw_\|_draw()" scripts` → só `prefacio.gd` e `paisagem.gd`. Todos os testes PASS.
- [ ] **Step 3:** Jogo completo, do menu à festa, sem F1–F5, uma vez com o jogador 1 sempre no papel A e outra aceitando as sugestões de troca. Conferir as 10 fotos do álbum (cada minijogo aparece na foto).
- [ ] **Step 4:** Abrir `godot` 4.3 (se alguém do grupo tiver) e confirmar que o projeto abre e roda.
- [ ] **Step 5:** Commit `docs: onde mexer depois da refatoração`. **Fim da Fase D — abrir PR 4.**

---

## Estimativa

| Fase | Tarefas | Dev humano (dias úteis) | Executando comigo |
|---|---|---|---|
| A — Base | 1–3 | 1 | 1 sessão |
| B — Minijogos | 4–8 | 3 a 4 | 2 sessões (+ pausa no piloto) |
| C — Mapa | 9–11 | 2 a 3 | 1 a 2 sessões |
| D — HUD e telas | 12–14 | 2 | 1 sessão |
| **Total** | 14 | **8 a 10 dias** | **~5 sessões** + o teste jogado de vocês |

O que mais pode atrasar: o estilo dos 13 sprites novos (é arte, pode pedir mais de uma rodada), a Tarefa 11 se o `exportar_fazenda.gd` não salvar algum nó criado em código, e conflitos se outra pessoa do grupo mexer nos mesmos scripts durante a refatoração.
