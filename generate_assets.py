import os
import sys
from PIL import Image, ImageDraw

ASSETS_DIR = "/Users/daidai/ai/path-of-ashes/assets"

# Create a PIL image helper
def make_pixel_art(width, height, draw_func):
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_func(draw, width, height)
    return img

def save_image(img, rel_path):
    out_path = os.path.join(ASSETS_DIR, rel_path)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path, "PNG")
    print(f"Saved: {rel_path} ({img.width}x{img.height})")

# --- PROCEDURAL DRAWING FUNCTIONS ---

# 1. Tilesets
def draw_themed_ground(draw, w, h, theme):
    # Determine colors
    if theme == "abyss":
        bg, border, crack, moss = (20, 16, 28, 255), (32, 28, 48, 255), (8, 4, 15, 255), (100, 30, 130, 255)
    elif theme == "capital":
        bg, border, crack, moss = (48, 48, 52, 255), (65, 65, 70, 255), (20, 20, 22, 255), (80, 85, 75, 255)
    elif theme == "cathedral":
        bg, border, crack, moss = (64, 25, 25, 255), (85, 40, 40, 255), (35, 10, 10, 255), (120, 100, 50, 255)
    elif theme == "forest":
        bg, border, crack, moss = (45, 38, 28, 255), (60, 52, 40, 255), (20, 15, 10, 255), (35, 70, 40, 255)
    elif theme == "heart":
        bg, border, crack, moss = (30, 15, 15, 255), (45, 22, 22, 255), (230, 60, 10, 255), (180, 40, 5, 255) # glowing lava cracks
    elif theme == "mines":
        bg, border, crack, moss = (40, 38, 38, 255), (55, 52, 52, 255), (15, 12, 12, 255), (200, 160, 40, 255) # gold ore veins
    elif theme == "palace":
        bg, border, crack, moss = (70, 80, 95, 255), (95, 110, 130, 255), (40, 48, 60, 255), (220, 180, 60, 255) # gold trims
    else: # temple
        bg, border, crack, moss = (85, 75, 55, 255), (110, 100, 75, 255), (50, 42, 30, 255), (65, 80, 50, 255)

    for ty in range(0, h, 32):
        for tx in range(0, w, 32):
            draw.rectangle([tx, ty, tx+31, ty+31], fill=bg)
            draw.line([tx, ty, tx+31, ty], fill=border)
            draw.line([tx, ty, tx, ty+31], fill=border)
            # Custom detailing based on theme
            if theme == "heart":
                draw.line([tx+10, ty+15, tx+20, ty+25], fill=crack, width=2) # magma crack
                draw.point((tx+15, ty+10), fill=moss)
            elif theme == "mines":
                draw.line([tx+8, ty+8, tx+24, ty+24], fill=moss, width=1) # gold veins
            elif theme == "forest":
                draw.rectangle([tx+4, ty+4, tx+16, ty+12], fill=moss) # heavy moss
            else:
                draw.line([tx+12, ty+10, tx+18, ty+22], fill=crack) # standard crack
                if (tx+ty) % 64 == 0:
                    draw.point((tx+6, ty+6), fill=moss)

def draw_themed_background(draw, w, h, theme):
    # Dark bricks or textures
    if theme == "abyss":
        c1, c2 = (12, 10, 20, 255), (20, 16, 32, 255)
    elif theme == "capital":
        c1, c2 = (30, 30, 32, 255), (42, 42, 45, 255)
    elif theme == "cathedral":
        c1, c2 = (38, 20, 20, 255), (48, 28, 28, 255)
    elif theme == "forest":
        c1, c2 = (22, 25, 20, 255), (32, 36, 28, 255)
    elif theme == "heart":
        c1, c2 = (20, 10, 10, 255), (32, 15, 15, 255)
    elif theme == "mines":
        c1, c2 = (25, 24, 24, 255), (35, 34, 34, 255)
    elif theme == "palace":
        c1, c2 = (40, 45, 55, 255), (55, 62, 75, 255)
    else: # temple
        c1, c2 = (55, 48, 35, 255), (70, 62, 48, 255)

    for ty in range(0, h, 16):
        shift = 8 if (ty // 16) % 2 == 1 else 0
        for tx in range(-16, w+16, 32):
            bx = tx + shift
            draw.rectangle([bx, ty, bx+31, ty+15], fill=c1)
            draw.line([bx, ty, bx+31, ty], fill=c2)
            draw.line([bx, ty, bx, ty+15], fill=c2)
            if theme == "cathedral" and (bx+ty)%64 == 0:
                # Add tiny stained glass window pixel hints
                draw.rectangle([bx+10, ty+4, bx+14, ty+12], fill=(220, 180, 60, 100))

def draw_themed_platform(draw, w, h, theme):
    # Platform stone slabs with support pillars
    top_c = (90, 95, 110, 255) if theme == "palace" else (50, 48, 48, 255)
    border_c = (220, 180, 60, 255) if theme == "palace" else (70, 68, 68, 255)
    
    draw.rectangle([0, 0, w, 16], fill=top_c)
    draw.line([0, 0, w, 0], fill=border_c, width=2)
    # Pillars
    for tx in range(0, w, 64):
        draw.rectangle([tx+20, 16, tx+44, h], fill=(top_c[0]-20, top_c[1]-20, top_c[2]-20, 255))

def draw_themed_wall(draw, w, h, theme):
    # Wall tileset (heavy bricks)
    draw_themed_ground(draw, w, h, theme) # base wall
    # Add vertical masonry lines to make it look like a wall
    for tx in range(0, w, 32):
        draw.line([tx, 0, tx, h], fill=(10, 10, 12, 100), width=2)

# 2. Weapons
def draw_weapon_axe(draw, w, h, theme):
    cx, cy = w // 2, h // 2
    # Shaft
    draw.line([cx - w//3, cy + h//3, cx + w//4, cy - h//4], fill=(100, 70, 40, 255), width=2)
    # Heavy Axe Head
    blade_color = (200, 70, 30, 255) if theme == "flame" else (110, 110, 115, 255)
    if theme == "bone":
        blade_color = (220, 215, 200, 255) # white bone hammer head
        draw.rectangle([cx - 4, cy - 10, cx + 12, cy + 6], fill=blade_color)
    else:
        draw.chord([cx, cy - 14, cx + 18, cy + 8], -90, 90, fill=blade_color)
        draw.line([cx, cy-14, cx, cy+8], fill=(50, 50, 52, 255), width=2)
    if theme == "ash":
        draw.point((cx+8, cy), fill=(100, 100, 100, 255))

def draw_weapon_dagger(draw, w, h, theme):
    cx, cy = w // 2, h // 2
    # Handle
    draw.line([cx - w//4, cy + h//4, cx - w//6, cy + h//6], fill=(80, 60, 45, 255), width=2)
    # Blade
    blade_color = (180, 30, 30, 255) if theme == "blood" else (110, 110, 115, 255)
    if theme == "flame":
        blade_color = (240, 130, 30, 255)
    elif theme == "poisoned":
        blade_color = (30, 180, 50, 255)
    elif theme == "shadow":
        blade_color = (130, 40, 200, 255)
    draw.line([cx - w//6, cy + h//6, cx + w//3, cy - h//3], fill=blade_color, width=2)

def draw_weapon_greatsword(draw, w, h, theme):
    cx, cy = w // 2, h // 2
    # Long Handle & Hilt
    draw.line([cx - w//3, cy + h//3, cx - w//6, cy + h//6], fill=(50, 40, 35, 255), width=2)
    draw.line([cx - w//6 - 4, cy + h//6 - 4, cx - w//6 + 4, cy + h//6 + 4], fill=(130, 110, 40, 255), width=2) # large guard
    # Bulky Blade
    blade_color = (140, 140, 145, 255)
    if theme == "abyss":
        blade_color = (60, 30, 110, 255)
    elif theme == "ash":
        blade_color = (80, 80, 85, 255)
    elif theme == "graveyard":
        blade_color = (90, 110, 95, 255)
    elif theme == "king-broken":
        # Draw a jagged broken blade
        draw.line([cx - w//6, cy + h//6, cx + w//8, cy - h//8], fill=(110, 110, 112, 255), width=3)
        draw.line([cx + w//8, cy - h//8, cx + w//8 + 2, cy - h//8 - 2], fill=(200, 60, 60, 255)) # red break point
        return
    draw.line([cx - w//6, cy + h//6, cx + w//3, cy - h//3], fill=blade_color, width=3)

def draw_weapon_spear(draw, w, h, theme):
    cx, cy = w // 2, h // 2
    # Long Shaft
    draw.line([cx - w//2 + 4, cy + h//2 - 4, cx + w//2 - 12, cy - h//2 + 12], fill=(100, 80, 60, 255), width=2)
    # Tip
    tip_color = (180, 180, 185, 255)
    if theme == "abyss":
        tip_color = (90, 40, 150, 255)
    elif theme == "holy":
        tip_color = (245, 220, 80, 255)
    elif theme == "lightning":
        # Draw zigzag tip
        lx, ly = cx + w//2 - 12, cy - h//2 + 12
        draw.line([lx, ly, lx+6, ly-10], fill=(80, 200, 255, 255), width=2)
        draw.line([lx+6, ly-10, lx+2, ly-14], fill=(255, 255, 255, 255), width=2)
        return
    draw.line([cx + w//2 - 12, cy - h//2 + 12, cx + w//2 - 2, cy - h//2 + 2], fill=tip_color, width=3)

def draw_weapon_staff(draw, w, h, theme):
    cx, cy = w // 2, h // 2
    # Wooden Staff
    draw.line([cx - w//3, cy + h//3, cx + w//5, cy - h//5], fill=(120, 80, 50, 255), width=2)
    # Orb gem at top
    gem_color = (255, 255, 255, 255)
    if theme == "abyss":
        gem_color = (130, 30, 220, 255)
    elif theme == "ash":
        gem_color = (90, 90, 95, 255)
    elif theme == "flame":
        gem_color = (240, 90, 20, 255)
    elif theme == "holy":
        gem_color = (245, 220, 50, 255)
    
    gx, gy = cx + w//5, cy - h//5
    draw.ellipse([gx-4, gy-4, gx+4, gy+4], fill=gem_color)
    draw.arc([gx-6, gy-6, gx+6, gy+6], 0, 360, fill=(60, 60, 64, 255), width=1)

# 3. Amulets & Consumables
def draw_amulet(draw, w, h, theme):
    cx, cy = w // 2, h // 2
    # Outer metal frame (shield/circle shape)
    draw.ellipse([cx-12, cy-12, cx+12, cy+12], fill=(60, 60, 64, 255))
    draw.ellipse([cx-10, cy-10, cx+10, cy+10], fill=(80, 80, 85, 255))
    # Icon inside
    if theme == "abyss-gaze" or theme == "ash-vision":
        draw.ellipse([cx-5, cy-3, cx+5, cy+3], fill=(180, 180, 200, 255))
        draw.point((cx, cy), fill=(130, 40, 200, 255) if "abyss" in theme else (30, 150, 240, 255))
    elif theme == "ash-affinity":
        draw.ellipse([cx-4, cy-4, cx+4, cy+4], fill=(120, 120, 125, 255))
    elif theme == "ash-blood" or theme == "vampire":
        draw.polygon([(cx, cy-6), (cx-5, cy+2), (cx+5, cy+2)], fill=(180, 20, 20, 255))
    elif theme == "fire-resist":
        draw.ellipse([cx-5, cy-5, cx+5, cy+5], fill=(230, 90, 20, 255))
    elif theme == "holy-range":
        draw.rectangle([cx-2, cy-6, cx+2, cy+6], fill=(245, 210, 40, 255))
        draw.rectangle([cx-6, cy-2, cx+6, cy+2], fill=(245, 210, 40, 255))
    elif theme == "iron-wall":
        draw.rectangle([cx-6, cy-6, cx+6, cy+6], fill=(120, 120, 125, 255))
    elif theme == "quake-range":
        draw.line([cx-7, cy, cx+7, cy], fill=(139, 69, 19, 255), width=2)
    elif theme == "range-master":
        draw.ellipse([cx-6, cy-6, cx+6, cy+6], fill=(30, 160, 50, 255))
        draw.ellipse([cx-3, cy-3, cx+3, cy+3], fill=(255, 255, 255, 255))
    elif "shadow" in theme:
        draw.line([cx-7, cy-4, cx+7, cy+4], fill=(130, 40, 210, 255), width=2)
    else: # soul-keeper
        draw.ellipse([cx-5, cy-5, cx+5, cy+5], fill=(100, 200, 255, 255))

def draw_consumable(draw, w, h, name):
    cx, cy = w // 2, h // 2
    if name == "antidote":
        draw.rectangle([cx-4, cy-8, cx+4, cy+6], fill=(30, 180, 55, 255)) # green vial
    elif name == "curse-cure":
        draw.ellipse([cx-8, cy-5, cx+8, cy+7], fill=(120, 40, 180, 255)) # purple jar
    elif name == "fire-pot":
        draw.ellipse([cx-7, cy-5, cx+7, cy+7], fill=(180, 70, 20, 255)) # red clay pot
        draw.point((cx, cy-8), fill=(255, 150, 30, 255)) # spark fuse
    elif name == "focus-potion":
        draw.rectangle([cx-4, cy-8, cx+4, cy+6], fill=(30, 120, 240, 255)) # blue vial
    elif name == "moss":
        draw.ellipse([cx-6, cy-6, cx+6, cy+6], fill=(55, 110, 40, 255)) # moss cluster
    elif name == "poison-pot":
        draw.ellipse([cx-7, cy-5, cx+7, cy+7], fill=(40, 90, 40, 255)) # green clay pot
    else: # return-bone
        draw.line([cx-6, cy+6, cx+6, cy-6], fill=(225, 220, 210, 255), width=3) # bone

# 4. Bosses & Enemies & NPCs Animation sheets
def draw_boss_sheet(draw, w, h, frames, action, name):
    # Theme colors for each boss
    if name == "abyss-watcher":
        body, cape, eye = (50, 40, 70, 255), (100, 40, 120, 255), (255, 255, 255, 255)
    elif name == "ash-king":
        body, cape, eye = (70, 65, 60, 255), (150, 70, 30, 255), (255, 160, 30, 255)
    elif name == "exiled-king":
        body, cape, eye = (45, 60, 80, 255), (200, 180, 60, 255), (100, 180, 255, 255)
    elif name == "fallen-bishop":
        body, cape, eye = (50, 20, 20, 255), (120, 20, 20, 255), (20, 20, 22, 255)
    elif name == "flame-guardian":
        body, cape, eye = (40, 30, 30, 255), (230, 70, 10, 255), (255, 120, 10, 255)
    elif name == "mine-worm":
        # Draw segment worm body
        for f in range(frames):
            cx = f * h + h // 2
            cy = h // 2
            draw.ellipse([cx-24, cy-12, cx+24, cy+12], fill=(120, 90, 60, 255))
            draw.ellipse([cx-12, cy-8, cx+12, cy+8], fill=(160, 130, 90, 255))
            draw.point((cx+8, cy-3), fill=(255, 230, 30, 255)) # yellow eyes
            draw.point((cx+8, cy+3), fill=(255, 230, 30, 255))
        return
    else: # mother-of-decay
        body, cape, eye = (40, 60, 40, 255), (90, 130, 60, 255), (50, 220, 30, 255)

    for f in range(frames):
        cx = f * h + h // 2
        cy = h // 2
        
        y_off = 3 if action == "idle" and f % 2 == 1 else 0
        if action == "hurt":
            y_off = -2
        
        # Heavy boss body shape (96x96 frame)
        # Head
        draw.ellipse([cx-12, cy-28 + y_off, cx+12, cy-8 + y_off], fill=cape)
        # Face shadow
        draw.rectangle([cx-8, cy-20 + y_off, cx+8, cy-12 + y_off], fill=(15, 15, 18, 255))
        draw.point((cx+3, cy-17 + y_off), fill=eye)
        draw.point((cx-3, cy-17 + y_off), fill=eye)
        
        # Bulky Torso
        draw.rectangle([cx-20, cy-8 + y_off, cx+20, cy+20 + y_off], fill=body)
        draw.rectangle([cx-24, cy-4 + y_off, cx-18, cy+26 + y_off], fill=cape) # large shoulder cape
        draw.rectangle([cx+18, cy-4 + y_off, cx+24, cy+26 + y_off], fill=cape)
        
        # Pillars legs
        draw.line([cx - 10, cy+20 + y_off, cx - 12, cy+42], fill=body, width=5)
        draw.line([cx + 10, cy+20 + y_off, cx + 12, cy+42], fill=body, width=5)

        # Attack swing overlays
        if "attack" in action:
            swing = f / (frames - 1)
            bx = cx + int(24 * swing) + 12
            by = cy - int(24 * (1.0 - swing)) + 8
            # Draw giant boss sword
            draw.line([cx - 8, cy, bx, by], fill=(150, 150, 165, 255), width=4)
            # Custom colored slash arc
            if f > 0:
                arc_c = (230, 80, 20, 180) if name in ["ash-king", "flame-guardian"] else (130, 30, 220, 150)
                draw.arc([cx - 15, cy - 32, cx + 45, cy + 28], -145, 45, fill=arc_c, width=5)

        elif action == "phase2":
            # Extra fire/void particles radiating
            draw.point((cx-26, cy-10), fill=eye)
            draw.point((cx+26, cy-6), fill=eye)
            draw.point((cx, cy-34), fill=eye)

        elif action == "death":
            fall = int(22 * (f / (frames - 1)))
            draw.rectangle([cx-20, cy-8+fall, cx+20, cy+20+fall], fill=body)
            if f == frames - 1:
                # Ashes pile
                draw.rectangle([cx-32, cy+32, cx+32, cy+40], fill=cape)

def draw_enemy_sheet(draw, w, h, frames, action, name):
    # Set theme colors
    if name == "ash-undead":
        body, cape, eye = (90, 90, 95, 255), (45, 45, 48, 255), (200, 30, 30, 255)
    elif name == "corrupted-villager":
        body, cape, eye = (120, 90, 70, 255), (80, 40, 110, 255), (160, 40, 230, 255) # purple corrupted
    elif name == "shadow-hunter":
        body, cape, eye = (20, 20, 24, 255), (30, 30, 36, 255), (130, 30, 220, 255) # shadow beast
    elif name == "skeleton-archer":
        body, cape, eye = (220, 215, 200, 255), (70, 70, 75, 255), (240, 160, 30, 255)
    else: # skeleton-knight
        body, cape, eye = (220, 215, 200, 255), (50, 60, 80, 255), (230, 30, 30, 255)

    for f in range(frames):
        cx = f * h + h // 2
        cy = h // 2
        
        y_off = 2 if action == "idle" and f % 2 == 1 else 0
        if action == "hurt":
            y_off = -1
        
        # Head / Hood
        draw.ellipse([cx - 6, cy - 16 + y_off, cx + 6, cy - 6 + y_off], fill=cape)
        draw.rectangle([cx - 4, cy - 12 + y_off, cx + 4, cy - 8 + y_off], fill=(15, 15, 18, 255))
        draw.point((cx + 1, cy - 11 + y_off), fill=eye)
        
        # Torso
        draw.rectangle([cx - 8, cy - 6 + y_off, cx + 6, cy + 12 + y_off], fill=body)
        
        # Legs
        if action == "walk":
            if f % 2 == 0:
                draw.line([cx - 4, cy+12, cx - 8, cy+24], fill=body, width=2)
                draw.line([cx + 2, cy+12, cx + 6, cy+24], fill=body, width=2)
            else:
                draw.line([cx - 4, cy+12, cx + 2, cy+24], fill=body, width=2)
                draw.line([cx + 2, cy+12, cx - 4, cy+24], fill=body, width=2)
        else:
            draw.line([cx - 4, cy+12 + y_off, cx - 4, cy+24], fill=body, width=2)
            draw.line([cx + 2, cy+12 + y_off, cx + 2, cy+24], fill=body, width=2)

        if action == "attack":
            swing = f / (frames - 1)
            bx = cx + int(12 * swing) + 4
            by = cy - int(12 * (1.0 - swing)) + 4
            if name == "skeleton-archer":
                # Draw bow & arrow path
                draw.line([cx + 2, cy - 8, cx + 12, cy + 4], fill=(100, 80, 50, 255), width=2) # bow
                draw.line([cx, cy, cx + int(14 * swing), cy], fill=(220, 215, 200, 255)) # arrow draw
            else:
                draw.line([cx, cy, bx, by], fill=(160, 160, 165, 255), width=2)
        elif action == "hurt":
            draw.rectangle([cx-8, cy-6, cx+6, cy+12], fill=(200, 50, 50, 255))
        elif action == "death":
            fall = int(12 * (f / (frames - 1)))
            draw.rectangle([cx-8, cy-6+fall, cx+6, cy+12+fall], fill=body)
            if f == frames - 1:
                draw.rectangle([cx-12, cy+18, cx+12, cy+22], fill=cape)

def draw_npc_static(draw, w, h, name):
    cx, cy = w // 2, h // 2
    if name == "captain":
        # Guard Captain (silver armor, blue cloak, shield)
        draw.rectangle([cx-10, cy-20, cx+10, cy+20], fill=(150, 150, 160, 255))
        draw.rectangle([cx-12, cy-12, cx-7, cy+16], fill=(50, 70, 130, 255)) # shield
        draw.ellipse([cx-6, cy-26, cx+6, cy-16], fill=(120, 120, 125, 255)) # helmet
        draw.line([cx-3, cy-28, cx+3, cy-28], fill=(200, 40, 40, 255), width=2) # red plume
    elif name == "spirit":
        # Lost Spirit (blue floating wisp)
        draw.ellipse([cx-8, cy-8, cx+8, cy+8], fill=(100, 200, 255, 150))
        draw.ellipse([cx-12, cy-12, cx+12, cy+12], fill=(80, 170, 255, 80))
        draw.point((cx-2, cy-2), fill=(255, 255, 255, 255))
        draw.point((cx+2, cy-2), fill=(255, 255, 255, 255))
    elif name == "ghost":
        # Miner Ghost (green translucent miner with pickaxe)
        draw.rectangle([cx-8, cy-16, cx+8, cy+16], fill=(80, 180, 120, 120))
        draw.line([cx+4, cy-4, cx+14, cy-14], fill=(139, 90, 43, 255), width=2) # pickaxe handle
        draw.arc([cx+10, cy-18, cx+18, cy-10], 0, 180, fill=(180, 180, 185, 255), width=2) # pickaxe blade
    elif name == "oracle":
        # Oracle (mystic white and gold robes)
        draw.rectangle([cx-8, cy-24, cx+8, cy+24], fill=(240, 240, 245, 255))
        draw.rectangle([cx-10, cy-12, cx+10, cy+24], fill=(220, 180, 50, 255)) # gold trims
        draw.ellipse([cx-5, cy-28, cx+5, cy-20], fill=(225, 200, 160, 255))
    else: # penitent
        # Penitent (hooded robes, crown of thorns)
        draw.rectangle([cx-8, cy-22, cx+8, cy+22], fill=(45, 42, 40, 255))
        draw.line([cx-6, cy-24, cx+6, cy-24], fill=(30, 130, 40, 255), width=2) # spiked green crown

# 5. VFX Effects
def draw_vfx_effect(draw, w, h, name):
    cx, cy = w // 2, h // 2
    if name == "buff-effect":
        draw.ellipse([cx-10, cy-10, cx+10, cy+10], fill=(40, 220, 60, 80))
        draw.point((cx-6, cy-6), fill=(100, 255, 120, 200))
        draw.point((cx+6, cy+6), fill=(100, 255, 120, 200))
    elif "explosion" in name:
        color = (240, 80, 10, 255) if "fire" in name else (110, 30, 180, 255)
        # Blast circle
        draw.ellipse([cx-18, cy-18, cx+18, cy+18], fill=(color[0], color[1], color[2], 120))
        draw.ellipse([cx-10, cy-10, cx+10, cy+10], fill=(255, 230, 180, 250))
    elif "slash" in name:
        color = (245, 215, 60, 250) if "holy" in name else (120, 30, 200, 250)
        draw.arc([cx-20, cy-12, cx+20, cy+12], -130, 30, fill=color, width=4)
    elif name == "death-particles":
        draw.point((cx-4, cy-4), fill=(100, 100, 105, 255))
        draw.point((cx+6, cy+8), fill=(100, 100, 105, 180))
        draw.point((cx-10, cy+12), fill=(100, 100, 105, 100))
    elif name == "heal-effect":
        # Green healing crosses rising
        draw.rectangle([cx-2, cy-8, cx+2, cy+2], fill=(50, 230, 70, 250))
        draw.rectangle([cx-6, cy-4, cx+6, cy-2], fill=(50, 230, 70, 250))
    else: # soul-absorb
        draw.arc([cx-12, cy-12, cx+12, cy+12], 45, 225, fill=(100, 180, 255, 180), width=2)
        draw.point((cx-8, cx+8), fill=(255, 255, 255, 255))

# --- BULK MAIN DRIVER ---

def generate_bulk_assets():
    # 150 Target assets list
    targets = [
        # Bosses (42 files)
        ("characters/bosses/abyss-watcher/abyss-watcher-attack1.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "attack1", "abyss-watcher")),
        ("characters/bosses/abyss-watcher/abyss-watcher-attack2.png", 768, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 8, "attack2", "abyss-watcher")),
        ("characters/bosses/abyss-watcher/abyss-watcher-death.png", 960, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 10, "death", "abyss-watcher")),
        ("characters/bosses/abyss-watcher/abyss-watcher-hurt.png", 384, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 4, "hurt", "abyss-watcher")),
        ("characters/bosses/abyss-watcher/abyss-watcher-idle.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "idle", "abyss-watcher")),
        ("characters/bosses/abyss-watcher/abyss-watcher-phase2.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "phase2", "abyss-watcher")),
        
        ("characters/bosses/ash-king/ash-king-attack1.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "attack1", "ash-king")),
        ("characters/bosses/ash-king/ash-king-attack2.png", 768, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 8, "attack2", "ash-king")),
        ("characters/bosses/ash-king/ash-king-death.png", 960, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 10, "death", "ash-king")),
        ("characters/bosses/ash-king/ash-king-hurt.png", 384, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 4, "hurt", "ash-king")),
        ("characters/bosses/ash-king/ash-king-idle.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "idle", "ash-king")),
        ("characters/bosses/ash-king/ash-king-phase2.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "phase2", "ash-king")),
        
        ("characters/bosses/exiled-king/exiled-king-attack1.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "attack1", "exiled-king")),
        ("characters/bosses/exiled-king/exiled-king-attack2.png", 768, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 8, "attack2", "exiled-king")),
        ("characters/bosses/exiled-king/exiled-king-death.png", 960, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 10, "death", "exiled-king")),
        ("characters/bosses/exiled-king/exiled-king-hurt.png", 384, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 4, "hurt", "exiled-king")),
        ("characters/bosses/exiled-king/exiled-king-idle.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "idle", "exiled-king")),
        ("characters/bosses/exiled-king/exiled-king-phase2.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "phase2", "exiled-king")),

        ("characters/bosses/fallen-bishop/fallen-bishop-attack1.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "attack1", "fallen-bishop")),
        ("characters/bosses/fallen-bishop/fallen-bishop-attack2.png", 768, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 8, "attack2", "fallen-bishop")),
        ("characters/bosses/fallen-bishop/fallen-bishop-death.png", 960, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 10, "death", "fallen-bishop")),
        ("characters/bosses/fallen-bishop/fallen-bishop-hurt.png", 384, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 4, "hurt", "fallen-bishop")),
        ("characters/bosses/fallen-bishop/fallen-bishop-idle.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "idle", "fallen-bishop")),
        ("characters/bosses/fallen-bishop/fallen-bishop-phase2.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "phase2", "fallen-bishop")),

        ("characters/bosses/flame-guardian/flame-guardian-attack1.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "attack1", "flame-guardian")),
        ("characters/bosses/flame-guardian/flame-guardian-attack2.png", 768, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 8, "attack2", "flame-guardian")),
        ("characters/bosses/flame-guardian/flame-guardian-death.png", 960, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 10, "death", "flame-guardian")),
        ("characters/bosses/flame-guardian/flame-guardian-hurt.png", 384, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 4, "hurt", "flame-guardian")),
        ("characters/bosses/flame-guardian/flame-guardian-idle.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "idle", "flame-guardian")),
        ("characters/bosses/flame-guardian/flame-guardian-phase2.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "phase2", "flame-guardian")),

        ("characters/bosses/mine-worm/mine-worm-attack1.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "attack1", "mine-worm")),
        ("characters/bosses/mine-worm/mine-worm-attack2.png", 768, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 8, "attack2", "mine-worm")),
        ("characters/bosses/mine-worm/mine-worm-death.png", 960, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 10, "death", "mine-worm")),
        ("characters/bosses/mine-worm/mine-worm-hurt.png", 384, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 4, "hurt", "mine-worm")),
        ("characters/bosses/mine-worm/mine-worm-idle.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "idle", "mine-worm")),
        ("characters/bosses/mine-worm/mine-worm-phase2.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "phase2", "mine-worm")),

        ("characters/bosses/mother-of-decay/mother-of-decay-attack1.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "attack1", "mother-of-decay")),
        ("characters/bosses/mother-of-decay/mother-of-decay-attack2.png", 768, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 8, "attack2", "mother-of-decay")),
        ("characters/bosses/mother-of-decay/mother-of-decay-death.png", 960, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 10, "death", "mother-of-decay")),
        ("characters/bosses/mother-of-decay/mother-of-decay-hurt.png", 384, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 4, "hurt", "mother-of-decay")),
        ("characters/bosses/mother-of-decay/mother-of-decay-idle.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "idle", "mother-of-decay")),
        ("characters/bosses/mother-of-decay/mother-of-decay-phase2.png", 576, 96, lambda d, w, h: draw_boss_sheet(d, w, h, 6, "phase2", "mother-of-decay")),

        # Enemies (22 files)
        ("characters/enemies/ash-undead/ash-undead-attack.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "attack", "ash-undead")),
        ("characters/enemies/ash-undead/ash-undead-death.png", 512, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 8, "death", "ash-undead")),
        ("characters/enemies/ash-undead/ash-undead-hurt.png", 192, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 3, "hurt", "ash-undead")),
        ("characters/enemies/ash-undead/ash-undead-idle.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "idle", "ash-undead")),

        ("characters/enemies/corrupted-villager/corrupted-villager-attack.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "attack", "corrupted-villager")),
        ("characters/enemies/corrupted-villager/corrupted-villager-death.png", 512, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 8, "death", "corrupted-villager")),
        ("characters/enemies/corrupted-villager/corrupted-villager-hurt.png", 192, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 3, "hurt", "corrupted-villager")),
        ("characters/enemies/corrupted-villager/corrupted-villager-idle.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "idle", "corrupted-villager")),
        ("characters/enemies/corrupted-villager/corrupted-villager-walk.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "walk", "corrupted-villager")),

        ("characters/enemies/shadow-hunter/shadow-hunter-attack.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "attack", "shadow-hunter")),
        ("characters/enemies/shadow-hunter/shadow-hunter-death.png", 512, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 8, "death", "shadow-hunter")),
        ("characters/enemies/shadow-hunter/shadow-hunter-hurt.png", 192, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 3, "hurt", "shadow-hunter")),
        ("characters/enemies/shadow-hunter/shadow-hunter-idle.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "idle", "shadow-hunter")),

        ("characters/enemies/skeleton-archer/skeleton-archer-attack.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "attack", "skeleton-archer")),
        ("characters/enemies/skeleton-archer/skeleton-archer-death.png", 512, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 8, "death", "skeleton-archer")),
        ("characters/enemies/skeleton-archer/skeleton-archer-hurt.png", 192, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 3, "hurt", "skeleton-archer")),
        ("characters/enemies/skeleton-archer/skeleton-archer-idle.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "idle", "skeleton-archer")),

        ("characters/enemies/skeleton-knight/skeleton-knight-attack.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "attack", "skeleton-knight")),
        ("characters/enemies/skeleton-knight/skeleton-knight-death.png", 512, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 8, "death", "skeleton-knight")),
        ("characters/enemies/skeleton-knight/skeleton-knight-hurt.png", 192, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 3, "hurt", "skeleton-knight")),
        ("characters/enemies/skeleton-knight/skeleton-knight-idle.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "idle", "skeleton-knight")),
        ("characters/enemies/skeleton-knight/skeleton-knight-walk.png", 384, 64, lambda d, w, h: draw_enemy_sheet(d, w, h, 6, "walk", "skeleton-knight")),

        # NPCs (5 files)
        ("characters/npcs/guard-captain/captain-idle.png", 64, 64, lambda d, w, h: draw_npc_static(d, w, h, "captain")),
        ("characters/npcs/lost-spirit/spirit-idle.png", 64, 64, lambda d, w, h: draw_npc_static(d, w, h, "spirit")),
        ("characters/npcs/miner-ghost/ghost-idle.png", 64, 64, lambda d, w, h: draw_npc_static(d, w, h, "ghost")),
        ("characters/npcs/oracle/oracle-idle.png", 64, 64, lambda d, w, h: draw_npc_static(d, w, h, "oracle")),
        ("characters/npcs/penitent/penitent-idle.png", 64, 64, lambda d, w, h: draw_npc_static(d, w, h, "penitent")),

        # Tilesets (32 files across 8 regions)
        # Abyss
        ("environment/tilesets/abyss/abyss-background.png", 128, 128, lambda d, w, h: draw_themed_background(d, w, h, "abyss")),
        ("environment/tilesets/abyss/abyss-ground.png", 128, 128, lambda d, w, h: draw_themed_ground(d, w, h, "abyss")),
        ("environment/tilesets/abyss/abyss-platform.png", 128, 64, lambda d, w, h: draw_themed_platform(d, w, h, "abyss")),
        ("environment/tilesets/abyss/abyss-wall.png", 128, 128, lambda d, w, h: draw_themed_wall(d, w, h, "abyss")),
        # Capital
        ("environment/tilesets/capital/capital-background.png", 128, 128, lambda d, w, h: draw_themed_background(d, w, h, "capital")),
        ("environment/tilesets/capital/capital-ground.png", 128, 128, lambda d, w, h: draw_themed_ground(d, w, h, "capital")),
        ("environment/tilesets/capital/capital-platform.png", 128, 64, lambda d, w, h: draw_themed_platform(d, w, h, "capital")),
        ("environment/tilesets/capital/capital-wall.png", 128, 128, lambda d, w, h: draw_themed_wall(d, w, h, "capital")),
        # Cathedral
        ("environment/tilesets/cathedral/cathedral-background.png", 128, 128, lambda d, w, h: draw_themed_background(d, w, h, "cathedral")),
        ("environment/tilesets/cathedral/cathedral-ground.png", 128, 128, lambda d, w, h: draw_themed_ground(d, w, h, "cathedral")),
        ("environment/tilesets/cathedral/cathedral-platform.png", 128, 64, lambda d, w, h: draw_themed_platform(d, w, h, "cathedral")),
        ("environment/tilesets/cathedral/cathedral-wall.png", 128, 128, lambda d, w, h: draw_themed_wall(d, w, h, "cathedral")),
        # Forest
        ("environment/tilesets/forest/forest-background.png", 128, 128, lambda d, w, h: draw_themed_background(d, w, h, "forest")),
        ("environment/tilesets/forest/forest-ground.png", 128, 128, lambda d, w, h: draw_themed_ground(d, w, h, "forest")),
        ("environment/tilesets/forest/forest-platform.png", 128, 64, lambda d, w, h: draw_themed_platform(d, w, h, "forest")),
        ("environment/tilesets/forest/forest-wall.png", 128, 128, lambda d, w, h: draw_themed_wall(d, w, h, "forest")),
        # Heart
        ("environment/tilesets/heart/heart-background.png", 128, 128, lambda d, w, h: draw_themed_background(d, w, h, "heart")),
        ("environment/tilesets/heart/heart-ground.png", 128, 128, lambda d, w, h: draw_themed_ground(d, w, h, "heart")),
        ("environment/tilesets/heart/heart-platform.png", 128, 64, lambda d, w, h: draw_themed_platform(d, w, h, "heart")),
        ("environment/tilesets/heart/heart-wall.png", 128, 128, lambda d, w, h: draw_themed_wall(d, w, h, "heart")),
        # Mines
        ("environment/tilesets/mines/mines-background.png", 128, 128, lambda d, w, h: draw_themed_background(d, w, h, "mines")),
        ("environment/tilesets/mines/mines-ground.png", 128, 128, lambda d, w, h: draw_themed_ground(d, w, h, "mines")),
        ("environment/tilesets/mines/mines-platform.png", 128, 64, lambda d, w, h: draw_themed_platform(d, w, h, "mines")),
        ("environment/tilesets/mines/mines-wall.png", 128, 128, lambda d, w, h: draw_themed_wall(d, w, h, "mines")),
        # Palace
        ("environment/tilesets/palace/palace-background.png", 128, 128, lambda d, w, h: draw_themed_background(d, w, h, "palace")),
        ("environment/tilesets/palace/palace-ground.png", 128, 128, lambda d, w, h: draw_themed_ground(d, w, h, "palace")),
        ("environment/tilesets/palace/palace-platform.png", 128, 64, lambda d, w, h: draw_themed_platform(d, w, h, "palace")),
        ("environment/tilesets/palace/palace-wall.png", 128, 128, lambda d, w, h: draw_themed_wall(d, w, h, "palace")),
        # Temple
        ("environment/tilesets/temple/temple-background.png", 128, 128, lambda d, w, h: draw_themed_background(d, w, h, "temple")),
        ("environment/tilesets/temple/temple-ground.png", 128, 128, lambda d, w, h: draw_themed_ground(d, w, h, "temple")),
        ("environment/tilesets/temple/temple-platform.png", 128, 64, lambda d, w, h: draw_themed_platform(d, w, h, "temple")),
        ("environment/tilesets/temple/temple-wall.png", 128, 128, lambda d, w, h: draw_themed_wall(d, w, h, "temple")),

        # Amulets (13 files)
        ("items/amulets/abyss-gaze.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "abyss-gaze")),
        ("items/amulets/ash-affinity.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "ash-affinity")),
        ("items/amulets/ash-blood.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "ash-blood")),
        ("items/amulets/ash-vision.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "ash-vision")),
        ("items/amulets/fire-resist.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "fire-resist")),
        ("items/amulets/holy-range.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "holy-range")),
        ("items/amulets/iron-wall.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "iron-wall")),
        ("items/amulets/quake-range.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "quake-range")),
        ("items/amulets/range-master.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "range-master")),
        ("items/amulets/shadow-dodge.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "shadow-dodge")),
        ("items/amulets/shadow-extend.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "shadow-extend")),
        ("items/amulets/soul-keeper.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "soul-keeper")),
        ("items/amulets/vampire.png", 32, 32, lambda d, w, h: draw_amulet(d, w, h, "vampire")),

        # Consumables (7 files)
        ("items/consumables/antidote.png", 32, 32, lambda d, w, h: draw_consumable(d, w, h, "antidote")),
        ("items/consumables/curse-cure.png", 32, 32, lambda d, w, h: draw_consumable(d, w, h, "curse-cure")),
        ("items/consumables/fire-pot.png", 32, 32, lambda d, w, h: draw_consumable(d, w, h, "fire-pot")),
        ("items/consumables/focus-potion.png", 32, 32, lambda d, w, h: draw_consumable(d, w, h, "focus-potion")),
        ("items/consumables/moss.png", 32, 32, lambda d, w, h: draw_consumable(d, w, h, "moss")),
        ("items/consumables/poison-pot.png", 32, 32, lambda d, w, h: draw_consumable(d, w, h, "poison-pot")),
        ("items/consumables/return-bone.png", 32, 32, lambda d, w, h: draw_consumable(d, w, h, "return-bone")),

        # Weapons (21 files)
        # Axes (4)
        ("items/weapons/axes/ash-axe.png", 64, 64, lambda d, w, h: draw_weapon_axe(d, w, h, "ash")),
        ("items/weapons/axes/bone-hammer.png", 64, 64, lambda d, w, h: draw_weapon_axe(d, w, h, "bone")),
        ("items/weapons/axes/flame-axe.png", 64, 64, lambda d, w, h: draw_weapon_axe(d, w, h, "flame")),
        ("items/weapons/axes/miner-axe.png", 64, 64, lambda d, w, h: draw_weapon_axe(d, w, h, "miner")),
        # Daggers (4)
        ("items/weapons/daggers/blood-dagger.png", 64, 64, lambda d, w, h: draw_weapon_dagger(d, w, h, "blood")),
        ("items/weapons/daggers/flame-dagger.png", 64, 64, lambda d, w, h: draw_weapon_dagger(d, w, h, "flame")),
        ("items/weapons/daggers/poisoned-knife.png", 64, 64, lambda d, w, h: draw_weapon_dagger(d, w, h, "poisoned")),
        ("items/weapons/daggers/shadow-dagger.png", 64, 64, lambda d, w, h: draw_weapon_dagger(d, w, h, "shadow")),
        # Greatswords (5)
        ("items/weapons/greatswords/abyss-greatsword.png", 64, 64, lambda d, w, h: draw_weapon_greatsword(d, w, h, "abyss")),
        ("items/weapons/greatswords/ash-greatsword.png", 64, 64, lambda d, w, h: draw_weapon_greatsword(d, w, h, "ash")),
        ("items/weapons/greatswords/graveyard-guardian.png", 64, 64, lambda d, w, h: draw_weapon_greatsword(d, w, h, "graveyard")),
        ("items/weapons/greatswords/greatsword.png", 64, 64, lambda d, w, h: draw_weapon_greatsword(d, w, h, "normal")),
        ("items/weapons/greatswords/king-broken-sword.png", 64, 64, lambda d, w, h: draw_weapon_greatsword(d, w, h, "king-broken")),
        # Spears (4)
        ("items/weapons/spears/abyss-spear.png", 64, 64, lambda d, w, h: draw_weapon_spear(d, w, h, "abyss")),
        ("items/weapons/spears/holy-spear.png", 64, 64, lambda d, w, h: draw_weapon_spear(d, w, h, "holy")),
        ("items/weapons/spears/knight-spear.png", 64, 64, lambda d, w, h: draw_weapon_spear(d, w, h, "knight")),
        ("items/weapons/spears/lightning-spear.png", 64, 64, lambda d, w, h: draw_weapon_spear(d, w, h, "lightning")),
        # Staves (4)
        ("items/weapons/staves/abyss-staff.png", 64, 64, lambda d, w, h: draw_weapon_staff(d, w, h, "abyss")),
        ("items/weapons/staves/ash-staff.png", 64, 64, lambda d, w, h: draw_weapon_staff(d, w, h, "ash")),
        ("items/weapons/staves/flame-staff.png", 64, 64, lambda d, w, h: draw_weapon_staff(d, w, h, "flame")),
        ("items/weapons/staves/holy-staff.png", 64, 64, lambda d, w, h: draw_weapon_staff(d, w, h, "holy")),

        # VFX (8 files)
        ("vfx/buff-effect.png", 256, 64, lambda d, w, h: draw_vfx_effect(d, w, h, "buff-effect")),
        ("vfx/dark-explosion.png", 384, 64, lambda d, w, h: draw_vfx_effect(d, w, h, "dark-explosion")),
        ("vfx/dark-slash.png", 256, 64, lambda d, w, h: draw_vfx_effect(d, w, h, "dark-slash")),
        ("vfx/death-particles.png", 256, 64, lambda d, w, h: draw_vfx_effect(d, w, h, "death-particles")),
        ("vfx/fire-explosion.png", 384, 64, lambda d, w, h: draw_vfx_effect(d, w, h, "fire-explosion")),
        ("vfx/heal-effect.png", 256, 64, lambda d, w, h: draw_vfx_effect(d, w, h, "heal-effect")),
        ("vfx/holy-slash.png", 256, 64, lambda d, w, h: draw_vfx_effect(d, w, h, "holy-slash")),
        ("vfx/soul-absorb.png", 256, 64, lambda d, w, h: draw_vfx_effect(d, w, h, "soul-absorb"))
    ]

    print(f"Starting procedural generation of {len(targets)} assets...")
    for rel_path, w, h, draw_func in targets:
        img = make_pixel_art(w, h, draw_func)
        save_image(img, rel_path)
    print("Bulk generation completed successfully!")

if __name__ == "__main__":
    generate_bulk_assets()
