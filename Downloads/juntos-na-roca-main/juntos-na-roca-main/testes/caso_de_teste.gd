class_name CasoDeTeste
extends RefCounted
## Base de todo arquivo de teste (testes/test_*.gd).
## O executor (testes/rodar_testes.gd) roda cada método que começa com "test_"
## e, no fim de cada um, olha a lista "falhas".

var falhas: Array[String] = []
var arvore: SceneTree   # preenchido pelo executor, para testes que precisam da árvore


func afirmar(cond: bool, msg := "") -> void:
	if not cond:
		falhas.append(msg if msg != "" else "afirmação falsa")


func afirmar_igual(obtido, esperado, msg := "") -> void:
	if typeof(obtido) != typeof(esperado) or obtido != esperado:
		var texto := "esperado %s, obtido %s" % [str(esperado), str(obtido)]
		falhas.append(texto if msg == "" else "%s (%s)" % [msg, texto])


func afirmar_perto(a: float, b: float, tol := 0.001, msg := "") -> void:
	if absf(a - b) > tol:
		var texto := "%f não está perto de %f (tolerância %f)" % [a, b, tol]
		falhas.append(texto if msg == "" else "%s (%s)" % [msg, texto])
