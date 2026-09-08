## defense_level_data.gd
##
## Configuração de um nível da mecânica Tower Defense (GDD seção 5-B,
## versão 2.0) — o equivalente do antigo `level_data.gd`, mas para o novo
## sistema. Um `Resource` só de dados: nenhum nó de cena, nada de Godot
## gráfico, pra poder ser montado e testado (test_defense_level_data_factory.gd)
## sem precisar de nenhuma cena.
##
## Ver `defense_level_data_factory.gd` para como cada nível (2, 3 e 4) é
## montado a partir disso.
class_name DefenseLevelData
extends Resource

@export var numero: int = 2
@export var nome: String = ""

## Quais defesas podem ser construídas neste nível — Array de
## DataTypes.Tipo (int/float/String/boolean/char) e, a partir do Nível 3,
## também TowerDefenseSystem.DEFESA_ERRO.
@export var tipos_disponiveis: Array = []

## tipo_defesa (int) -> custo em pontos pra construir uma torre desse tipo.
@export var custo_defesa: Dictionary = {}

## Slots de construção ao longo do caminho: Array de
## {"posicao": float 0.0-1.0, "alcance": float}.
@export var slots: Array = []

## Ondas de inimigos: Array de {"inimigos": Array de specs de inimigo, cada
## uma com "atraso" (segundos desde o início da onda) e os campos que
## `TowerDefenseSystem._spawnar_inimigo` espera (categoria, texto,
## defesa_correta, velocidade, pontos_recompensa, dano_escape}.
@export var ondas: Array = []

@export var pontos_iniciais: int = 300
