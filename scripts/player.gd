extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var velocity = Vector2.ZERO

func _physics_process(delta):
	# 处理移动输入
	var input_dir = Input.get_axis("ui_left", "ui_right")
	velocity.x = input_dir * SPEED
	
	# 处理跳跃
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# 应用重力
	velocity.y += gravity * delta
	
	# 移动角色
	move_and_slide()
