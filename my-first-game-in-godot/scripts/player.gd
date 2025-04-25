extends CharacterBody2D

@export var speed = 300
@export var gravity = 500
@export var jump_force = -320
@export var wall_jump_force = Vector2(-400, -300)  # Horizontal and vertical force for wall jump
@export var max_wall_jumps = 2  # Maximum number of jumps allowed on the same wall

@onready var ap = $AnimationPlayer
@onready var sprite = $Sprite2D

var is_attacking = false  # Tracks if the character is currently attacking
var attack_index = 1      # Tracks the current attack animation (1, 2, or 3)
var wall_jump_count = 0   # Counts jumps performed on the same wall

func _ready():
	# Connect the animation_finished signal to handle attack completion
	ap.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_force  # Perform regular jump
			wall_jump_count = 0  # Reset wall jump count on landing
		elif is_on_wall():
			if wall_jump_count < max_wall_jumps:
				_perform_wall_jump()  # Perform wall jump
				wall_jump_count += 1  # Increment wall jump counter
		# No additional jump unless conditions are met

	# Handle horizontal movement
	var horizontal_direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = speed * horizontal_direction

	
	if horizontal_direction != 0:
		sprite.flip_h = (horizontal_direction < 0)  # Face left if moving left

	# Handle multiple attacks
	if Input.is_action_just_pressed("attack1") and not is_attacking:
		is_attacking = true
		_perform_attack()

	# Move the character
	move_and_slide()

	
	update_animations(horizontal_direction)


func update_animations(horizontal_direction):
	if is_attacking:
		if horizontal_direction != 0 and is_on_floor():
			ap.play("run_attack")  # Play running attack animation
		else:
			ap.play("attack")  # Play stationary attack animation
		return  # Skip other animations while attacking

	if is_on_floor():
		if horizontal_direction == 0:
			ap.play("idle")  # Play idle animation when stationary
		else:
			ap.play("run")  # Play running animation when moving
	else:
		if velocity.y < 0:
			ap.play("jump")  # Play jump animation when ascending
		elif velocity.y > 0:
			ap.play("fall")  # Play falling animation when descending

# Function to handle chaining multiple attacks
func _perform_attack():
	# Determine the current attack animation based on attack_index
	match attack_index:
		1:
			ap.play("attack1")  # Play first attack animation
		2:
			ap.play("attack2")  # Play second attack animation
		3:
			ap.play("attack3")  # Play third attack animation

	# Increment the attack index, looping back to 1 after 3
	attack_index += 1
	if attack_index > 3:
		attack_index = 1

# Function to handle wall jumps
func _perform_wall_jump():
	# Apply a wall jump force in the opposite direction of the wall
	velocity = wall_jump_force * Vector2(1 if sprite.flip_h else -1, 1)

func _on_animation_finished(anim_name: String):
	if anim_name in ["attack1", "attack2", "attack3", "run_attack"]:
		is_attacking = false
