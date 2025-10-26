extends ShopItem
class_name BoosterItem
var booster_catalog : BoosterCatalog

@export var booster_id: String = "health"
var booster_type: String = ""

func _init(p_id: String = "health"):
    booster_id = p_id
    item_type = "booster"
    _setup_booster()

func _setup_booster():
    var data = BoosterCatalog.get_data(booster_id)
    
    if data.is_empty():
        push_error("❌ Booster inválido: %s" % booster_id)
        return
    
    # Asignar datos del catálogo
    item_id = booster_id
    item_name = data["name"]
    description = data["description"]
    cost = data["cost"]
    booster_type = data["type"]
    
    effect = {
        "type": booster_type,
        "value": data["amount"]
    }

func apply_effect(game_manager: Node) -> bool:
    # Aplica el efecto del booster a todas las unidades del jugador
    print("\n🎁 === APLICANDO BOOSTER: %s ===" % item_name)
    
    # Obtener el team del jugador (team_id = 0)
    var turn_manager = game_manager.get_tree().get_first_node_in_group("turn_manager")
    if not turn_manager or turn_manager.teams.size() == 0:
        push_error("❌ No se pudo obtener el team del jugador")
        return false
    
    var player_team = turn_manager.teams[0]
    var units = player_team.get_living_units()
    
    if units.is_empty():
        print("⚠️ No hay unidades vivas para aplicar el booster")
        return false
    
    var applied_count = 0
    
    # Aplicar efecto a cada unidad
    for unit in units:
        if _apply_to_unit(unit):
            applied_count += 1
            print("  ✅ %s mejorado" % unit.name)
        else:
            print("  ❌ %s no pudo ser mejorado" % unit.name)
    
    print("🎁 Booster aplicado a %d/%d unidades\n" % [applied_count, units.size()])
    return applied_count > 0

func _apply_to_unit(unit: BaseUnit) -> bool:
    # Aplica el efecto a una unidad específica

    match booster_type:
        "health":
            if not unit.has_node("HealthComponent"):
                return false
            var health_comp = unit.get_node("HealthComponent") as HealthComponent
            var amount = effect["value"]
            health_comp.max_hp += amount
            health_comp.hp = min(health_comp.hp + amount, health_comp.max_hp)
            print("    💚 HP: +%d (ahora %d/%d)" % [amount, health_comp.hp, health_comp.max_hp])
            return true
        
        "power":
            var amount = effect["value"]
            unit.power += amount
            print("    ⚔️ Poder: +%d (ahora %d)" % [amount, unit.power])
            return true
        
        "movement":
            if not unit.has_node("MovementComponent"):
                return false
            var movement_comp = unit.get_node("MovementComponent") as MovementComponent
            var amount = effect["value"]
            movement_comp.original_range += amount
            print("    🚶 Rango movimiento: +%d (ahora %d)" % [amount, movement_comp.original_range])
            return true
        
        "full_heal":
            if not unit.has_node("HealthComponent"):
                return false
            var health_comp = unit.get_node("HealthComponent") as HealthComponent
            var old_hp = health_comp.hp
            health_comp.hp = health_comp.max_hp
            print("    💚 Curación completa: %d → %d" % [old_hp, health_comp.hp])
            return true
        
        _:
            push_error("❌ Tipo de booster desconocido: %s" % booster_type)
            return false

func can_apply() -> bool:
    return true
