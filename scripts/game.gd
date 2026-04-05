extends Node2D

const GRID_WIDTH = 10
const GRID_HEIGHT = 20
const CELL_SIZE = 30

var grid = []
var current_piece = null
var next_piece = null
var score = 0
var game_over = false
var game_started = false
var fall_timer = 0
var fall_speed = 0.5

# 方块的形状定义
var tetrominoes = [
    # I型
    [[1, 1, 1, 1]],
    # J型
    [[1, 0, 0], [1, 1, 1]],
    # L型
    [[0, 0, 1], [1, 1, 1]],
    # O型
    [[1, 1], [1, 1]],
    # S型
    [[0, 1, 1], [1, 1, 0]],
    # T型
    [[0, 1, 0], [1, 1, 1]],
    # Z型
    [[1, 1, 0], [0, 1, 1]]
]

# 方块的颜色
var tetromino_colors = [
    Color(0, 1, 1, 1),  # I型 - 青色
    Color(0, 0, 1, 1),    # J型 - 蓝色
    Color(1, 0.5, 0, 1),  # L型 - 橙色
    Color(1, 1, 0, 1),    # O型 - 黄色
    Color(0, 1, 0, 1),    # S型 - 绿色
    Color(0.5, 0, 0.5, 1), # T型 - 紫色
    Color(1, 0, 0, 1)     # Z型 - 红色
]

func _ready():
    # 初始化网格
    for y in range(GRID_HEIGHT):
        grid.append([])
        for x in range(GRID_WIDTH):
            grid[y].append(-1)
    
    # 连接开始按钮信号
    $StartButton.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
    # 开始游戏
    if not game_started:
        game_started = true
        game_over = false
        score = 0
        $ScoreLabel.text = "Score: 0"
        $GameOverLabel.visible = false
        
        # 初始化网格
        for y in range(GRID_HEIGHT):
            for x in range(GRID_WIDTH):
                grid[y][x] = -1
        
        # 生成初始方块
        current_piece = generate_piece()
        next_piece = generate_piece()
        
        # 清空现有方块
        clear_pieces()
        
        # 绘制当前方块
        draw_current_piece()
        
        # 绘制下一个方块
        draw_next_piece()

func _process(delta):
    if game_started and not game_over:
        fall_timer += delta
        if fall_timer >= fall_speed:
            fall_timer = 0
            move_piece_down()
    
    # 处理键盘输入
    if game_started and not game_over:
        if Input.is_action_just_pressed("ui_left"):
            move_piece_left()
        elif Input.is_action_just_pressed("ui_right"):
            move_piece_right()
        elif Input.is_action_just_pressed("ui_down"):
            move_piece_down()
        elif Input.is_action_just_pressed("ui_accept"):
            rotate_piece()

func generate_piece():
    var piece_index = randi() % tetrominoes.size()
    var piece = {
        "shape": tetrominoes[piece_index],
        "color": tetromino_colors[piece_index],
        "x": int(GRID_WIDTH / 2) - int(tetrominoes[piece_index][0].size() / 2),
        "y": 0
    }
    return piece

func clear_pieces():
    # 清除游戏区域内的所有方块
    for child in $GameArea.get_children():
        if child.name.begins_with("Cell"):
            child.queue_free()
    
    # 清除下一个方块区域内的所有方块
    for child in $NextPieceArea.get_children():
        if child.name.begins_with("NextCell"):
            child.queue_free()

func draw_current_piece():
    # 绘制当前方块
    var shape = current_piece["shape"]
    var color = current_piece["color"]
    var x = current_piece["x"]
    var y = current_piece["y"]
    
    for row in range(shape.size()):
        for col in range(shape[row].size()):
            if shape[row][col] == 1:
                var cell = ColorRect.new()
                cell.name = "Cell_{}_{}".format(y + row, x + col)
                cell.position = Vector2((x + col) * CELL_SIZE, (y + row) * CELL_SIZE)
                cell.size = Vector2(CELL_SIZE - 1, CELL_SIZE - 1)
                cell.color = color
                $GameArea.add_child(cell)

func draw_next_piece():
    # 绘制下一个方块
    var shape = next_piece["shape"]
    var color = next_piece["color"]
    
    # 清除现有方块
    for child in $NextPieceArea.get_children():
        if child.name.begins_with("NextCell"):
            child.queue_free()
    
    # 计算居中位置
    var offset_x = (200 - shape[0].size() * CELL_SIZE) / 2
    var offset_y = (200 - shape.size() * CELL_SIZE) / 2
    
    for row in range(shape.size()):
        for col in range(shape[row].size()):
            if shape[row][col] == 1:
                var cell = ColorRect.new()
                cell.name = "NextCell_{}_{}".format(row, col)
                cell.position = Vector2(offset_x + col * CELL_SIZE, offset_y + row * CELL_SIZE)
                cell.size = Vector2(CELL_SIZE - 1, CELL_SIZE - 1)
                cell.color = color
                $NextPieceArea.add_child(cell)

func move_piece_left():
    current_piece["x"] -= 1
    if check_collision():
        current_piece["x"] += 1
        return
    clear_pieces()
    draw_current_piece()
    draw_next_piece()

func move_piece_right():
    current_piece["x"] += 1
    if check_collision():
        current_piece["x"] -= 1
        return
    clear_pieces()
    draw_current_piece()
    draw_next_piece()

func move_piece_down():
    current_piece["y"] += 1
    if check_collision():
        current_piece["y"] -= 1
        lock_piece()
        check_lines()
        spawn_next_piece()
        return
    clear_pieces()
    draw_current_piece()
    draw_next_piece()

func rotate_piece():
    var shape = current_piece["shape"]
    var rotated_shape = []
    
    # 旋转矩阵
    for col in range(shape[0].size()):
        var new_row = []
        for row in range(shape.size() - 1, -1, -1):
            new_row.append(shape[row][col])
        rotated_shape.append(new_row)
    
    # 保存原始形状
    var original_shape = shape
    current_piece["shape"] = rotated_shape
    
    # 检查碰撞
    if check_collision():
        current_piece["shape"] = original_shape
        return
    
    clear_pieces()
    draw_current_piece()
    draw_next_piece()

func check_collision():
    var shape = current_piece["shape"]
    var x = current_piece["x"]
    var y = current_piece["y"]
    
    for row in range(shape.size()):
        for col in range(shape[row].size()):
            if shape[row][col] == 1:
                var grid_x = x + col
                var grid_y = y + row
                
                # 检查边界
                if grid_x < 0 or grid_x >= GRID_WIDTH or grid_y >= GRID_HEIGHT:
                    return true
                
                # 检查是否与已有方块碰撞
                if grid_y >= 0 and grid[grid_y][grid_x] != -1:
                    return true
    
    return false

func lock_piece():
    var shape = current_piece["shape"]
    var x = current_piece["x"]
    var y = current_piece["y"]
    
    for row in range(shape.size()):
        for col in range(shape[row].size()):
            if shape[row][col] == 1:
                var grid_x = x + col
                var grid_y = y + row
                
                if grid_y >= 0:
                    # 找到颜色索引
                    var color_index = tetromino_colors.find(current_piece["color"])
                    grid[grid_y][grid_x] = color_index

func check_lines():
    var lines_cleared = 0
    
    for y in range(GRID_HEIGHT - 1, -1, -1):
        var line_full = true
        for x in range(GRID_WIDTH):
            if grid[y][x] == -1:
                line_full = false
                break
        
        if line_full:
            lines_cleared += 1
            # 清除该行
            for row in range(y, 0, -1):
                for col in range(GRID_WIDTH):
                    grid[row][col] = grid[row - 1][col]
            # 顶部行清空
            for col in range(GRID_WIDTH):
                grid[0][col] = -1
    
    # 更新得分
    if lines_cleared > 0:
        score += lines_cleared * 100
        $ScoreLabel.text = "Score: {}".format(score)
        
        # 重新绘制网格
        clear_pieces()
        draw_grid()
        draw_current_piece()
        draw_next_piece()

func draw_grid():
    # 绘制网格中的方块
    for y in range(GRID_HEIGHT):
        for x in range(GRID_WIDTH):
            if grid[y][x] != -1:
                var color = tetromino_colors[grid[y][x]]
                var cell = ColorRect.new()
                cell.name = "Cell_{}_{}".format(y, x)
                cell.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
                cell.size = Vector2(CELL_SIZE - 1, CELL_SIZE - 1)
                cell.color = color
                $GameArea.add_child(cell)

func spawn_next_piece():
    current_piece = next_piece
    next_piece = generate_piece()
    
    # 检查游戏是否结束
    if check_collision():
        game_over = true
        game_started = false
        $GameOverLabel.visible = true
        return
    
    clear_pieces()
    draw_grid()
    draw_current_piece()
    draw_next_piece()
