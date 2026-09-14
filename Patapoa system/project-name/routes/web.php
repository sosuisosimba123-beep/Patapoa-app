<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AdminController;

Route::get('/', function () {
    return view('landing');
});

Route::get('/download-apk', function () {
    $path = public_path('downloads/patapoa-debug.apk');
    if (file_exists($path)) {
        return response()->download($path, 'patapoa-debug.apk');
    }
    return response()->json(['message' => 'The Patapoa APK is being prepared for release. Please check back soon!']);
})->name('download.apk');

Route::prefix('admin')->name('admin.')->group(function () {
    // Public login gateway
    Route::get('/login', [AdminController::class, 'showLoginForm'])->name('login');

    // Auth logic
    Route::post('/authenticate', [AdminController::class, 'authenticateViaPocketBase'])->name('authenticate');
    Route::get('/verify', [AdminController::class, 'handlePocketBaseRedirect'])->name('verify');
    Route::post('/logout', [AdminController::class, 'logout'])->name('logout');

    // Protected routes
    Route::middleware(['admin.auth'])->group(function () {
        Route::get('/', [AdminController::class, 'dashboard'])->name('dashboard');
        Route::get('/dashboard', [AdminController::class, 'dashboard']); // Alias

        // Orders
        Route::get('/orders', [AdminController::class, 'orders'])->name('orders');

        // Merchants
        Route::get('/merchants', [AdminController::class, 'merchants'])->name('merchants');
        Route::post('/merchants', [AdminController::class, 'storeMerchant'])->name('merchants.store');
        Route::post('/merchants/{id}/verify', [AdminController::class, 'verifyMerchant'])->name('merchants.verify');

        // Users
        Route::post('/users/{id}/toggle-status', [AdminController::class, 'toggleUserStatus'])->name('users.toggle-status');

        // Deliveries
        Route::get('/deliveries', [AdminController::class, 'deliveries'])->name('deliveries');
        Route::post('/riders', [AdminController::class, 'storeRider'])->name('riders.store');
        Route::post('/riders/{id}/verify', [AdminController::class, 'verifyRider'])->name('riders.verify');

        // Financials
        Route::get('/transactions', [AdminController::class, 'transactions'])->name('transactions');
        Route::post('/orders/{id}/mark-as-paid', [AdminController::class, 'markAsPaid'])->name('orders.mark-paid');

        // Settings
        Route::get('/settings', [AdminController::class, 'settings'])->name('settings');
        Route::post('/settings/pricing', [AdminController::class, 'updatePricing'])->name('settings.pricing');
        Route::post('/settings/platform', [AdminController::class, 'updatePlatformSettings'])->name('settings.platform');

        // Security Hub
        Route::get('/security', [AdminController::class, 'security'])->name('security');
        Route::post('/security/alerts/{id}/resolve', [AdminController::class, 'resolveSecurityAlert'])->name('security.resolve');
    });
});
