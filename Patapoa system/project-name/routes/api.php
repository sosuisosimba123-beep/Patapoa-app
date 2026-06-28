<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\MerchantController;
use App\Http\Controllers\Api\RiderController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\AddressController;
use App\Http\Controllers\Api\WalletController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\UploadController;
use App\Http\Controllers\Api\AdminController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::prefix('v1')->group(function () {
    // Public routes
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/otp/send', [AuthController::class, 'sendOtp']);
    Route::post('/auth/otp/verify', [AuthController::class, 'verifyOtp']);
    Route::post('/auth/refresh', [AuthController::class, 'refresh']);

    // Public browsing (no auth required)
    Route::get('/categories', [CategoryController::class, 'index']);
    Route::get('/categories/{category}', [CategoryController::class, 'show']);
    Route::get('/products', [ProductController::class, 'index']);
    Route::get('/products/{product}', [ProductController::class, 'show']);

    // Protected routes
    Route::middleware('auth:sanctum')->group(function () {
        // Auth
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/auth/me', [AuthController::class, 'me']);

        // User management
        Route::apiResource('/users', UserController::class);
        Route::put('/users/{user}/location', [UserController::class, 'updateLocation']);
        Route::put('/users/{user}/fcm-token', [UserController::class, 'updateFcmToken']);

        // Addresses
        Route::apiResource('/addresses', AddressController::class);
        Route::put('/addresses/{address}/default', [AddressController::class, 'setDefault']);

        // Merchant routes
        Route::middleware('role:merchant')->prefix('merchant')->group(function () {
            Route::apiResource('/products', ProductController::class)->except(['index', 'show']);
            Route::get('/products', [ProductController::class, 'merchantProducts']);
            Route::get('/dashboard', [MerchantController::class, 'dashboard']);
            Route::get('/orders', [MerchantController::class, 'orders']);
            Route::put('/orders/{order}/status', [MerchantController::class, 'updateOrderStatus']);
        });

        // Rider routes
        Route::middleware('role:rider')->prefix('rider')->group(function () {
            Route::get('/orders', [RiderController::class, 'riderOrders']);
            Route::get('/profile', [RiderController::class, 'profile']);
            Route::post('/location', [RiderController::class, 'updateLocation']);
            Route::post('/online', [RiderController::class, 'goOnline']);
            Route::post('/offline', [RiderController::class, 'goOffline']);
            Route::get('/available-orders', [RiderController::class, 'availableOrders']);
            Route::post('/orders/{order}/accept', [RiderController::class, 'acceptOrder']);
            Route::put('/orders/{order}/status', [RiderController::class, 'updateOrderStatus']);
            Route::get('/earnings', [RiderController::class, 'earnings']);
            Route::post('/payout/request', [RiderController::class, 'requestPayout']);
        });

        // Customer routes
        Route::middleware('role:customer')->prefix('customer')->group(function () {
            Route::post('/orders', [OrderController::class, 'store']);
            Route::get('/orders', [OrderController::class, 'customerOrders']);
            Route::get('/orders/{order}', [OrderController::class, 'show']);
        });

        // Orders (general)
        Route::get('/orders/{order}/tracking', [OrderController::class, 'tracking']);
        Route::put('/orders/{order}/cancel', [OrderController::class, 'cancel']);

        // Wallet
        Route::get('/wallet', [WalletController::class, 'show']);
        Route::get('/transactions', [TransactionController::class, 'index']);

        // Payments
        Route::post('/payments/initiate', [TransactionController::class, 'initiatePayment']);
        Route::post('/payments/callback', [TransactionController::class, 'paymentCallback']);

        // Notifications
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::put('/notifications/{notification}/read', [NotificationController::class, 'markAsRead']);
        Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
    });

    // Upload routes (auth required)
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/uploads/image', [UploadController::class, 'uploadImage']);
        Route::post('/uploads/images', [UploadController::class, 'uploadMultipleImages']);
    });
    Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->group(function () {
        Route::get('/dashboard', [AdminController::class, 'dashboard']);
        Route::get('/orders', [AdminController::class, 'orders']);
        Route::get('/merchants', [AdminController::class, 'merchants']);
        Route::get('/riders', [AdminController::class, 'riders']);
        Route::get('/transactions', [AdminController::class, 'transactions']);
        Route::post('/merchants/{merchant}/verify', [AdminController::class, 'verifyMerchant']);
        Route::post('/riders/{rider}/verify', [AdminController::class, 'verifyRider']);
    });
});
