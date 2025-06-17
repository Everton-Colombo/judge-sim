extends AnimatedSprite2D

# Timer for controlling animation changes
var idle_timer: Timer
var rng = RandomNumberGenerator.new()

func _ready():
    # Connect animation finished signal
    animation_finished.connect(_on_animation_finished)
    
    # Set up timer
    idle_timer = Timer.new()
    idle_timer.one_shot = true
    idle_timer.timeout.connect(_on_idle_timer_timeout)
    add_child(idle_timer)
    
    # Start in default state
    play("default")
    
    # Start the animation cycle
    _start_idle_timer()

func _start_idle_timer():
    var idle_time = rng.randf_range(2.0, 7.0)
    idle_timer.start(idle_time)

func _on_idle_timer_timeout():
    # Choose randomly between blink and look
    var animations = ["blink", "look"]
    var chosen_animation = animations[rng.randi() % 2]
    
    # Play the chosen animation
    play(chosen_animation)

func _on_animation_finished():
    # If we're not in the default animation, go back to it
    if animation != "default":
        play("default")
        # Start the timer again for the next cycle
        _start_idle_timer()