extends Node
## Autoload (singleton) pequeno, exclusivo da Fase 6. Guarda qual
## ConfigFase deve ser usado da PRÓXIMA vez que Main.tscn entrar em
## _ready(). Existe só porque Main.tscn é reaproveitada por todas as
## sub-fases (Main1/2/3 antigas viraram apenas arquivos de dados .tres);
## ao avançar de fase, trocamos a config aqui antes de recarregar a cena.

var config_pendente: ConfigFase = null
var tutorial_fortificado_visto := false
var tutorial_chefe_visto := false
var execucao_ativa := false

## Uma execucao compreende tutorial + sub-fases 1, 2 e 3. Os avisos ficam
## memorizados entre reloads, mas voltam a aparecer em uma nova partida.
func iniciar_execucao() -> void:
	execucao_ativa = true
	config_pendente = null
	tutorial_fortificado_visto = false
	tutorial_chefe_visto = false

func encerrar_execucao() -> void:
	execucao_ativa = false
	config_pendente = null
	tutorial_fortificado_visto = false
	tutorial_chefe_visto = false

## Chamado por main.gd ao clicar em "Próxima fase".
func definir_proxima_config(config: ConfigFase) -> void:
	config_pendente = config

## Chamado por main.gd em _ready(): se houver uma config pendente, ela tem
## prioridade sobre a config fixada na cena/inspector, e é consumida (só
## vale para esta única carga da cena).
func consumir_config_pendente() -> ConfigFase:
	var c := config_pendente
	config_pendente = null
	return c
