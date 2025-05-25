import serial
import pygame
import sys
import math
import time
from pygame.locals import *

# Configure serial connection - adjust port as needed
SERIAL_PORT = '/dev/ttyACM0'  # Change this to your Arduino's port
BAUD_RATE = 9600

# Pygame setup
pygame.init()
WIDTH, HEIGHT = 800, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Judge Simulator")

# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
WOOD = (160, 120, 80)
GOLD = (218, 165, 32)
GRAY = (100, 100, 100)
RED = (200, 50, 50)
GREEN = (50, 200, 50)

# Load and scale images (you can replace with your own images)
try:
    scale_img = pygame.image.load('scale.png')
    hammer_img = pygame.image.load('hammer.png')
    scale_img = pygame.transform.scale(scale_img, (300, 150))
    hammer_img = pygame.transform.scale(hammer_img, (100, 200))
except:
    # Use drawn shapes if images not available
    scale_img = None
    hammer_img = None

# Game state variables
scale_value = 512  # Middle position (0-1023 from Arduino)
knock_strength = 0
knock_animation = 0  # Counter for animation
last_knock_time = 0

def draw_scale(value):
    """Draw the justice scale with tilt based on potentiometer value"""
    # Scale the value to an angle between -30 and 30 degrees
    # Arduino sends 0-1023, we map to -30 to 30 degrees
    angle = (value - 512) / 512 * 30
    
    center_x, center_y = WIDTH // 2, HEIGHT // 3
    
    if scale_img:
        # Use rotated image
        rotated = pygame.transform.rotate(scale_img, angle)
        rect = rotated.get_rect(center=(center_x, center_y))
        screen.blit(rotated, rect)
    else:
        # Draw a scale with shapes
        # Base
        pygame.draw.rect(screen, WOOD, (center_x - 50, center_y + 50, 100, 30))
        
        # Pivot
        pygame.draw.rect(screen, GRAY, (center_x - 10, center_y - 20, 20, 80))
        
        # Beam
        beam_length = 200
        end_x_left = center_x - beam_length/2 * math.cos(math.radians(angle))
        end_y_left = center_y - beam_length/2 * math.sin(math.radians(angle))
        end_x_right = center_x + beam_length/2 * math.cos(math.radians(angle))
        end_y_right = center_y + beam_length/2 * math.sin(math.radians(angle))
        
        pygame.draw.line(screen, GOLD, (end_x_left, end_y_left), (end_x_right, end_y_right), 8)
        
        # Pans
        pygame.draw.circle(screen, GOLD, (int(end_x_left), int(end_y_left) + 20), 30, 2)
        pygame.draw.circle(screen, GOLD, (int(end_x_right), int(end_y_right) + 20), 30, 2)
    
    # Draw scale value
    font = pygame.font.SysFont('Arial', 24)
    if value < 450:
        text = font.render("Innocent", True, GREEN)
    elif value > 550:
        text = font.render("Guilty", True, RED)
    else:
        text = font.render("Neutral", True, BLACK)
    
    screen.blit(text, (center_x - text.get_width() // 2, center_y + 100))

def draw_hammer(animation_step):
    """Draw the hammer with animation based on knock detection"""
    hammer_x, hammer_y = WIDTH * 3/4, HEIGHT * 2/3
    
    # If hammer is in animation, rotate it
    angle = 0
    if animation_step > 0:
        # 0-10: up, 10-20: down
        if animation_step <= 10:
            angle = animation_step * 4  # Raise hammer
        else:
            angle = (20 - animation_step) * 4  # Lower hammer
    
    if hammer_img:
        # Use rotated image
        rotated = pygame.transform.rotate(hammer_img, angle)
        rect = rotated.get_rect(center=(hammer_x, hammer_y))
        screen.blit(rotated, rect)
    else:
        # Draw hammer with shapes
        # Handle
        handle_length = 120
        handle_end_x = hammer_x
        handle_end_y = hammer_y - handle_length
        
        # Rotate handle
        handle_top_x = hammer_x + math.sin(math.radians(angle)) * handle_length
        handle_top_y = hammer_y - math.cos(math.radians(angle)) * handle_length
        
        pygame.draw.line(screen, WOOD, (hammer_x, hammer_y), 
                         (handle_top_x, handle_top_y), 15)
        
        # Head
        head_width = 60
        head_height = 30
        pygame.draw.rect(screen, WOOD, 
                        (handle_top_x - head_width/2, handle_top_y - head_height/2, 
                         head_width, head_height))
    
    # Show bang text if in second half of animation
    if 10 < animation_step <= 15:
        font = pygame.font.SysFont('Impact', 48)
        text = font.render("BANG!", True, RED)
        screen.blit(text, (hammer_x - 60, hammer_y - 100))

def request_sensor_data(ser):
    """Request sensor data from Arduino and parse response"""
    global scale_value, knock_strength, knock_animation, last_knock_time
    
    # Clear any pending data
    ser.reset_input_buffer()
    
    # Send request command
    ser.write(b'R')
    
    # Wait and read response until END marker
    responses = []
    while True:
        if ser.in_waiting > 0:
            try:
                line = ser.readline().decode('utf-8', errors='replace').strip()
                if line == "END":
                    break
                responses.append(line)
            except Exception as e:
                print(f"Error reading response: {e}")
                break
    
    # Process all responses
    for line in responses:
        if line.startswith("SCALE:"):
            try:
                scale_value = int(line.split(":")[1])
            except (ValueError, IndexError):
                pass
        
        elif line.startswith("KNOCK:"):
            try:
                knock_strength = int(line.split(":")[1])
                knock_animation = 1  # Start animation
                last_knock_time = time.time()
            except (ValueError, IndexError):
                pass

def game_loop():
    """Main game loop"""
    global scale_value, knock_strength, knock_animation, last_knock_time
    
    try:
        # Open serial connection
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1.0)
        print(f"Connected to {SERIAL_PORT}")
        
        # Allow Arduino to reset
        time.sleep(2)
        ser.reset_input_buffer()
        
        # Setup pygame clock
        clock = pygame.time.Clock()
        
        # Time of last sensor request
        last_request_time = 0
        request_interval = 50  # ms between requests
        
        while True:
            # Handle pygame events
            for event in pygame.event.get():
                if event.type == QUIT:
                    ser.close()
                    pygame.quit()
                    sys.exit()
            
            # Request sensor data on interval
            current_time = pygame.time.get_ticks()
            if current_time - last_request_time >= request_interval:
                request_sensor_data(ser)
                last_request_time = current_time
            
            # Update knock animation
            if knock_animation > 0:
                knock_animation += 1
                if knock_animation > 20:  # Animation length
                    knock_animation = 0
            
            # Draw everything
            screen.fill(WHITE)
            draw_scale(scale_value)
            draw_hammer(knock_animation)
            
            # Show time since last knock
            font = pygame.font.SysFont('Arial', 20)
            if knock_strength > 0:
                time_since = time.time() - last_knock_time
                if time_since < 5:  # Show for 5 seconds
                    text = font.render(f"Last Knock: {time_since:.1f}s ago (Strength: {knock_strength})", 
                                      True, BLACK)
                    screen.blit(text, (20, HEIGHT - 40))
            
            pygame.display.flip()
            clock.tick(60)  # 60 FPS
            
    except serial.SerialException as e:
        print(f"Serial connection error: {e}")
        font = pygame.font.SysFont('Arial', 24)
        text = font.render(f"Serial connection error: {e}", True, RED)
        screen.blit(text, (WIDTH//2 - text.get_width()//2, HEIGHT//2))
        pygame.display.flip()
        pygame.time.delay(3000)
        pygame.quit()
        sys.exit()

if __name__ == "__main__":
    game_loop()