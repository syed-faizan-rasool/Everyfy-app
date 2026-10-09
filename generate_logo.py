import math
import os
from PIL import Image, ImageDraw, ImageFilter

def create_everyfy_logo():
    size = 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    # 1. Base Gradient Canvas (Super-ellipse / rounded squircle)
    # Gradient: Top-left #09472B -> Bottom-right #10B981
    gradient = Image.new("RGBA", (size, size))
    draw_grad = ImageDraw.Draw(gradient)
    
    c_start = (9, 75, 45)      # Deep Forest Emerald
    c_end = (16, 185, 129)     # Vibrant Fresh Mint
    
    for y in range(size):
        for x in range(size):
            # Diagonal gradient factor
            factor = (x + y) / (2 * size)
            r = int(c_start[0] + (c_end[0] - c_start[0]) * factor)
            g = int(c_start[1] + (c_end[1] - c_start[1]) * factor)
            b = int(c_start[2] + (c_end[2] - c_start[2]) * factor)
            # Add subtle radial shine in top-left
            dx = x - 280
            dy = y - 280
            dist = math.sqrt(dx*dx + dy*dy)
            shine = max(0, int(35 * (1 - dist / 500)))
            r = min(255, r + shine)
            g = min(255, g + shine)
            b = min(255, b + shine)
            gradient.putpixel((x, y), (r, g, b, 255))
            
    # Rounded squircle mask
    mask = Image.new("L", (size, size), 0)
    draw_mask = ImageDraw.Draw(mask)
    margin = 40
    corner_radius = 240
    draw_mask.rounded_rectangle(
        [(margin, margin), (size - margin, size - margin)],
        radius=corner_radius,
        fill=255
    )
    
    # Apply mask to gradient
    base = Image.composite(gradient, img, mask)
    
    # Draw soft inner border glow
    border_draw = ImageDraw.Draw(base)
    border_draw.rounded_rectangle(
        [(margin, margin), (size - margin, size - margin)],
        radius=corner_radius,
        outline=(255, 255, 255, 50),
        width=8
    )
    
    # 2. Add modern 3D Shadow layer for the central grocery illustration
    shadow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_layer)
    
    # Main illustration centers around (512, 540)
    # Basket shadow
    s_draw.ellipse([300, 720, 724, 820], fill=(0, 30, 15, 110))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(32))
    base = Image.alpha_composite(base, shadow_layer)
    
    # 3. Illustration layer
    illus = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(illus)
    
    # --- GROCERY PRODUCE ITEMS (Poking out of the basket) ---
    
    # A. Fresh Golden Orange / Citrus (Right side)
    draw.ellipse([540, 380, 730, 570], fill=(245, 158, 11, 255)) # Vibrant Amber Orange
    # Orange highlight
    draw.ellipse([570, 400, 640, 470], fill=(251, 191, 36, 180))
    
    # B. Fresh Crisp Red Apple (Left side)
    draw.ellipse([310, 370, 530, 580], fill=(239, 68, 68, 255)) # Rich Crimson Red
    draw.ellipse([360, 370, 560, 580], fill=(220, 38, 38, 255))
    # Apple highlight
    draw.ellipse([340, 400, 410, 460], fill=(254, 202, 202, 190))
    # Little stem
    draw.rectangle([435, 330, 447, 380], fill=(120, 53, 15, 255))
    
    # C. Fresh Organic Leaf (Center top sprouting)
    leaf_polygon = [
        (445, 350),
        (480, 310),
        (540, 310),
        (560, 340),
        (520, 370),
        (450, 360)
    ]
    draw.polygon(leaf_polygon, fill=(74, 222, 128, 255))
    
    # Another small leaf
    draw.polygon([(430, 350), (400, 320), (370, 330), (390, 360)], fill=(34, 197, 94, 255))
    
    # --- SLEEK WHITE SHOPPING BASKET / BAG ---
    # Basket Handle (Arc at top)
    draw.arc([370, 360, 654, 580], start=180, end=360, fill=(255, 255, 255, 255), width=28)
    
    # Basket Body - Trapeze with rounded base
    basket_poly = [
        (260, 500), # Top-left
        (764, 500), # Top-right
        (710, 740), # Bottom-right
        (314, 740), # Bottom-left
    ]
    draw.polygon(basket_poly, fill=(255, 255, 255, 255))
    
    # Basket Bottom Rounded Corner
    draw.rounded_rectangle([300, 490, 724, 755], radius=48, fill=(255, 255, 255, 255))
    
    # Rim Accent Line (Subtle top rim shadow)
    draw.rounded_rectangle([250, 485, 774, 515], radius=14, fill=(241, 245, 249, 255))
    
    # --- MODERN "E" / SMILE / SPEED ACCENT ON BASKET ---
    # Dynamic curved swoosh representing Fresh speed & smile
    draw.arc([360, 560, 664, 690], start=20, end=160, fill=(16, 185, 129, 255), width=24)
    # Smile dot accent / leaf tip
    draw.ellipse([640, 595, 665, 620], fill=(245, 158, 11, 255))
    
    # Combine illustration onto base
    final_icon = Image.alpha_composite(base, illus)
    
    # Save master 1024x1024 logo
    master_path = r"d:\freshUp\everyfy_app_logo.png"
    final_icon.save(master_path, "PNG")
    print(f"Master logo saved: {master_path}")
    
    # Save to customer_app assets
    assets_dir = r"d:\freshUp\freshup_app\customer_app\assets\images"
    os.makedirs(assets_dir, exist_ok=True)
    final_icon.save(os.path.join(assets_dir, "app_logo.png"), "PNG")
    
    # Android mipmap icons sizes
    mipmaps = {
        r"d:\freshUp\freshup_app\customer_app\android\app\src\main\res\mipmap-mdpi": 48,
        r"d:\freshUp\freshup_app\customer_app\android\app\src\main\res\mipmap-hdpi": 72,
        r"d:\freshUp\freshup_app\customer_app\android\app\src\main\res\mipmap-xhdpi": 96,
        r"d:\freshUp\freshup_app\customer_app\android\app\src\main\res\mipmap-xxhdpi": 144,
        r"d:\freshUp\freshup_app\customer_app\android\app\src\main\res\mipmap-xxxhdpi": 192,
    }
    
    for folder, px in mipmaps.items():
        os.makedirs(folder, exist_ok=True)
        resized = final_icon.resize((px, px), Image.Resampling.LANCZOS)
        target_file = os.path.join(folder, "ic_launcher.png")
        resized.save(target_file, "PNG")
        print(f"Saved {px}x{px} -> {target_file}")

if __name__ == "__main__":
    create_everyfy_logo()
