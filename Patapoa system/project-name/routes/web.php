<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AdminController;

Route::get('/', function () {
    return view('welcome');
});

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/', [AdminController::class, 'dashboard'])->name('dashboard');

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
});

Route::post('/logout', function () {
    auth()->logout();
    return redirect('/');
})->name('auth.logout');
