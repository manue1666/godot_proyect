extends Control
class_name BattleHUD

@onready var level_label: Label = $ButtomBar/MarginContainer/HBoxContainer/LevelLabel
@onready var turn_label: Label = $ButtomBar/MarginContainer/HBoxContainer/TurnLabel
@onready var end_turn_button: Button = $Turn

# Referencias a labels de boosts
@onready var health_boost_label: Label = $ButtomBar/MarginContainer2/VBoxContainer/HealthBoostLabel
@onready var power_boost_label: Label = $ButtomBar/MarginContainer2/VBoxContainer/PowerLabel
@onready var movement_boost_label: Label = $ButtomBar/MarginContainer2/VBoxContainer/MovBoostLabel

var team_stats_tracker: TeamStatsTracker

signal end_turn_pressed()

func _ready():
    end_turn_button.pressed.connect(_on_end_turn_pressed)
    
    # Obtener referencia a TeamStatsTracker
    await get_tree().process_frame
    team_stats_tracker = get_tree().get_first_node_in_group("team_stats_tracker")
    
    if team_stats_tracker:
        print("✅ BattleHUD conectado a TeamStatsTracker")
        # Actualizar al iniciar por si hay boosts previos
        update_boosts_display()
    else:
        print("⚠️  TeamStatsTracker no encontrado en BattleHUD")

func update_level(current: int, total: int):
    level_label.text = "Level %d/%d" % [current, total]

func update_turn(team_name: String):
    turn_label.text = "Turn: %s" % team_name

# ACTUALIZAR DISPLAY DE BOOSTS
func update_boosts_display():
    if not team_stats_tracker:
        return
    
    health_boost_label.text = "Health Boost: %d" % team_stats_tracker.get_health_boost()
    power_boost_label.text = "Power Boost: %d" % team_stats_tracker.get_power_boost()
    movement_boost_label.text = "Movement Boost: %d" % team_stats_tracker.get_movement_boost()
    
    print("🎨 Boosts actualizados en HUD:")
    print("  💚 Health: %d" % team_stats_tracker.get_health_boost())
    print("  ⚔️ Power: %d" % team_stats_tracker.get_power_boost())
    print("  🚶 Movement: %d" % team_stats_tracker.get_movement_boost())

func _on_end_turn_pressed():
    end_turn_pressed.emit()
