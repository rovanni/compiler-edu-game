extends Resource
class_name ConfigFase
## Dados que variam entre as sub-fases da Fase 6 (Main1/2/3 antigas).
## Um recurso (.tres) por fase — a cena Main.tscn é única e só lê estes
## valores, evitando duplicar toda a árvore de UI 3 vezes.

## Expressão-objetivo em tokens de alto nível (números multi-dígito são
## quebrados automaticamente em dígitos pelo GerenciadorExpressao).
@export var expressao_objetivo: Array[String] = ["x", "=", "20", "+", "5"]

## Texto exibido no canto (ex: "Fase 1/3").
@export var rotulo_fase: String = "Fase 1/3"

## Caminho do .tres da próxima fase (vazio = última fase, sem botão "Próxima fase").
@export_file("*.tres") var proxima_fase_config_path: String = ""

## --- Configuração do spawner de balões ---
@export var intervalo_spawn: float = 1.4
@export_range(0.0, 1.0) var chance_token_correto: float = 0.45
@export_range(0.0, 1.0) var vies_mesmo_tipo: float = 0.75
## Paleta de cores dos balões (estética/distração). 1 cor = todos iguais.
@export var paleta_cores: Array[Color] = [Color(0.55, 0.6, 0.75)]
