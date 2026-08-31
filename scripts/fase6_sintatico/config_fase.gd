extends Resource
class_name ConfigFase

@export var expressao_objetivo: Array[String] = ["x", "=", "20", "+", "5"]
@export var rotulo_fase: String = "Fase 1/3"
@export_file("*.tres") var proxima_fase_config_path: String = ""

## --- Configuração do spawner de balões ---
@export var intervalo_spawn: float = 1.4
@export_range(0.0, 1.0) var chance_token_correto: float = 0.45
@export_range(0.0, 1.0) var vies_mesmo_tipo: float = 0.75
@export var paleta_cores: Array[Color] = [Color(0.55, 0.6, 0.75)]

## --- Novas Mecânicas (Planejamento) ---
@export_range(0.0, 1.0) var chance_balao_fortificado: float = 0.0

## Marca se esta fase é a batalha contra o balão gigante
@export var inicia_com_chefe: bool = false
