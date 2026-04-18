<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Cache;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Register a new user.
     */
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'User registered successfully',
            'user'    => $user,
            'token'   => $token,
        ], 201);
    }

    /**
     * Login a user.
     */
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|string|email',
            'password' => 'required|string',
        ]);

        if (!Auth::attempt($request->only('email', 'password'))) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $user  = Auth::user();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'user'    => $user,
            'token'   => $token,
        ]);
    }

    /**
     * Get authenticated user profile.
     */
    public function profile(Request $request)
    {
        return response()->json($request->user());
    }

    /**
     * Update authenticated user profile.
     */
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name'        => 'sometimes|string|max:255',
            'avatar_file' => 'sometimes|image|mimes:jpeg,png,jpg,gif|max:5120',
            'avatar'      => 'sometimes|string|nullable',
            'preferences' => 'sometimes|array|nullable',
        ]);

        if ($request->hasFile('avatar_file')) {
            $path = $request->file('avatar_file')->store('avatars', 'public');
            $user->avatar = url('storage/' . $path);
        } elseif (isset($validated['avatar'])) {
            $user->avatar = $validated['avatar'];
        }

        if (isset($validated['name'])) {
            $user->name = $validated['name'];
        }
        if (isset($validated['preferences'])) {
            $user->preferences = $validated['preferences'];
        }

        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully',
            'user'    => $user,
        ]);
    }

    /**
     * Logout the user.
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out successfully']);
    }

    /**
     * Get authenticated user's property listings.
     */
    public function listings(Request $request)
    {
        $listings = $request->user()->properties()->with(['category', 'photos'])->latest()->get();
        return response()->json($listings);
    }

    /**
     * Get authenticated user's profile stats.
     */
    public function stats(Request $request)
    {
        $user = $request->user();
        return response()->json([
            'listings' => $user->properties()->count(),
            'reviews'  => \App\Models\Review::where('user_id', $user->id)->count(),
        ]);
    }

    /**
     * Ping online presence.
     */
    public function ping(Request $request)
    {
        $user = $request->user();
        
        // Throttling database updates to once a minute per user to save performance
        $cacheKey = 'user-ping-' . $user->id;
        if (!Cache::has($cacheKey)) {
            $user->update(['last_seen_at' => now()]);
            Cache::put($cacheKey, true, 60); // lock for 60 seconds
        }

        return response()->json(['status' => 'ok']);
    }

    /**
     * Get a user's online status.
     */
    public function userStatus(int $id)
    {
        $user = User::findOrFail($id);
        $lastSeen = $user->last_seen_at;

        $isOnline = $lastSeen && $lastSeen->diffInSeconds(now()) < 60;

        return response()->json([
            'is_online'    => $isOnline,
            'last_seen_at' => $lastSeen?->toIso8601String(),
        ]);
    }
}
