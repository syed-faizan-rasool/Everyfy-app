import os
import shutil
import json
from PIL import Image

SRC_DIR = r"C:\Users\RC A\Downloads\Scan Picture\Scan Picture"

FLUTTER_ASSETS_DIR = r"d:\freshUp\freshup_app\customer_app\assets\images"
FLUTTER_PRODUCTS_DIR = os.path.join(FLUTTER_ASSETS_DIR, "products")
FLUTTER_CATEGORIES_DIR = os.path.join(FLUTTER_ASSETS_DIR, "categories")

BACKEND_DIR = r"d:\freshUp\backend"
BACKEND_UPLOADS_PRODUCTS = os.path.join(BACKEND_DIR, "uploads", "products")
BACKEND_UPLOADS_CATEGORIES = os.path.join(BACKEND_DIR, "uploads", "categories")

for d in [FLUTTER_PRODUCTS_DIR, FLUTTER_CATEGORIES_DIR, BACKEND_UPLOADS_PRODUCTS, BACKEND_UPLOADS_CATEGORIES]:
    os.makedirs(d, exist_ok=True)

# 16 Categories matching user's exact folder list
CATEGORIES = [
    {"id": 1, "name": "Baby care", "slug": "baby_care", "unit": "1 Pack", "icon_color": "#FF80AB"},
    {"id": 2, "name": "Beverages", "slug": "beverages", "unit": "1 Cup", "icon_color": "#8D6E63"},
    {"id": 3, "name": "Breakfast - dairy", "slug": "breakfast_dairy", "unit": "1 Pack", "icon_color": "#FFD54F"},
    {"id": 4, "name": "Dry fruits", "slug": "dry_fruits", "unit": "500 g", "icon_color": "#FFA726"},
    {"id": 5, "name": "Electronics", "slug": "electronics", "unit": "1 pcs", "icon_color": "#42A5F5"},
    {"id": 6, "name": "Entertainment", "slug": "entertainment", "unit": "1 pcs", "icon_color": "#AB47BC"},
    {"id": 7, "name": "Fast Food", "slug": "fast_food", "unit": "1 Serving", "icon_color": "#FF7043"},
    {"id": 8, "name": "Fruits", "slug": "fruits", "unit": "1 kg", "icon_color": "#66BB6A"},
    {"id": 9, "name": "Gojra special", "slug": "gojra_special", "unit": "1 Plate", "icon_color": "#26A69A"},
    {"id": 10, "name": "Grossery", "slug": "grossery", "unit": "1 kg", "icon_color": "#78909C"},
    {"id": 11, "name": "Health & beauty", "slug": "health_beauty", "unit": "500 g", "icon_color": "#EC407A"},
    {"id": 12, "name": "House hold", "slug": "house_hold", "unit": "1 Pack", "icon_color": "#5C6BC0"},
    {"id": 13, "name": "Personal care", "slug": "personal_care", "unit": "1 pcs", "icon_color": "#26C6DA"},
    {"id": 14, "name": "Stationary", "slug": "stationary", "unit": "1 pcs", "icon_color": "#9CCC65"},
    {"id": 15, "name": "Sweets", "slug": "sweets", "unit": "500 g", "icon_color": "#EF5350"},
    {"id": 16, "name": "Vegetables", "slug": "vegetables", "unit": "1 kg", "icon_color": "#4CAF50"},
]

# Category lookup by folder name
CAT_BY_FOLDER = {
    "Baby care": 1,
    "Beverages": 2,
    "Breakfast - dairy": 3,
    "Dry fruits": 4,
    "Electronics": 5,
    "Entertainment": 6,
    "Fast Food": 7,
    "Fruits": 8,
    "Gojra special": 9,
    "Grossery": 10,
    "Health & beauty": 11,
    "House hold": 12,
    "Personal care": 13,
    "Stationary": 14,
    "Sweets": 15,
    "Vegetables": 16,
}

# Specific product naming dictionary
ITEM_NAMES = {
    # Beverages
    ("Beverages", "187.jpg"): ("Nescafe Classic Hot Coffee", "1 Cup", "Rich aromatic hot coffee brewed with Nescafe Classic roast."),
    ("Beverages", "188.jpg"): ("Karak Doodh Patti Chai & Biscuits", "1 Cup", "Traditional strong Pakistani milk tea served fresh with crispy Parle-G biscuits."),

    # Fruits
    ("Fruits", "123.jpg"): ("Fresh Royal Jamun (Black Plum)", "1 kg", "Juicy, sweet and slightly tangy handpicked black plums."),
    ("Fruits", "124.jpg"): ("Fresh Farm Strawberries", "500 g", "Vibrant red, fragrant, sweet strawberries freshly harvested."),
    ("Fruits", "125.jpg"): ("Kandhari Red Pomegranate (Anar)", "1 kg", "Deep ruby red, crisp sweet pomegranate seeds rich in antioxidants."),
    ("Fruits", "126.jpg"): ("Swat Valley Fresh Peaches (Aaroo)", "1 kg", "Soft, succulent and aromatic sweet peaches hand-sorted."),
    ("Fruits", "127.jpg"): ("Seedless Green Grapes (Angoor)", "1 kg", "Crisp, sweet, and seedless premium table grapes."),
    ("Fruits", "128.jpg"): ("Fresh Farm Guava (Amrood)", "1 kg", "Crunchy and fragrant white-fleshed local sweet guavas."),
    ("Fruits", "129.jpg"): ("Green Pear (Nashpati)", "1 kg", "Juicy, sweet and crisp farm-grown fresh pears."),
    ("Fruits", "130.jpg"): ("Fresh Red Cherries", "500 g", "Plump, sweet, and glossy deep-red premium cherries."),
    ("Fruits", "131.jpg"): ("Sugar Baby Watermelon (Tarbooz)", "1 Whole", "Crisp, intensely sweet and refreshing red watermelon."),
    ("Fruits", "132.jpg"): ("Juicy Citrus Oranges / Kino", "1 Dozen", "Sun-ripened, citrusy, vitamin-C rich fresh Pakistani kinnow."),

    # Gojra Special
    ("Gojra special", "167.jpg"): ("Gojra Special Gol Gappay Platter", "1 Plate (10 Pcs)", "Crispy puris filled with spiced chickpeas, potatoes, and zesty khatta meetha pani."),

    # Fast Food
    ("Fast Food", "166.jpg"): ("Chicken Shawarma Pita Wrap", "1 Roll", "Slow-roasted tender chicken with garlic mayo, crisp lettuce in soft pita wrap."),

    # Sweets
    ("Sweets", "169.jpg"): ("Fresh Baked Golden Bread Loaf", "1 Loaf", "Oven-fresh sliced white bread loaf with soft crust and pillowy texture."),

    # Health & Beauty
    ("Health & beauty", "159.jpg"): ("100% Pure Natural Honeycomb Jar", "500 g", "Unprocessed pure raw honey with natural honeycomb section."),

    # Vegetables
    ("Vegetables", "95.jpg"): ("Fresh Green Chilies (Hari Mirch)", "500 g", "Crisp, spicy, farm-fresh vibrant green chilies."),

    # Dry fruits
    ("Dry fruits", "141.jpg"): ("Kashmiri Mountain Walnuts (Akhrot)", "500 g", "Premium thin-shelled whole walnuts with rich buttery halves."),

    # Breakfast - dairy
    ("Breakfast - dairy", "143.jpg"): ("Fresh Roghani Naan / Sesame Kulcha", "2 Pcs", "Tandoor-baked soft and buttery naan topped with sesame seeds and fresh coriander."),

    # Stationary
    ("Stationary", "57.jpg"): ("Heavy Duty Multi-Color Duct Tape", "1 Roll", "Strong adhesive waterproof colored duct tape for repairs, packaging and crafts."),

    # Grossery
    ("Grossery", "1.jpg"): ("Organic Tej Patta (Bay Leaves)", "100 g", "Aromatic dried bay leaves for traditional biryani, pulao and gravies.")
}

def generate_clean_name(folder, filename, index):
    if (folder, filename) in ITEM_NAMES:
        return ITEM_NAMES[(folder, filename)]

    num = os.path.splitext(filename)[0]
    base_cat = folder.replace("Grossery", "Grocery").replace("Stationary", "Stationery")
    
    # Generic descriptive template
    name = f"{base_cat} Item #{num}"
    unit = "1 Pack"
    desc = f"Premium quality {base_cat.lower()} item hand-selected for Everyfy customers."
    
    if folder == "Vegetables":
        unit = "1 kg"
        desc = "Farm-fresh hand-sorted vegetable harvested daily for optimal freshness."
        name = f"Fresh Farm Vegetable #{num}"
    elif folder == "Fruits":
        unit = "1 kg"
        desc = "Naturally ripened sweet and succulent orchard fruit."
        name = f"Premium Seasonal Fruit #{num}"
    elif folder == "Dry fruits":
        unit = "250 g"
        desc = "High-grade dry fruit rich in natural nutrition and vitamins."
        name = f"Premium Dry Fruit #{num}"
    elif folder == "Fast Food":
        unit = "1 Serving"
        desc = "Freshly prepared sizzling hot snack made with premium ingredients."
        name = f"Hot Fast Food #{num}"
    elif folder == "Sweets":
        unit = "500 g"
        desc = "Freshly prepared traditional sweet confectionery."
        name = f"Artisanal Sweet #{num}"
    elif folder == "Gojra special":
        unit = "1 Plate"
        desc = "Traditional authentic Gojra specialty prepared using generational recipes."
        name = f"Gojra Special Treat #{num}"
    elif folder == "Breakfast - dairy":
        unit = "1 Pack"
        desc = "Morning breakfast and dairy essential delivered fresh."
        name = f"Breakfast Essential #{num}"
    elif folder == "Stationary":
        unit = "1 pcs"
        desc = "Reliable stationery item for school, home, and office use."
        name = f"Stationery Essential #{num}"
    elif folder == "Grossery":
        unit = "1 kg" if index % 3 == 0 else ("500 g" if index % 3 == 1 else "1 Pack")
        desc = "Essential kitchen staple for daily cooking and household groceries."
        name = f"Kitchen Grocery #{num}"

    return (name, unit, desc)

def main():
    print("Starting Everyfy Live Catalog Asset Generator...")
    products = []
    category_covers = {}
    product_id = 1

    for cat_folder in sorted(os.listdir(SRC_DIR)):
        cat_path = os.path.join(SRC_DIR, cat_folder)
        if not os.path.isdir(cat_path):
            continue
            
        cat_id = CAT_BY_FOLDER.get(cat_folder, 10)
        slug = next((c["slug"] for c in CATEGORIES if c["id"] == cat_id), "grocery")
        
        files = sorted(os.listdir(cat_path), key=lambda x: int(os.path.splitext(x)[0]) if os.path.splitext(x)[0].isdigit() else 999)
        print(f"\nProcessing Category: {cat_folder} (ID: {cat_id}) - {len(files)} items")

        first_img_target = None

        for idx, f in enumerate(files):
            src_file = os.path.join(cat_path, f)
            ext = os.path.splitext(f)[1].lower()
            if ext not in [".jpg", ".jpeg", ".png", ".webp"]:
                continue
                
            clean_filename = f"prod_{cat_id}_{os.path.splitext(f)[0]}{ext}"
            
            # Destination file paths
            flutter_prod_path = os.path.join(FLUTTER_PRODUCTS_DIR, clean_filename)
            backend_prod_path = os.path.join(BACKEND_UPLOADS_PRODUCTS, clean_filename)
            
            # Copy & optimize image (ensure standard max 1024x1024 RGB JPEG)
            with Image.open(src_file) as img:
                img_rgb = img.convert("RGB")
                if img_rgb.width > 1200 or img_rgb.height > 1200:
                    img_rgb.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
                img_rgb.save(flutter_prod_path, "JPEG", quality=88, optimize=True)
                img_rgb.save(backend_prod_path, "JPEG", quality=88, optimize=True)

            if first_img_target is None:
                first_img_target = clean_filename

            pname, punit, pdesc = generate_clean_name(cat_folder, f, idx)

            products.append({
                "id": product_id,
                "category_id": cat_id,
                "name": pname,
                "description": pdesc,
                "image": f"assets/images/products/{clean_filename}",
                "backend_image": f"uploads/products/{clean_filename}",
                "price": 0.0,  # "Decided soon"
                "discount_price": None,
                "unit": punit,
                "stock_qty": 50,
                "is_featured": 1 if idx < 2 else 0,
                "is_available": 1
            })
            product_id += 1

        if first_img_target:
            category_covers[cat_id] = first_img_target

    # Create category covers in assets/images/categories and backend/uploads/categories
    for c in CATEGORIES:
        cid = c["id"]
        cslug = c["slug"]
        cat_img_name = f"cat_{cid}_{cslug}.jpg"
        flutter_cat_path = os.path.join(FLUTTER_CATEGORIES_DIR, cat_img_name)
        backend_cat_path = os.path.join(BACKEND_UPLOADS_CATEGORIES, cat_img_name)

        if cid in category_covers:
            # Copy best image from products
            src_prod = os.path.join(FLUTTER_PRODUCTS_DIR, category_covers[cid])
            shutil.copyfile(src_prod, flutter_cat_path)
            shutil.copyfile(src_prod, backend_cat_path)
        else:
            # Generate placeholder emblem image for empty categories
            img = Image.new("RGB", (600, 600), (248, 250, 252))
            img.save(flutter_cat_path, "JPEG", quality=90)
            img.save(backend_cat_path, "JPEG", quality=90)
            
        c["image"] = f"assets/images/categories/{cat_img_name}"
        c["backend_image"] = f"uploads/categories/{cat_img_name}"

    print(f"\nTotal Processed Products: {len(products)}")
    print(f"Total Processed Categories: {len(CATEGORIES)}")

    # Write products JSON artifact
    json_path = r"d:\freshUp\freshup_app\customer_app\assets\images\catalog_manifest.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump({"categories": CATEGORIES, "products": products}, f, indent=2)
    print(f"Saved manifest to {json_path}")

    # Generate Dart code for DummyData
    dart_code_path = r"d:\freshUp\freshup_app\customer_app\lib\data\dummy_data.dart"
    generate_dart_file(dart_code_path, CATEGORIES, products)
    print(f"Updated Flutter DummyData at {dart_code_path}")

    # Generate SQL inserts for backend
    sql_path = r"d:\freshUp\backend\database\everyfy_catalog_seed.sql"
    generate_sql_file(sql_path, CATEGORIES, products)
    print(f"Generated SQL Seed at {sql_path}")

def generate_dart_file(target_file, categories, products):
    lines = [
        "import '../models/category_model.dart';",
        "import '../models/product_model.dart';",
        "",
        "/// Real Everyfy Catalog populated directly from user scanned inventory.",
        "/// Real categories and real photographed products with 'Decided soon' pricing.",
        "class DummyData {",
        "  static final List<CategoryModel> categories = [",
    ]
    for c in categories:
        lines.append(f"    CategoryModel(")
        lines.append(f"      id: {c['id']},")
        lines.append(f"      name: '{c['name']}',")
        lines.append(f"      image: '{c['image']}',")
        lines.append(f"    ),")
    lines.append("  ];")
    lines.append("")
    lines.append("  static final List<ProductModel> products = [")
    for p in products:
        pname = p['name'].replace("'", "\\'")
        pdesc = p['description'].replace("'", "\\'")
        punit = p['unit'].replace("'", "\\'")
        pimg = p['image']
        lines.append(f"    ProductModel(")
        lines.append(f"      id: {p['id']},")
        lines.append(f"      categoryId: {p['category_id']},")
        lines.append(f"      name: '{pname}',")
        lines.append(f"      description: '{pdesc}',")
        lines.append(f"      image: '{pimg}',")
        lines.append(f"      price: {p['price']},")
        lines.append(f"      unit: '{punit}',")
        lines.append(f"      stockQty: {p['stock_qty']},")
        lines.append(f"    ),")
    lines.append("  ];")
    lines.append("}")
    lines.append("")

    with open(target_file, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

def generate_sql_file(target_file, categories, products):
    lines = [
        "-- Everyfy Scanned Catalog Seed",
        "SET FOREIGN_KEY_CHECKS = 0;",
        "TRUNCATE TABLE categories;",
        "TRUNCATE TABLE products;",
        "SET FOREIGN_KEY_CHECKS = 1;",
        "",
        "-- 1. Categories Seed",
        "INSERT INTO `categories` (`id`, `name`, `image`, `sort_order`, `is_active`) VALUES",
    ]
    cat_rows = []
    for c in categories:
        name_esc = c['name'].replace("'", "''")
        img_esc = c['backend_image']
        cat_rows.append(f"({c['id']}, '{name_esc}', '{img_esc}', {c['id']}, 1)")
    lines.append(",\n".join(cat_rows) + ";")
    lines.append("")
    lines.append("-- 2. Products Seed (189 Live Scanned Products)")
    lines.append("INSERT INTO `products` (`id`, `category_id`, `name`, `description`, `image`, `price`, `discount_price`, `unit`, `stock_qty`, `is_featured`, `is_available`) VALUES")
    
    prod_rows = []
    for p in products:
        pname_esc = p['name'].replace("'", "''")
        pdesc_esc = p['description'].replace("'", "''")
        punit_esc = p['unit'].replace("'", "''")
        pimg_esc = p['backend_image']
        prod_rows.append(f"({p['id']}, {p['category_id']}, '{pname_esc}', '{pdesc_esc}', '{pimg_esc}', 0.00, NULL, '{punit_esc}', {p['stock_qty']}, {p['is_featured']}, 1)")
    lines.append(",\n".join(prod_rows) + ";")
    lines.append("")

    with open(target_file, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

if __name__ == "__main__":
    main()
