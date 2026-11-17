class_name Textos
## TODO o texto que a Vovó fala durante o jogo, num lugar só.
## Regra para escrever (o jogo é para crianças de 10 anos):
##   - frases curtas (até umas 8 palavras), uma ideia por frase;
##   - falar com os dois ("vocês"), verbo no começo: "Levem", "Cerquem";
##   - nada de explicar controle por escrito: a tela mostra a tecla.

## O que a Vovó fala quando cada dia começa (uma fala por vez, AÇÃO passa).
## Ordem: quanto falta para a festa -> o problema -> por que importa -> onde ir.
const FALAS_DO_DIA := {
	1: ["Oi, meus netos! Que bom que vieram!",
		"O poço quebrou e o fogão está sem lenha.",
		"Para o poço, achem a corda e as tábuas.",
		"A setinha amarela mostra o caminho.",
		"Cada um num círculo, e a tarefa começa!"],
	2: ["Bom dia! Faltam 4 dias para a festa!",
		"O trator atolou na lama, perto do galpão.",
		"Sem trator, não dá para afofar a terra.",
		"Primeiro o trator. Depois, a terra!"],
	3: ["Bom dia! Faltam 3 dias para a festa!",
		"A terra está pronta. Hora de plantar!",
		"E as galinhas fugiram do cercado.",
		"Sozinho, ela foge. Cerquem juntos!"],
	4: ["Faltam 2 dias! As galinhas botaram ovos!",
		"A Mimosa está com fome e sede.",
		"O lago tem peixe para o almoço da festa.",
		"E a horta precisa de água e cuidado.",
		"Escolham por onde começar!"],
	5: ["Hoje é a Festa da Colheita!",
		"Tudo cresceu graças a vocês dois!",
		"Colham a horta e levem o jerimum gigante.",
		"A festa começa lá na porteira!"],
}

## O que a Vovó fala quando uma tarefa termina: o elogio + a cor que voltou.
const ELOGIOS := {
	"poco": "Poço consertado! O quintal ganhou cor!",
	"lenha": "Fogão aceso! A casa e a mata ganharam cor!",
	"trator": "O trator saiu! O galpão ganhou cor!",
	"arar": "Terra afofada! O campo ganhou cor!",
	"plantar": "Tudo plantado! Amanhã vai ter broto.",
	"galinhas": "Galinhas em casa! O galinheiro ganhou cor!",
	"animais": "Mimosa feliz! O curral ganhou cor!",
	"pesca": "Que peixes! O lago ganhou cor!",
	"cuidar_horta": "A horta está linda! Amanhã é colheita!",
}

## Cartão de missão (cenas/objetos/cartao_missao.tscn), antes de cada tarefa.
##   porque = o problema, na voz da Vovó;
##   a / b  = o que faz quem está no círculo da esquerda / da direita;
##   depois = a segunda parte da tarefa, se tiver.
const MISSOES := {
	"poco": {"porque": "Sem poço, não tem água para nada!",
		"a": "Leve a tábua ao buraco do mesmo formato",
		"b": "Martele quando a barrinha estiver no prego",
		"teclas_a": "lados", "teclas_b": "acao"},
	"lenha": {"porque": "Sem lenha, o fogão não acende!",
		"a": "Puxe a serra quando for sua vez",
		"b": "Puxe a serra quando for sua vez",
		"teclas_a": "acao", "teclas_b": "acao",
		"depois": "Depois: levem o tronco juntos até a casa.",
		"imagem_depois": "res://assets/sprites/objetos/tora.png"},
	"trator": {"porque": "O trator atolou! Sem ele, nada de plantar.",
		"a": "SEGURE o botão para acelerar",
		"b": "APERTE muitas vezes para empurrar",
		"teclas_a": "acao", "gesto_a": "segure",
		"teclas_b": "acao", "gesto_b": "várias vezes"},
	"arar": {"porque": "Terra dura e com pedra não deixa plantar.",
		"a": "Dirija o trator por todo o campo",
		"b": "Tire as pedras da frente do trator"},
	"plantar": {"porque": "Milho, feijão e jerimum para a festa!",
		"a": "Ponha a semente em cada buraco",
		"b": "Regue onde já tem semente"},
	"galinhas": {"porque": "As galinhas fugiram! Sozinho, ninguém pega.",
		"a": "Cheguem juntos perto da galinha",
		"b": "Cheguem juntos perto da galinha",
		"depois": "Ela fica calma e segue vocês até o cercado.",
		"imagem": "res://assets/sprites/personagens/galinha_1.png"},
	"animais": {"porque": "A Mimosa está com fome e sede.",
		"a": "Traga o saco de milho do galpão",
		"b": "Traga o balde de água do poço",
		"depois": "Depois: um dá capim, o outro tira o leite.",
		"imagem": "res://assets/sprites/personagens/vaca_mimosa.png",
		"imagem_depois": "res://assets/sprites/extras/balde_leite.png"},
	"pesca": {"porque": "Peixe fresco para o almoço da festa!",
		"a": "APERTE muitas vezes para puxar a linha",
		"b": "Fique na sombra. Pegue quando pular!",
		"teclas_a": "acao", "gesto_a": "várias vezes", "teclas_b": "lados",
		"imagem": "res://assets/sprites/objetos/peixe.png"},
	"cuidar_horta": {"porque": "As plantinhas estão com sede e com mato.",
		"a": "Regue onde aparece a gotinha",
		"b": "Arranque o mato das plantas"},
	"colher": {"porque": "Tudo maduro! Hora de colher.",
		"a": "Colha as plantas que brilham",
		"b": "Colha as plantas que brilham",
		"depois": "Depois: levem o jerimum gigante até a porteira!",
		"imagem_depois": "res://assets/sprites/objetos/jerimum_gigante.png"},
}

## Fim do dia: o que vem amanhã (antes de mandar dormir).
const NOITE := {
	1: "Que dia! Amanhã: o trator e o campo.",
	2: "Terra fofinha! Amanhã a gente planta.",
	3: "Amanhã tem bicho, peixe e horta!",
	4: "Amanhã é a festa! Descansem bem.",
}

## Créditos: quem fez o jogo.
# TODO grupo: completar nomes e papéis (ex.: ["Fulana", "programação"]).
## Quando todas as tarefas do dia acabam.
const HORA_DE_DORMIR := "Agora os dois na porta, para dormir."

const CREDITOS_EQUIPE := [
	["Nicolas Simões", ""],
	["Lucas Braide", ""],
	["Ravier Rodrigues", ""],
	["Vinícius Alexander", ""],
]
