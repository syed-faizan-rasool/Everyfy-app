<?php
$pageTitle = 'Products Catalog';
$pageHeading = 'Grocery Products Management';
require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/../helpers/upload.php';

$pdo = Database::getConnection();
$message = '';

// Handle Product Actions (Add, Edit, Delete)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $action = $_POST['action'];

    if ($action === 'save_product') {
        $id            = (int)($_POST['id'] ?? 0);
        $categoryId    = (int)($_POST['category_id'] ?? 1);
        $name          = trim($_POST['name'] ?? '');
        $description   = trim($_POST['description'] ?? '');
        $price         = (float)($_POST['price'] ?? 0);
        $discountPrice = !empty($_POST['discount_price']) ? (float)$_POST['discount_price'] : null;
        $unit          = trim($_POST['unit'] ?? '1 kg');
        $stockQty      = (int)($_POST['stock_qty'] ?? 50);
        $isFeatured    = !empty($_POST['is_featured']) ? 1 : 0;
        $isAvailable   = !empty($_POST['is_available']) ? 1 : 0;
        $image         = trim($_POST['image'] ?? '');

        // Image file upload
        if (isset($_FILES['image_file']) && $_FILES['image_file']['error'] === UPLOAD_ERR_OK) {
            $up = UploadHelper::uploadImage('image_file', 'products');
            if ($up['success']) {
                $image = $up['url'];
            }
        }

        if (empty($image)) {
            $image = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500';
        }

        try {
            if ($id > 0) {
                $sql = "UPDATE products SET category_id = ?, name = ?, description = ?, image = ?, price = ?, discount_price = ?, unit = ?, stock_qty = ?, is_featured = ?, is_available = ? WHERE id = ?";
                $pdo->prepare($sql)->execute([$categoryId, $name, $description, $image, $price, $discountPrice, $unit, $stockQty, $isFeatured, $isAvailable, $id]);
                $message = "Product '{$name}' updated successfully!";
            } else {
                $sql = "INSERT INTO products (category_id, name, description, image, price, discount_price, unit, stock_qty, is_featured, is_available) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                $pdo->prepare($sql)->execute([$categoryId, $name, $description, $image, $price, $discountPrice, $unit, $stockQty, $isFeatured, $isAvailable]);
                $message = "New product '{$name}' added to store!";
            }
        } catch (PDOException $e) {
            $message = "Error: " . $e->getMessage();
        }
    } elseif ($action === 'delete_product') {
        $id = (int)($_POST['id'] ?? 0);
        try {
            $pdo->prepare("DELETE FROM products WHERE id = ?")->execute([$id]);
            $message = "Product deleted successfully!";
        } catch (PDOException $e) {
            $message = "Error: " . $e->getMessage();
        }
    }
}

// Fetch products & categories
$products = [];
$categories = [];
if ($pdo) {
    try {
        $products = $pdo->query("SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON c.id = p.category_id ORDER BY p.id DESC")->fetchAll();
        $categories = $pdo->query("SELECT id, name FROM categories ORDER BY sort_order ASC")->fetchAll();
    } catch (Exception $e) {}
}
?>

<?php if (!empty($message)): ?>
    <div class="alert alert-success alert-dismissible fade show rounded-3 mb-4" role="alert">
        <?= htmlspecialchars($message) ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
<?php endif; ?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h5 class="fw-bold mb-0">Total Products: <?= count($products) ?></h5>
        <small class="text-muted">Manage grocery catalog, prices, and inventory stock</small>
    </div>
    <button class="btn btn-primary rounded-pill px-4" data-bs-toggle="modal" data-bs-target="#addProductModal">
        <i class="fa-solid fa-plus me-2"></i> Add Product
    </button>
</div>

<!-- Products Table -->
<div class="card border-0 shadow-sm rounded-4 overflow-hidden">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-light">
                <tr class="small text-muted">
                    <th class="ps-4">Product</th>
                    <th>Category</th>
                    <th>Price</th>
                    <th>Discount</th>
                    <th>Stock Qty</th>
                    <th>Status</th>
                    <th class="text-end pe-4">Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($products as $p): ?>
                    <tr>
                        <td class="ps-4">
                            <div class="d-flex align-items-center gap-3">
                                <img src="<?= htmlspecialchars($p['image']) ?>" alt="" class="rounded-3" style="width: 48px; height: 48px; object-fit: cover;">
                                <div>
                                    <div class="fw-bold"><?= htmlspecialchars($p['name']) ?></div>
                                    <small class="text-muted"><?= htmlspecialchars($p['unit']) ?></small>
                                </div>
                            </div>
                        </td>
                        <td><span class="badge bg-light text-dark border"><?= htmlspecialchars($p['category_name'] ?: 'General') ?></span></td>
                        <td class="fw-bold">Rs <?= number_format($p['price']) ?></td>
                        <td>
                            <?php if ($p['discount_price']): ?>
                                <span class="badge bg-danger-subtle text-danger">Rs <?= number_format($p['discount_price']) ?></span>
                            <?php else: ?>
                                <span class="text-muted small">&mdash;</span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if ($p['stock_qty'] <= 5): ?>
                                <span class="badge bg-danger rounded-pill"><?= $p['stock_qty'] ?> low</span>
                            <?php else: ?>
                                <span class="fw-semibold"><?= $p['stock_qty'] ?></span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?= $p['is_available'] ? '<span class="badge bg-success-subtle text-success">Active</span>' : '<span class="badge bg-secondary">Hidden</span>' ?>
                        </td>
                        <td class="text-end pe-4">
                            <button class="btn btn-sm btn-light border rounded-pill px-3 me-1" data-bs-toggle="modal" data-bs-target="#editModal<?= $p['id'] ?>">Edit</button>
                            <form method="POST" class="d-inline" onsubmit="return confirm('Delete this product permanently?');">
                                <input type="hidden" name="action" value="delete_product">
                                <input type="hidden" name="id" value="<?= $p['id'] ?>">
                                <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill px-2"><i class="fa-solid fa-trash"></i></button>
                            </form>
                        </td>
                    </tr>

                    <!-- Edit Modal -->
                    <div class="modal fade" id="editModal<?= $p['id'] ?>" tabindex="-1">
                        <div class="modal-dialog modal-lg">
                            <div class="modal-content rounded-4 border-0">
                                <div class="modal-header border-bottom">
                                    <h6 class="modal-title fw-bold">Edit Product</h6>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <form method="POST" enctype="multipart/form-data">
                                    <div class="modal-body">
                                        <input type="hidden" name="action" value="save_product">
                                        <input type="hidden" name="id" value="<?= $p['id'] ?>">

                                        <div class="row g-3">
                                            <div class="col-md-8">
                                                <label class="form-label small fw-bold">Product Name</label>
                                                <input type="text" name="name" class="form-control" value="<?= htmlspecialchars($p['name']) ?>" required>
                                            </div>
                                            <div class="col-md-4">
                                                <label class="form-label small fw-bold">Category</label>
                                                <select name="category_id" class="form-select">
                                                    <?php foreach ($categories as $cat): ?>
                                                        <option value="<?= $cat['id'] ?>" <?= $p['category_id'] == $cat['id'] ? 'selected' : '' ?>><?= htmlspecialchars($cat['name']) ?></option>
                                                    <?php endforeach; ?>
                                                </select>
                                            </div>
                                            <div class="col-md-4">
                                                <label class="form-label small fw-bold">Regular Price (Rs)</label>
                                                <input type="number" step="0.01" name="price" class="form-control" value="<?= $p['price'] ?>" required>
                                            </div>
                                            <div class="col-md-4">
                                                <label class="form-label small fw-bold">Discount Price (Rs)</label>
                                                <input type="number" step="0.01" name="discount_price" class="form-control" value="<?= $p['discount_price'] ?>">
                                            </div>
                                            <div class="col-md-4">
                                                <label class="form-label small fw-bold">Unit (e.g. 1 kg, 1 dozen)</label>
                                                <input type="text" name="unit" class="form-control" value="<?= htmlspecialchars($p['unit']) ?>">
                                            </div>
                                            <div class="col-md-4">
                                                <label class="form-label small fw-bold">Stock Quantity</label>
                                                <input type="number" name="stock_qty" class="form-control" value="<?= $p['stock_qty'] ?>">
                                            </div>
                                            <div class="col-md-8">
                                                <label class="form-label small fw-bold">Image URL</label>
                                                <input type="text" name="image" class="form-control" value="<?= htmlspecialchars($p['image']) ?>">
                                            </div>
                                            <div class="col-12">
                                                <label class="form-label small fw-bold">Description</label>
                                                <textarea name="description" class="form-control" rows="3"><?= htmlspecialchars($p['description']) ?></textarea>
                                            </div>
                                            <div class="col-md-6">
                                                <div class="form-check form-switch mt-2">
                                                    <input class="form-check-input" type="checkbox" name="is_available" value="1" <?= $p['is_available'] ? 'checked' : '' ?>>
                                                    <label class="form-check-label fw-semibold">Available for Sale</label>
                                                </div>
                                            </div>
                                            <div class="col-md-6">
                                                <div class="form-check form-switch mt-2">
                                                    <input class="form-check-input" type="checkbox" name="is_featured" value="1" <?= $p['is_featured'] ? 'checked' : '' ?>>
                                                    <label class="form-check-label fw-semibold">Featured on Home</label>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="modal-footer border-0">
                                        <button type="button" class="btn btn-light rounded-3" data-bs-dismiss="modal">Cancel</button>
                                        <button type="submit" class="btn btn-primary rounded-3 px-4">Save Changes</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Add Product Modal -->
<div class="modal fade" id="addProductModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content rounded-4 border-0">
            <div class="modal-header border-bottom">
                <h6 class="modal-title fw-bold">Add New Grocery Product</h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" enctype="multipart/form-data">
                <div class="modal-body">
                    <input type="hidden" name="action" value="save_product">
                    <input type="hidden" name="id" value="0">

                    <div class="row g-3">
                        <div class="col-md-8">
                            <label class="form-label small fw-bold">Product Name</label>
                            <input type="text" name="name" class="form-control" placeholder="e.g. Fresh Red Apples" required>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-bold">Category</label>
                            <select name="category_id" class="form-select">
                                <?php foreach ($categories as $cat): ?>
                                    <option value="<?= $cat['id'] ?>"><?= htmlspecialchars($cat['name']) ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-bold">Price (Rs)</label>
                            <input type="number" step="0.01" name="price" class="form-control" placeholder="350" required>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-bold">Discount Price (Rs) (Optional)</label>
                            <input type="number" step="0.01" name="discount_price" class="form-control" placeholder="299">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-bold">Unit</label>
                            <input type="text" name="unit" class="form-control" value="1 kg">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small fw-bold">Stock Quantity</label>
                            <input type="number" name="stock_qty" class="form-control" value="50">
                        </div>
                        <div class="col-md-8">
                            <label class="form-label small fw-bold">Image URL</label>
                            <input type="text" name="image" class="form-control" placeholder="https://images.unsplash.com/...">
                        </div>
                        <div class="col-12">
                            <label class="form-label small fw-bold">Description</label>
                            <textarea name="description" class="form-control" rows="2" placeholder="Describe the item freshness, origin, etc."></textarea>
                        </div>
                        <div class="col-md-6">
                            <div class="form-check form-switch mt-2">
                                <input class="form-check-input" type="checkbox" name="is_available" value="1" checked>
                                <label class="form-check-label fw-semibold">Available for Sale</label>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-check form-switch mt-2">
                                <input class="form-check-input" type="checkbox" name="is_featured" value="1">
                                <label class="form-check-label fw-semibold">Featured on Home</label>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-0">
                    <button type="button" class="btn btn-light rounded-3" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary rounded-3 px-4">Create Product</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
