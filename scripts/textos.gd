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
		"Hoje tem dois consertos: o poço e a lenha.",
		"Para o poço, tragam a corda do galpão...",
		"...e as tábuas que estão lá na mata.",
		"A setinha amarela mostra o caminho.",
		"Cada um num círculo, e a tarefa começa!"],
	2: ["Bom dia! Faltam 4 dias para a festa!",
		"O trator atolou na lama, perto do galpão.",
		"Sem trator, não dá para arar o campo.",
		"Primeiro o trator. Depois, a terra!"],
	3: ["Bom dia! Faltam 3 dias para a festa!",
		"A terra está pronta. Hora de plantar!",
		"E as galinhas fugiram do cercado.",
		"Sozinho, ela foge. Cerquem juntos!"],
	4: ["Faltam 2 dias! As galinhas botaram ovos!",
		"A Mimosa está com fome e sede.",
		"O lago tem peixe para o almoço da festa.",
		"E a horta precisa de água e cuidado."],
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
	"arar": "Terra arada! O campo ganhou cor!",
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
		"a": "Encaixe cada tábua no buraco igual",
		"b": "Martele quando a marca passar no prego"},
	"lenha": {"porque": "Sem lenha, o fogão não acende!",
		"a": "Puxe a serra quando for sua vez",
		"b": "Puxe a serra quando for sua vez",
		"depois": "Depois: levem a tora juntos até a casa."},
	"trator": {"porque": "O trator atolou! Sem ele, nada de arar.",
		"a": "SEGURE o botão para acelerar",
		"b": "APERTE muitas vezes para empurrar"},
	"arar": {"porque": "Terra dura não deixa a semente crescer.",
		"a": "Dirija o trator por todo o campo",
		"b": "Tire as pedras da frente do trator"},
	"plantar": {"porque": "Milho, feijão e jerimum para a festa!",
		"a": "Ponha a semente em cada buraco",
		"b": "Regue onde já tem semente"},
	"galinhas": {"porque": "As galinhas fugiram! Sozinho, elas correm.",
		"a": "Chegue perto da galinha junto com o outro",
		"b": "Chegue perto da galinha junto com o outro",
		"depois": "Ela fica calma e segue vocês até o cercado."},
	"animais": {"porque": "A Mimosa está com fome e sede.",
		"a": "Traga o saco de milho do galpão",
		"b": "Traga o balde de água do poço",
		"depois": "Depois: um dá capim, o outro tira o leite."},
	"pesca": {"porque": "Peixe fresco para o almoço da festa!",
		"a": "Puxe a linha até o peixe pular",
		"b": "Siga a sombra e pegue com o puçá"},
	"cuidar_horta": {"porque": "As plantinhas estão com sede e com mato.",
		"a": "Regue onde aparece a gotinha",
		"b": "Arranque o mato das plantas"},
	"colher": {"porque": "Tudo maduro! Hora de colher.",
		"a": "Colha as plantas que brilham",
		"b": "Colha as plantas que brilham",
		"depois": "Depois: levem o jerimum gigante até a porteira!"},
}

## Fim do dia: o que vem amanhã (antes de mandar dormir).
const NOITE := {
	1: "Que dia! Amanhã: o trator e o campo.",
	2: "Campo arado! Amanhã a gente planta.",
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
]
