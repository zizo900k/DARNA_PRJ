<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\FavoriteController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PropertyController;
use App\Http\Controllers\Api\PropertyPhotoController;
use App\Http\Controllers\PropertyRequestController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\ChatController;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Broadcast;

Broadcast::routes(['middleware' => ['auth:sanctum']]);

/*
|--------------------------------------------------------------------------
| Public Routes
|--------------------------------------------------------------------------
*/

// Auth (OTP flow)
Route::post('/register/request-code', [AuthController::class, 'requestCode']);
Route::post('/register/verify-code',  [AuthController::class, 'verifyCode']);
Route::post('/register/resend-code',  [AuthController::class, 'resendCode']);

// Legacy Auth
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);
Route::post('/auth/google', [AuthController::class, 'googleAuth']);

// Password Reset
Route::post('/password/forgot', [AuthController::class, 'forgotPassword']);
Route::post('/password/reset', [AuthController::class, 'resetPassword']);

// Public property listing & details
Route::get('/properties',      [PropertyController::class, 'index']);
Route::get('/properties/types', [PropertyController::class, 'types']);
Route::get('/properties/statuses', [PropertyController::class, 'statuses']);
Route::get('/properties/nearby/{id}', [PropertyController::class, 'nearby']);
Route::get('/properties/{property}', [PropertyController::class, 'show']);

Route::get('/locations/top', [PropertyController::class, 'topLocations']);
Route::get('/locations', [PropertyController::class, 'locations']);
Route::get('/stats', [PropertyController::class, 'stats']);
Route::get('/agents', [\App\Http\Controllers\Api\AgentController::class, 'index']);
Route::get('/agents/{id}', [\App\Http\Controllers\Api\AgentController::class, 'show']);

// Categories
Route::get('/categories',          [CategoryController::class, 'index']);
Route::get('/categories/{category}', [CategoryController::class, 'show']);
Route::get('/conversations/{id}/audio-stream/{filename}', [ChatController::class, 'streamAudio']);

/*
|--------------------------------------------------------------------------
| Protected Routes (Require Authentication via Sanctum)
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::get('/profile',    [AuthController::class, 'profile']);
    Route::put('/profile',    [AuthController::class, 'updateProfile']);
    Route::post('/logout',    [AuthController::class, 'logout']);
    Route::get('/profile/listings', [AuthController::class, 'listings']);
    Route::get('/profile/stats',    [AuthController::class, 'stats']);
    Route::post('/users/ping',      [AuthController::class, 'ping']);
    Route::get('/users/{id}/status', [AuthController::class, 'userStatus']);

    // Properties CRUD
    Route::post('/properties',               [PropertyController::class, 'store']);
    Route::put('/properties/{property}',     [PropertyController::class, 'update']);
    Route::delete('/properties/{property}', [PropertyController::class, 'destroy']);

    // Property Photos
    Route::post('/properties/{property}/photos',            [PropertyPhotoController::class, 'store']);
    Route::delete('/properties/{property}/photos/{photo}', [PropertyPhotoController::class, 'destroy']);

    // Favorites
    Route::get('/favorites',          [FavoriteController::class, 'index']);
    Route::post('/favorites',         [FavoriteController::class, 'store']);
    Route::delete('/favorites',       [FavoriteController::class, 'clearAll']);
    Route::delete('/favorites/{propertyId}', [FavoriteController::class, 'destroy']);

    // Reviews
    Route::get('/properties/{propertyId}/reviews', [ReviewController::class, 'index']);
    Route::post('/reviews',               [ReviewController::class, 'store']);
    Route::put('/reviews/{review}',       [ReviewController::class, 'update']);
    Route::delete('/reviews/{review}',    [ReviewController::class, 'destroy']);

    // Notifications
    Route::get('/notifications',                           [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count',              [NotificationController::class, 'unreadCount']);
    Route::put('/notifications/read-all',                  [NotificationController::class, 'markAllAsRead']);
    Route::put('/notifications/{notification}/read',       [NotificationController::class, 'markAsRead']);
    Route::delete('/notifications/{notification}',         [NotificationController::class, 'destroy']);

    // Property Requests (Appointments, Visits, etc.)
    Route::get('/requests',                                 [PropertyRequestController::class, 'index']);
    Route::post('/properties/{id}/requests',                [PropertyRequestController::class, 'store']);
    Route::put('/requests/{id}/status',                     [PropertyRequestController::class, 'updateStatus']);

    // Admin Property Moderation
    Route::get('/admin/properties', [App\Http\Controllers\Api\AdminPropertyController::class, 'index']);
    Route::get('/admin/properties/stats', [App\Http\Controllers\Api\AdminPropertyController::class, 'stats']);
    Route::get('/admin/properties/{id}', [App\Http\Controllers\Api\AdminPropertyController::class, 'show']);
    Route::put('/admin/properties/{id}/approve', [App\Http\Controllers\Api\AdminPropertyController::class, 'approve']);
    Route::put('/admin/properties/{id}/reject', [App\Http\Controllers\Api\AdminPropertyController::class, 'reject']);

    // Admin-only: Category management
    Route::post('/categories',              [CategoryController::class, 'store']);
    Route::put('/categories/{category}',    [CategoryController::class, 'update']);
    Route::delete('/categories/{category}', [CategoryController::class, 'destroy']);

    // Chat / Messaging
    Route::get('/conversations',                    [ChatController::class, 'conversations']);
    Route::post('/conversations',                   [ChatController::class, 'createOrGet']);
    Route::get('/conversations/unread-count',       [ChatController::class, 'unreadCount']);
    Route::get('/conversations/{id}/messages',      [ChatController::class, 'messages']);
    Route::post('/conversations/{id}/messages',     [ChatController::class, 'sendMessage']);
    Route::post('/conversations/{id}/audio',        [ChatController::class, 'sendAudioMessage']);
    Route::post('/conversations/{id}/call/signal',  [ChatController::class, 'sendCallSignal']);
    Route::put('/conversations/{id}/read',          [ChatController::class, 'markAsRead']);
    Route::put('/conversations/{id}/delivered',     [ChatController::class, 'markDelivered']);
    Route::delete('/conversations/{id}/messages/{msgId}/for-me',       [ChatController::class, 'deleteForMe']);
    Route::delete('/conversations/{id}/messages/{msgId}/for-everyone', [ChatController::class, 'deleteForEveryone']);
});
