<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::match(['GET', 'OPTIONS'], '/proxy/storage/{path}', function ($path) {
    if (request()->isMethod('OPTIONS')) {
        return response('', 204)->withHeaders([
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Access-Control-Allow-Headers' => '*',
        ]);
    }

    // Securely resolve path within public storage to prevent path traversal
    $storagePath = storage_path('app/public/' . $path);
    $realStoragePath = realpath($storagePath);
    $publicPath = realpath(storage_path('app/public'));

    if (!$realStoragePath || strpos($realStoragePath, $publicPath) !== 0 || !file_exists($realStoragePath)) {
        abort(404);
    }

    return response()->file($realStoragePath, [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, OPTIONS',
        'Access-Control-Allow-Headers' => '*',
    ]);
})->where('path', '.*');

// Legacy route for property photos
Route::match(['GET', 'OPTIONS'], '/images/{filename}', function ($filename) {
    if (request()->isMethod('OPTIONS')) {
        return response('', 204)->withHeaders([
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Access-Control-Allow-Headers' => '*',
        ]);
    }

    $path = storage_path('app/public/property_photos/' . $filename);
    if (!file_exists($path)) {
        // Fallback for just in case it's stored directly in public
        $path = storage_path('app/public/' . $filename);
        if(!file_exists($path)) abort(404);
    }
    return response()->file($path, [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, OPTIONS',
        'Access-Control-Allow-Headers' => '*',
    ]);
});
