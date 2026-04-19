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

// External URL proxy (for Google profile pictures etc.) to avoid CORS on Flutter Web
Route::match(['GET', 'OPTIONS'], '/proxy/external', function () {
    if (request()->isMethod('OPTIONS')) {
        return response('', 204)->withHeaders([
            'Access-Control-Allow-Origin'  => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Access-Control-Allow-Headers' => '*',
        ]);
    }

    $url = request()->query('url');
    if (!$url) abort(400);

    // Only allow known safe external domains (whitelist)
    $parsed = parse_url($url);
    $allowedHosts = ['lh3.googleusercontent.com', 'lh4.googleusercontent.com', 'lh5.googleusercontent.com', 'lh6.googleusercontent.com', 'googleusercontent.com'];
    if (!isset($parsed['host']) || !in_array($parsed['host'], $allowedHosts)) {
        abort(403, 'External host not allowed');
    }

    try {
        $response = \Illuminate\Support\Facades\Http::timeout(5)->get($url);
        $contentType = $response->header('Content-Type') ?? 'image/jpeg';
        return response($response->body(), 200, [
            'Content-Type'                 => $contentType,
            'Access-Control-Allow-Origin'  => '*',
            'Cache-Control'                => 'public, max-age=86400',
        ]);
    } catch (\Exception $e) {
        abort(502, 'Failed to fetch external image');
    }
});

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
