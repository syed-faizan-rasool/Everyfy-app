<?php
$pageTitle = 'Categories';
$pageHeading = 'Product Categories';
require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/../helpers/upload.php';

$pdo = Database::getConnection();
$message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $action = $_POST['action'];

    if ($action === 'save_category') {
        $id        = (int)($_POST['id'] ?? 0);
        $name      = trim($_POST['name'] ?? '');
        $image     = trim($_POST['image'] ?? '');
        $sortOrder = (int)($_POST['sort_order'] ?? 0);

        // Handle uploaded image file
        if (isset($_FILES['image_file']) && $_FILES['image_file']['error'] === UPLOAD_ERR_OK) {
            $up = UploadHelper::uploadImage('image_file', 'categories');
            if ($up['success']) {
                $image = $up['url'];
            }
        }

        // On edit: if no file uploaded and image field is empty, retain existing image
        if ($id > 0 && empty($image)) {
            $existing = $pdo->prepare("SELECT image FROM categories WHERE id = ?");
            $existing->execute([$id]);
            $image = $existing->fetchColumn() ?: '';
        }

        if (empty($image)) {
            $image = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500';
        }

        try {
            if ($id > 0) {
                $pdo->prepare("UPDATE categories SET name = ?, image = ?, sort_order = ? WHERE id = ?")
                    ->execute([$name, $image, $sortOrder, $id]);
                $message = "Category updated successfully!";
            } else {
                $pdo->prepare("INSERT INTO categories (name, image, sort_order) VALUES (?, ?, ?)")
                    ->execute([$name, $image, $sortOrder]);
                $message = "New category added!";
            }
        } catch (PDOException $e) {
            $message = "Error: " . $e->getMessage();
        }
    } elseif ($action === 'delete_category') {
        $id = (int)($_POST['id'] ?? 0);
        try {
            $pdo->prepare("DELETE FROM categories WHERE id = ?")->execute([$id]);
            $message = "Category deleted!";
        } catch (PDOException $e) {
            $message = "Error: " . $e->getMessage();
        }
    }
}

$categories = [];
if ($pdo) {
    try {
        $categories = $pdo->query("SELECT c.*, COUNT(p.id) as product_count FROM categories c LEFT JOIN products p ON p.category_id = c.id GROUP BY c.id ORDER BY c.sort_order ASC, c.id ASC")->fetchAll();
    } catch (Exception $e) {}
}
?>

<?php if (!empty($message)): ?>
    <div class="alert alert-success alert-dismissible fade show rounded-3 mb-4">
        <?= htmlspecialchars($message) ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
<?php endif; ?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h5 class="fw-bold mb-0">Product Categories (<?= count($categories) ?>)</h5>
        <small class="text-muted">Organize grocery items into store departments</small>
    </div>
    <button class="btn btn-primary rounded-pill px-4" data-bs-toggle="modal" data-bs-target="#addCategoryModal">
        <i class="fa-solid fa-plus me-2"></i> Add Category
    </button>
</div>

<div class="row g-4">
    <?php foreach ($categories as $cat): ?>
        <div class="col-md-4 col-sm-6">
            <div class="card border-0 shadow-sm rounded-4 overflow-hidden h-100">
                <div style="height: 140px; overflow: hidden; position: relative;">
                    <img src="<?= htmlspecialchars(getAdminImageUrl($cat['image'])) ?>" alt="" style="width: 100%; height: 100%; object-fit: cover;" onerror="this.onerror=null;this.src='https://placehold.co/200x150?text=Category';">
                    <div style="position: absolute; inset: 0; background: linear-gradient(to top, rgba(0,0,0,0.7), transparent);"></div>
                    <div style="position: absolute; bottom: 12px; left: 16px; color: white;">
                        <h5 class="fw-bold mb-0"><?= htmlspecialchars($cat['name']) ?></h5>
                        <small class="text-white-50"><?= $cat['product_count'] ?> products</small>
                    </div>
                </div>
                <div class="card-body p-3 d-flex justify-content-between align-items-center">
                    <span class="small text-muted">Order: #<?= $cat['sort_order'] ?></span>
                    <div class="d-flex gap-1">
                        <button class="btn btn-sm btn-light border rounded-pill px-3" data-bs-toggle="modal" data-bs-target="#editCatModal<?= $cat['id'] ?>">Edit</button>
                        <form method="POST" onsubmit="return confirm('Delete this category? Associated products will be affected.');" class="d-inline">
                            <input type="hidden" name="action" value="delete_category">
                            <input type="hidden" name="id" value="<?= $cat['id'] ?>">
                            <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill px-2"><i class="fa-solid fa-trash"></i></button>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <!-- Edit Category Modal -->
        <div class="modal fade" id="editCatModal<?= $cat['id'] ?>" tabindex="-1">
            <div class="modal-dialog">
                <div class="modal-content rounded-4 border-0">
                    <div class="modal-header border-bottom">
                        <h6 class="modal-title fw-bold">Edit Category</h6>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <form method="POST" enctype="multipart/form-data">
                        <div class="modal-body">
                            <input type="hidden" name="action" value="save_category">
                            <input type="hidden" name="id" value="<?= $cat['id'] ?>">

                            <div class="mb-3">
                                <label class="form-label small fw-bold">Category Name</label>
                                <input type="text" name="name" class="form-control rounded-3" value="<?= htmlspecialchars($cat['name']) ?>" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label small fw-bold"><i class="fa-solid fa-cloud-arrow-up me-1 text-primary"></i> Upload New Image File</label>
                                <input type="file" name="image_file" class="form-control rounded-3" accept="image/*">
                                <small class="text-muted">PNG, JPG, WEBP up to 5MB</small>
                            </div>
                            <div class="mb-3">
                                <label class="form-label small fw-bold">Or Direct Image URL</label>
                                <input type="text" name="image" class="form-control rounded-3" value="<?= htmlspecialchars($cat['image']) ?>" placeholder="https://... or uploads/...">
                            </div>
                            <div class="mb-3 p-2 border rounded-3 bg-light d-flex align-items-center gap-3">
                                <img src="<?= htmlspecialchars(getAdminImageUrl($cat['image'])) ?>" class="rounded-2" style="width: 48px; height: 48px; object-fit: cover;" onerror="this.onerror=null;this.src='https://placehold.co/100x100?text=No+Image';">
                                <small class="text-muted">Leave file and URL blank if keeping current image.</small>
                            </div>
                            <div class="mb-3">
                                <label class="form-label small fw-bold">Display Sort Order</label>
                                <input type="number" name="sort_order" class="form-control rounded-3" value="<?= $cat['sort_order'] ?>">
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
</div>

<!-- Add Category Modal -->
<div class="modal fade" id="addCategoryModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content rounded-4 border-0">
            <div class="modal-header border-bottom">
                <h6 class="modal-title fw-bold">Add Category</h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" enctype="multipart/form-data">
                <div class="modal-body">
                    <input type="hidden" name="action" value="save_category">
                    <input type="hidden" name="id" value="0">
                    <div class="mb-3">
                        <label class="form-label small fw-bold">Category Name</label>
                        <input type="text" name="name" class="form-control rounded-3" placeholder="e.g. Organic Meat & Seafood" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-bold"><i class="fa-solid fa-cloud-arrow-up me-1 text-primary"></i> Upload Category Image File</label>
                        <input type="file" name="image_file" class="form-control rounded-3" accept="image/*">
                        <small class="text-muted">Select image file from your device</small>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-bold">Or Direct Image URL</label>
                        <input type="text" name="image" class="form-control rounded-3" placeholder="https://images.unsplash.com/...">
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-bold">Display Sort Order</label>
                        <input type="number" name="sort_order" class="form-control rounded-3" value="10">
                    </div>
                </div>
                <div class="modal-footer border-0">
                    <button type="button" class="btn btn-light rounded-3" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary rounded-3 px-4">Save Category</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
