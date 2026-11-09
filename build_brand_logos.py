import os
import ctypes
import math
from PIL import Image, ImageDraw, ImageFilter
import pypdfium2 as pdfium
import pypdfium2.raw as c

PDF_PATH = r"C:\Users\RC A\.gemini\antigravity-ide\brain\7256bb8c-bbc7-409e-b770-067d672e48c0\.user_uploaded\media_1792850043685.pdf"

# App Colors
# Emerald Green Palette:
COLOR_EMERALD_PRIMARY = (13, 92, 58)    # #0D5C3A - Deep Botanical Emerald
COLOR_EMERALD_DARK    = (8, 61, 38)     # #083D26 - Rich Forest
COLOR_EMERALD_MEDIUM  = (22, 121, 79)   # #16794F - Vibrant Leaf Green

# Warm Gold Palette (matching the original PDF's gold tone, perfected):
COLOR_GOLD_RICH       = (196, 160, 82)  # #C4A052 - Warm Champagne Gold
COLOR_GOLD_LIGHT      = (222, 188, 114) # #DEBC72 - Lustrous Gold Highlight

def render_vector_element(green_rgb, gold_rgb, include_wordmark=True, scale=8):
    """Render vector elements directly from PDFium with exact colors and zero artifacts."""
    pdf = pdfium.PdfDocument(PDF_PATH)
    page = pdf[0]
    objs = list(page.get_objects())
    
    # Obj 0 is the background rectangle - remove it for 100% transparent vector rendering
    c.FPDFPage_RemoveObject(page.raw, objs[0].raw)
    
    if not include_wordmark:
        for o in objs[15:]: # Objs 15..21 are the letters 'EVERYFY'
            c.FPDFPage_RemoveObject(page.raw, o.raw)
            
    for obj in page.get_objects():
        raw = obj.raw
        fr, fg, fb, fa = ctypes.c_uint(), ctypes.c_uint(), ctypes.c_uint(), ctypes.c_uint()
        c.FPDFPageObj_GetFillColor(raw, ctypes.byref(fr), ctypes.byref(fg), ctypes.byref(fb), ctypes.byref(fa))
        
        # In original PDF: Maroon = 83 or 105, Gold = 191
        if fr.value in (83, 105):
            c.FPDFPageObj_SetFillColor(raw, green_rgb[0], green_rgb[1], green_rgb[2], 255)
        elif fr.value == 191:
            c.FPDFPageObj_SetFillColor(raw, gold_rgb[0], gold_rgb[1], gold_rgb[2], 255)
            
    c.FPDFPage_GenerateContent(page.raw)
    bitmap = page.render(scale=scale, fill_color=(0, 0, 0, 0))
    pil_img = bitmap.to_pil()
    bbox = pil_img.getbbox()
    return pil_img.crop(bbox)

def main():
    print("1. Rendering transparent vector assets at 8x resolution...")
    # Transparent full logo (Icon + Wordmark)
    full_logo = render_vector_element(COLOR_EMERALD_PRIMARY, COLOR_GOLD_RICH, include_wordmark=True, scale=8)
    print(f"   Full logo rendered: {full_logo.size}")
    
    # Transparent icon only (Shopping Bag + 'e' arrow)
    icon_logo = render_vector_element(COLOR_EMERALD_PRIMARY, COLOR_GOLD_RICH, include_wordmark=False, scale=8)
    print(f"   Icon rendered: {icon_logo.size}")
    
    # 2. Build 1024x1024 Master App Icon Tile
    size = 1024
    
    # A. Full Bleed White Master (for Flutter Container/ClipRRect usage)
    # Filling the entire 1024x1024 canvas with pure white ensures Flutter's ClipRRect and BoxShadow
    # match the exact visual boundaries without any transparent corner artifacts.
    tile_bleed = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    
    # Add subtle organic radial glow in top-left for ultra premium depth
    for y in range(size):
        for x in range(size):
            dx = x - 260
            dy = y - 260
            dist = math.sqrt(dx*dx + dy*dy)
            # Softest pearl mint highlight
            if dist < 600:
                factor = (1 - dist / 600) * 0.05
                r = int(255 * (1 - factor) + 245 * factor)
                g = int(255 * (1 - factor) + 252 * factor)
                b = int(255 * (1 - factor) + 248 * factor)
                tile_bleed.putpixel((x, y), (r, g, b, 255))
                
    # Center full logo with elegant padding
    target_w = 780
    target_h = int(target_w * full_logo.height / full_logo.width)
    resized_logo = full_logo.resize((target_w, target_h), Image.Resampling.LANCZOS)
    pos_x = (size - target_w) // 2
    pos_y = (size - target_h) // 2
    tile_bleed.paste(resized_logo, (pos_x, pos_y), resized_logo)
    
    # B. Android Squircle Launcher Icon (with standard Android adaptive margin)
    launcher_canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = Image.new("L", (size, size), 0)
    draw_mask = ImageDraw.Draw(mask)
    margin = 32
    corner_radius = 220
    draw_mask.rounded_rectangle(
        [(margin, margin), (size - margin, size - margin)],
        radius=corner_radius,
        fill=255
    )
    
    # Subtle inner border for the launcher squircle
    tile_launcher = tile_bleed.copy()
    border_draw = ImageDraw.Draw(tile_launcher)
    border_draw.rounded_rectangle(
        [(margin, margin), (size - margin, size - margin)],
        radius=corner_radius,
        outline=(13, 92, 58, 28),
        width=8
    )
    launcher_icon = Image.composite(tile_launcher, launcher_canvas, mask)
    
    # 3. Save Master Assets in d:\freshUp
    full_logo.save(r"d:\freshUp\everyfy_brand_logo_transparent.png", "PNG")
    icon_logo.save(r"d:\freshUp\everyfy_brand_icon_transparent.png", "PNG")
    tile_bleed.save(r"d:\freshUp\everyfy_app_logo.png", "PNG")
    launcher_icon.save(r"d:\freshUp\everyfy_launcher_icon.png", "PNG")
    print("   Master logos saved in d:\\freshUp")
    
    # 4. Save to Flutter customer_app assets
    customer_assets_dir = r"d:\freshUp\freshup_app\customer_app\assets\images"
    os.makedirs(customer_assets_dir, exist_ok=True)
    
    # app_logo.png is the primary asset used in Flutter
    tile_bleed.save(os.path.join(customer_assets_dir, "app_logo.png"), "PNG")
    full_logo.save(os.path.join(customer_assets_dir, "app_logo_full.png"), "PNG")
    icon_logo.save(os.path.join(customer_assets_dir, "app_logo_icon.png"), "PNG")
    launcher_icon.save(os.path.join(customer_assets_dir, "app_logo_squircle.png"), "PNG")
    print(f"   Saved app_logo.png and variants to {customer_assets_dir}")
    
    # 5. Android mipmap launcher icons
    mipmaps = {
        r"d:\freshUp\freshup_app\customer_app\android\app\src\main\res\mipmap-mdpi": 48,
        r"d:\freshUp\freshup_app\customer_app\android\app\src\main\res\mipmap-hdpi": 72,
        r"d:\freshUp\freshup_app\customer_app\android\app\src\main\res\mipmap-xhdpi": 96,
        r"d:\freshUp\freshup_app\customer_app\android\app\src\main\res\mipmap-xxhdpi": 144,
        r"d:\freshUp\freshup_app\customer_app\android\app\src\main\res\mipmap-xxxhdpi": 192,
    }
    
    for folder, px in mipmaps.items():
        os.makedirs(folder, exist_ok=True)
        resized = launcher_icon.resize((px, px), Image.Resampling.LANCZOS)
        target_file = os.path.join(folder, "ic_launcher.png")
        resized.save(target_file, "PNG")
        print(f"   Android {px}x{px} -> {target_file}")
        
    # 6. Web icons & favicon
    web_dir = r"d:\freshUp\freshup_app\customer_app\web"
    if os.path.exists(web_dir):
        fav = launcher_icon.resize((64, 64), Image.Resampling.LANCZOS)
        fav.save(os.path.join(web_dir, "favicon.png"), "PNG")
        print(f"   Web favicon saved")
        
        web_icons_dir = os.path.join(web_dir, "icons")
        if os.path.exists(web_icons_dir):
            for icon_name, px in [
                ("Icon-192.png", 192),
                ("Icon-512.png", 512),
                ("Icon-maskable-192.png", 192),
                ("Icon-maskable-512.png", 512),
            ]:
                ic = (launcher_icon if "maskable" in icon_name else tile_bleed).resize((px, px), Image.Resampling.LANCZOS)
                ic.save(os.path.join(web_icons_dir, icon_name), "PNG")
                print(f"   Web {icon_name} ({px}x{px}) saved")

    # 7. Copy to Artifacts for User Review
    artifact_dir = r"C:\Users\RC A\.gemini\antigravity-ide\brain\7256bb8c-bbc7-409e-b770-067d672e48c0"
    tile_bleed.save(os.path.join(artifact_dir, "new_everyfy_logo_preview.png"), "PNG")
    full_logo.save(os.path.join(artifact_dir, "new_everyfy_full_transparent.png"), "PNG")
    launcher_icon.save(os.path.join(artifact_dir, "new_everyfy_launcher_icon.png"), "PNG")
    print(f"   Artifact previews saved in {artifact_dir}")
    print("ALL ASSETS GENERATED AND UPDATED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
