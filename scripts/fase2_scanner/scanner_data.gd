extends RefCounted
class_name ScannerData

enum TokenKind { KEYWORD, IDENTIFIER, NUMBER, OPERATOR, SYMBOL }

static func challenges() -> Array[Dictionary]:
	return [
		{"id": 1, "title": "APRENDENDO O SCANNER", "source": "int x = 10;", "time_limit": 120.0,
		"hint": "O Scanner começa pela palavra reservada usada para declarar o tipo da variável.", "tokens": [
			_token("int", TokenKind.KEYWORD, "Palavra reservada utilizada para declarar uma variável inteira.", Vector2(510, 503)),
			_token("x", TokenKind.IDENTIFIER, "Nome utilizado para identificar uma variável.", Vector2(330, 264)),
			_token("=", TokenKind.OPERATOR, "Operador que atribui um valor à variável.", Vector2(1150, 293)),
			_token("10", TokenKind.NUMBER, "Valor numérico inteiro encontrado no código.", Vector2(835, 322)),
			_token(";", TokenKind.SYMBOL, "Símbolo que indica o final da instrução.", Vector2(1035, 540)),
		]},
		{"id": 2, "title": "SCANNER EM AÇÃO", "source": "if (x > 10) return x;", "time_limit": 180.0,
		"hint": "Leia o código da esquerda para a direita. Depois de if vem o símbolo que abre a condição.", "tokens": [
			_token("if", TokenKind.KEYWORD, "Palavra-chave que inicia uma estrutura condicional.", Vector2(650, 173)),
			_token("(", TokenKind.SYMBOL, "Símbolo que abre a condição do if.", Vector2(330, 264)),
			_token("x", TokenKind.IDENTIFIER, "Identificador usado na condição.", Vector2(1150, 293)),
			_token(">", TokenKind.OPERATOR, "Operador utilizado para realizar uma comparação.", Vector2(835, 322)),
			_token("10", TokenKind.NUMBER, "Valor numérico comparado com o identificador.", Vector2(510, 503)),
			_token(")", TokenKind.SYMBOL, "Símbolo que fecha a condição do if.", Vector2(1080, 542)),
			_token("return", TokenKind.KEYWORD, "Palavra-chave que devolve um valor.", Vector2(215, 510)),
			_token("x", TokenKind.IDENTIFIER, "Identificador cujo valor será devolvido.", Vector2(670, 503)),
			_token(";", TokenKind.SYMBOL, "Símbolo que encerra a instrução return.", Vector2(925, 444)),
		]},
	]

static func kind_color(kind: int) -> Color:
	match kind:
		TokenKind.KEYWORD: return Color("58a6ff")
		TokenKind.IDENTIFIER: return Color("6ee7a8")
		TokenKind.NUMBER: return Color("c084fc")
		TokenKind.OPERATOR: return Color("fbbf24")
		TokenKind.SYMBOL: return Color("fb7185")
	return Color.WHITE

static func kind_name(kind: int) -> String:
	match kind:
		TokenKind.KEYWORD: return "Palavra-chave"
		TokenKind.IDENTIFIER: return "Identificador"
		TokenKind.NUMBER: return "Número"
		TokenKind.OPERATOR: return "Operador"
		TokenKind.SYMBOL: return "Símbolo"
	return "Token"

static func kind_short(kind: int) -> String:
	match kind:
		TokenKind.KEYWORD: return "PAL"
		TokenKind.IDENTIFIER: return "ID"
		TokenKind.NUMBER: return "NUM"
		TokenKind.OPERATOR: return "OP"
		TokenKind.SYMBOL: return "SIM"
	return "?"

static func source_bbcode(tokens: Array) -> String:
	var parts: PackedStringArray = []
	for token in tokens:
		var color := kind_color(int(token["kind"]))
		parts.append("[color=#%s]%s[/color]" % [color.to_html(false), str(token["lexeme"])])
	return "[center][color=#ffc43d]CÓDIGO FONTE[/color]   %s[/center]" % " ".join(parts)

static func _token(lexeme: String, kind: int, explanation: String, position: Vector2) -> Dictionary:
	return {"lexeme": lexeme, "kind": kind, "explanation": explanation, "position": position}
