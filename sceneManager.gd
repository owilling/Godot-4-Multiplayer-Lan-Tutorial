extends Node2D

@export var playerScene : PackedScene

func _ready() -> void:
	var index = 0
	for i in gameManager.players:
		var currentPlayer = playerScene.instantiate()
		currentPlayer.name = str(gameManager.players[i].id)
		add_child(currentPlayer)
		for spawn in get_tree().get_nodes_in_group("playerSpawnPoint"):
			if spawn.name == str(index):
				currentPlayer.global_position = spawn.global_position
				
		index += 1
