class_name Textos
## TODO o texto que a Vovó fala durante o jogo, num lugar só.
## Regra para escrever (o jogo é para crianças de 10 anos):
##   - frases curtas (até umas 8 palavras), uma ideia por frase;
##   - falar com os dois ("vocês"), verbo no começo: "Levem", "Cerquem";
##   - nada de explicar controle por escrito: a tela mostra a tecla.

## O que a Vovó fala quando cada dia começa (uma fala por vez, AÇÃO passa).
const FALAS_DO_DIA := {
	1: ["Oi, meus netos! Que bom que vieram!",
		"O poço quebrou. E o fogão está sem lenha.",
		"Sigam a setinha amarela!",
		"Cada um num círculo, e a tarefa começa."],
	2: ["Bom dia! O trator atolou na lama.",
		"E o campo está cheio de pedras."],
	3: ["Hoje é dia de plantar!",
		"E as galinhas fugiram. Cerquem juntos!"],
	4: ["As galinhas botaram ovos!",
		"Tem bicho com fome e peixe no lago."],
	5: ["Hoje é a Festa da Colheita!",
		"Colham tudo e levem o jerimum gigante!"],
}

## O que a Vovó fala quando uma tarefa termina.
const ELOGIOS := {
	"poco": "Poço consertado! Tem água de novo!",
	"lenha": "O fogão acendeu! Vou fazer bolo!",
	"trator": "O trator saiu! Que força!",
	"arar": "Terra arada! Amanhã a gente planta.",
	"plantar": "Tudo plantado! Logo, logo cresce.",
	"galinhas": "Galinhas em casa! Obrigada, meus amores!",
	"animais": "A Mimosa está feliz! Tem leite!",
	"pesca": "Que peixes bonitos!",
	"cuidar_horta": "A horta está linda!",
}

## Créditos: quem fez o jogo.
# TODO grupo: completar nomes e papéis (ex.: ["Fulana", "programação"]).
## Quando todas as tarefas do dia acabam.
const HORA_DE_DORMIR := "Tudo pronto! Os dois na porta, para dormir."

const CREDITOS_EQUIPE := [
	["Nicolas Simões", ""],
	["Lucas Braide", ""],
]
