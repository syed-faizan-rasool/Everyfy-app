<?php
$pageTitle = 'Categories';
$pageHeading = 'Product Categories';
require_once __DIR__ . '/includes/header.php';

$pdo = Database::getConnection();
$message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $action = $_POST['action'];

    if ($action === 'save_category') {
        $id        = (int)($_POST['id'] ?? 0);
        $name      = trim($_POST['name'] ?? '');
        $image     = trim($_POST['image'] ?? '');
        $sortOrder = (int)($_POST['sort_order'] ?? 0);

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
                    <img src="<?= htmlspecialchars($cat['image']) ?>" alt="" style="width: 100%; height: 100%; object-fit: cover;">
                    <div style="position: absolute; inset: 0; background: linear-gradient(to top, rgba(0,0,0,0.7), transparent);"></div>
                    <div style="position: absolute; bottom: 12px; left: 16px; color: white;">
                        <h5 class="fw-bold mb-0"><?= htmlspecialchars($cat['name']) ?></h5>
                        <small class="text-white-50"><?= $cat['product_count'] ?> products</small>
                    </div>
                </div>
                <div class="card-body p-3 d-flex justify-content-between align-items-center">
                    <span class="small text-muted">Order: #<?= $cat['sort_order'] ?></span>
                    <form method="POST" onsubmit="return confirm('Delete this category? Associated products will be affected.');">
                        <input type="hidden" name="action" value="delete_category">
                        <input type="hidden" name="id" value="<?= $cat['id'] ?>">
                        <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill px-3">Delete</button>
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
            <form method="POST">
                <div class="modal-body">
                    <input type="hidden" name="action" value="save_category">
                    <div class="mb-3">
                        <label class="form-label small fw-bold">Category Name</label>
                        <input type="text" name="name" class="form-control rounded-3" placeholder="e.g. Organic Meat & Seafood" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label small fw-bold">Image URL</label>
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
