extends CharacterBody2D

# Constants for enemy behavior
const SPEED = 150.0  # Walking speed for patrolling or chasing
const ATTACK_RANGE = 80.0  # Distance to trigger an attack
const ATTACK_COOLDOWN = 1.5  # Cooldown time between attacks
const MAX_HEALTH = 100  # Maximum health for the Minotaur

@onready var ap = $AnimationPlayer  # AnimationPlayer for animations
@onready var hitbox = $CollisionShape2D  # Physical collision shape
@onready var attack_timer = $Timer  # Timer for attack cooldown
@onready var player_detector = $Area2D  # Area2D for detecting the player

# Variables for enemy behavior
var health = MAX_HEALTH
var is_attacking = false  # Whether the Minotaur is currently attacking
var is_dead = false  # Whether the Minotaur is dead
var direction = -1  # Movement direction (-1 for left, 1 for right)
var target_player = null  # Tracks the player for chasing/attacking

func _ready():
	# Connect signals for Area2D and Timer
	player_detector.body_entered.connect(_on_area_2d_body_entered)
	player_detector.body_exited.connect(_on_area_2d_body_exited)
	attack_timer.timeout.connect(_on_timer_timeout)

func _physics_process(delta: float) -> void:
	# Stop all behavior if the Minotaur is dead
	if is_dead:
		return

	# If attacking, stop movement and play attack animation
	if is_attacking:
		velocity.x = 0  # Stop movement while attacking
		ap.play("attack")
		return

	# Patrol or chase the player based on the state
	if target_player:
		chase_player(delta)
	else:
		patrol(delta)

	# Apply movement
	velocity.x = direction * SPEED
	move_and_slide()

	# Update animations (idle or walk)
	if velocity.x != 0:
		ap.play("walk")
	else:
		ap.play("idle")

# Patrol logic (walking back and forth)
func patrol(_delta: float) -> void:  # '_delta' suppresses unused parameter warnings
	if is_on_wall():
		direction *= -1  # Reverse direction on wall collision
		flip_sprite()

# Chase logic (moving toward the player)
func chase_player(_delta: float) -> void:  # '_delta' suppresses unused parameter warnings
	if target_player:
		# Determine the direction to the player (left or right)
		direction = 1 if target_player.global_position.x > global_position.x else -1
		flip_sprite()

		# Check attack range
		var distance_to_player = target_player.global_position.distance_to(global_position)
		if distance_to_player <= ATTACK_RANGE and not is_attacking:
			start_attack()

# Attack logic (triggered when player is in range)
func start_attack():
	if not is_attacking:  # Ensure only one attack at a time
		is_attacking = true
		attack_timer.start(ATTACK_COOLDOWN)  # Start cooldown timer
		ap.play("attack")  # Play attack animation

# Timer timeout logic (resets attack state)
func _on_timer_timeout():
	is_attacking = false  # Reset attack state after cooldown

# Flip the sprite direction based on movement direction
func flip_sprite():
	$Sprite2D.flip_h = (direction < 0)

# Signal triggered when the player enters the detection area
func _on_area_2d_body_entered(body):
	if body.name == "Player":  # Ensure the detected body is the player
		target_player = body  # Set the player as the target
		print("Player detected! Engaging target.")

# Signal triggered when the player leaves the detection area
func _on_area_2d_body_exited(body):
	if body.name == "Player":  # Reset state if the player leaves the area
		target_player = null
		is_attacking = false  # Stop attacking
		print("Player left detection area.")

# Damage logic (reduces health and handles death)
func take_damage(damage: int) -> void:
	if is_dead:  # Ignore damage if already dead
		return

	health -= damage
	if health <= 0:
		die()
	else:
		ap.play("hit")  # Optional hit animation

# Death logic (disables the enemy and plays animation)
func die():
	is_dead = true  # Mark enemy as dead
	velocity = Vector2.ZERO  # Stop movement
	ap.play("dead")  # Play dead animation
	hitbox.disabled = true  # Disable collision
	queue_free()  # Remove the enemy from the scene
