extends Node2D

const player = preload("res://Prefabs/player.tscn")
const poop = preload("res://Prefabs/poop.tscn")
const snatcher = preload("res://Prefabs/snatcher.tscn")
const dog = preload("res://Prefabs/dog.tscn")

const SPAWN_TIME = 1
const enemyList = [snatcher, dog]

var playerNode
var counter = 0
var mousePos = Vector2(-100, -100)
var spawnTimer = 1

# DEBUG variables
var debugCounter = 0
var fps = 0

func _ready():
	playerNode = get_node("player")
	playerNode.add_to_group("Entity")
	set_fixed_process(true)

func _fixed_process(delta):
	updateAI()
	updateEntities(delta)
	updateCrosshair()
	handleShooting(delta)
	spawnEnemies(delta)
	
	# DEBUG: show fps
	debugCounter += 1
	fps += 1 / delta
	if debugCounter > 15:
		fps /= debugCounter
		playerNode.get_node("debugLabel").set_text("FPS: " + str(fps) + "\nHP: " + str(playerNode.health))
		debugCounter = 0
		fps = 0

# Handle entity updating and movement
func updateEntities(delta):
	for entity in get_tree().get_nodes_in_group("Entity"):
		entity.update(delta)
		# TODO: change move for translate when using Area2D instead of Kinematic2D
		entity.translate(entity.velocity * delta)
		
# Set crosshair to mouse's position and make player look at crosshair's direction
func updateCrosshair():
	var crosshair = get_node("crosshair")
	mousePos = get_global_mouse_pos()
	crosshair.set_pos(mousePos)
	var lookDirection = crosshair.get_pos().x - playerNode.get_pos().x
	# Flip player if crosshair is behind
	playerNode.call("lookAt", lookDirection)

# If shooting is not on cooldown, shoot a projectile in the crosshair's direction
func handleShooting(delta):
	var playerPos = playerNode.get_pos()
	if counter < playerNode.cooldown:
		counter += delta
	elif Input.is_action_pressed("fire"):
		var shootDirection = (mousePos - playerPos).normalized()
		var poopNode = poop.instance()
		add_child(poopNode)
		var offset = shootDirection.normalized() * 35
		poopNode.set_pos(playerPos + offset)
		poopNode.call("setVelocity", shootDirection)
		counter = 0
		
func updateAI():
	# Inform enemies of player's current position
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		enemy.getPlayerPosition(playerNode.get_pos())
		
func spawnEnemies(delta):
	spawnTimer += delta
	if spawnTimer >= SPAWN_TIME:
		# Select a random spawn point and spawn an enemy
		spawnTimer = 0
		var spawnPoints = get_node("spawnPoints").get_children()
		var spawner = spawnPoints[randi() % spawnPoints.size()]
		var newEnemy = enemyList[randi() % enemyList.size()].instance()
		add_child(newEnemy)
		newEnemy.set_pos(spawner.get_pos())
		
# Returns a dict containing the coordinates of the top-left of the map
# and its dimensions
func calculate_bounds():
	var used_cells = get_used_cells()
	var min_x = used_cells[0].x
	var min_y = used_cells[0].y
	var max_x = min_x
	var max_y = min_y
	for pos in used_cells:
		if pos.x < min_x:
			min_x = int(pos.x)
		elif pos.x > max_x:
			max_x = int(pos.x)
		if pos.y < min_y:
			min_y = int(pos.y)
		elif pos.y > max_y:
			max_y = int(pos.y)
	return {
		x = min_x,
		y = min_y,
		width = max_x - min_x + 1,
		height = max_y - min_y + 1
    	}

