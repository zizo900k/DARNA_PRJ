<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$request = Illuminate\Http\Request::create('/api/register', 'POST');
$request->merge([
    'name' => 'API Test User',
    'email' => 'api_test_'.time().'@gmail.com',
    'password' => 'password',
    'password_confirmation' => 'password',
]);
$request->headers->set('Accept', 'application/json');

$response = \Illuminate\Support\Facades\Route::dispatch($request);
echo "Response status: " . $response->getStatusCode() . "\n";
echo "Response body: " . $response->getContent() . "\n";
