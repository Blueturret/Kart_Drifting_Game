extends Node
class_name GameManager

static var instance : GameManager

var checkPointsCollected : int = 0 ## The amount of checkpoints collected 

func _ready() -> void:
	
	if(GameManager.instance == null):
		instance = self
