class_name AIDecisionMaker

var unit: BaseUnit
var turn_manager: TurnManager

func _init(p_unit: BaseUnit, p_turn_manager: TurnManager):
    unit = p_unit
    turn_manager = p_turn_manager

func decide_action() -> Dictionary:
    # Evaluar situación
    var enemies = get_nearby_enemies(5)
    
    if enemies.is_empty():
        print("  📊 Decisión: Sin enemigos, movimiento aleatorio")
        return {
            "type": "random",
            "target": null,
            "priority": 10
        }
    
    var closest_enemy = enemies[0]
    
    #Sistema de puntuaciones
    var scores = evaluate_all_strategies(closest_enemy)
    var best_strategy = get_best_strategy(scores, closest_enemy)
    
    print("  📊 Decisión: %s (puntuación: %d)" % [best_strategy["type"], best_strategy["priority"]])
    return best_strategy

# ============ EVALUACIÓN DE ESTRATEGIAS ============

func evaluate_all_strategies(closest_enemy: BaseUnit) -> Dictionary:
    # Evalúa cada estrategia y retorna puntuaciones
    var scores = {}
    
    scores["attack"] = evaluate_attack_strategy(closest_enemy)
    scores["move"] = evaluate_move_strategy(closest_enemy)
    scores["retreat"] = evaluate_retreat_strategy(closest_enemy)
    scores["pursue"] = evaluate_pursuit_strategy(closest_enemy)
    scores["random"] = 5  # Fallback siempre disponible
    
    print("    📈 Puntuaciones: %s" % scores)
    return scores

func evaluate_attack_strategy(target: BaseUnit) -> int:
    var score = 0
    
    # ¿Está en rango de ataque?
    if not is_in_attack_range(target):
        return 0
    
    score += 50  # Bonus base por estar en rango
    
    # ¿Enemigo está débil? (bonus por atacar enemigo bajo HP)
    var enemy_hp_percent = float(target.health_component.hp) / float(target.health_component.max_hp)
    if enemy_hp_percent < 0.3:
        score += 30
    elif enemy_hp_percent < 0.6:
        score += 15
    
    # ¿Nosotros estamos saludables? (bonus por atacar si tenemos HP)
    var my_hp_percent = float(unit.health_component.hp) / float(unit.health_component.max_hp)
    if my_hp_percent > 0.7:
        score += 20
    elif my_hp_percent < 0.3:
        score -= 25  # Penalización por atacar si estamos débiles
    
    # ¿Hay aliados cercanos? (bonus por atacar en grupo)
    var nearby_allies = get_nearby_allies(3)
    score += nearby_allies.size() * 10
    
    return score

func evaluate_move_strategy(target: BaseUnit) -> int:
    var score = 0
    
    # ¿Está en rango de movimiento pero no de ataque?
    if not is_in_movement_range(target) or is_in_attack_range(target):
        return 0
    
    score += 40  # Bonus base
    
    # ¿Podemos movernos?
    if not unit.state_machine.actions_available.get("move", false):
        return 0
    
    # Bonus por cercanía
    var distance = unit.board_position.distance_to(target.board_position)
    score += max(0, 30 - int(distance))  # Más bonus si está cerca
    
    return score

func evaluate_retreat_strategy(_target: BaseUnit) -> int:
    var score = 0
    
    # ¿Estamos bajo en HP?
    var my_hp_percent = float(unit.health_component.hp) / float(unit.health_component.max_hp)
    if my_hp_percent >= 0.6:
        return 0  # No huir si estamos bien
    
    score += 50  # Bonus base por baja salud
    
    # Bonus extra si estamos muy mal
    if my_hp_percent < 0.2:
        score += 30
    
    # ¿Podemos movernos?
    if not unit.state_machine.actions_available.get("move", false):
        return 0
    
    return score

func evaluate_pursuit_strategy(target: BaseUnit) -> int:
    var score = 0
    
    # Solo si enemigo está lejano
    var distance = unit.board_position.distance_to(target.board_position)
    if distance <= 2:
        return 0
    
    score += 30 + int(distance * 2)  # Más score si está más lejano
    
    # ¿Podemos movernos?
    if not unit.state_machine.actions_available.get("move", false):
        return 0
    
    return score

func get_best_strategy(scores: Dictionary, closest_enemy: BaseUnit) -> Dictionary:
    #Retorna la estrategia con mejor puntuación
    var best_type = "random"
    var best_score = scores.get("random", 5)
    
    for strategy_type in scores:
        if scores[strategy_type] > best_score:
            best_score = scores[strategy_type]
            best_type = strategy_type
    
    return {
        "type": best_type,
        "target": closest_enemy, 
        "priority": best_score
    }

# ============ HELPERS ============

func get_nearby_enemies(range_val: int) -> Array[BaseUnit]:
    var enemies: Array[BaseUnit] = []
    
    if turn_manager.teams.size() < 2:
        return enemies
    
    var player_team = turn_manager.teams[0]
    
    for enemy_unit in player_team.get_living_units():
        var distance = unit.board_position.distance_to(enemy_unit.board_position)
        if distance <= range_val:
            enemies.append(enemy_unit)
    
    enemies.sort_custom(func(a, b): 
        return unit.board_position.distance_to(a.board_position) < unit.board_position.distance_to(b.board_position)
    )
    
    return enemies

func get_nearby_allies(range_val: int) -> Array[BaseUnit]:
    #Obtiene aliados cercanos para coordinar ataques
    var allies: Array[BaseUnit] = []
    var my_team = unit.team
    
    for ally in my_team.get_living_units():
        if ally == unit:
            continue
        var distance = unit.board_position.distance_to(ally.board_position)
        if distance <= range_val:
            allies.append(ally)
    
    return allies

func is_in_attack_range(target: BaseUnit) -> bool:
    if not is_instance_valid(target) or not unit.attack_component:
        return false
    
    var attack_range_1 = unit.attack_component.get_attackable_cells(0)
    var attack_range_2 = unit.attack_component.get_attackable_cells(1)
    
    return target.board_position in attack_range_1 or target.board_position in attack_range_2

func is_in_movement_range(target: BaseUnit) -> bool:
    if not is_instance_valid(target) or not unit.movement_component:
        return false
    
    var movable_cells = unit.movement_component.get_movable_cells()
    return target.board_position in movable_cells
