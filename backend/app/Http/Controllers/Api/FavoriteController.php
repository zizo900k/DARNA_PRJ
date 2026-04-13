<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Favorite;
use App\Models\Property;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    /**
     * List the authenticated user's favorites.
     */
    public function index(Request $request)
    {
        $favorites = $request->user()->favorites()->with('property.photos')->get();
        return response()->json($favorites);
    }

    /**
     * Add a property to favorites.
     */
    public function store(Request $request)
    {
        $request->validate([
            'property_id' => 'required|exists:properties,id',
        ]);

        $exists = Favorite::where('user_id', $request->user()->id)
            ->where('property_id', $request->property_id)
            ->exists();

        if ($exists) {
            return response()->json(['message' => 'Property already in favorites.'], 409);
        }

        $favorite = Favorite::create([
            'user_id'     => $request->user()->id,
            'property_id' => $request->property_id,
        ]);

        return response()->json([
            'message'  => 'Property added to favorites',
            'favorite' => $favorite,
        ], 201);
    }

    /**
     * Remove a property from favorites.
     */
    public function destroy(Request $request, $propertyId)
    {
        $deleted = Favorite::where('user_id', $request->user()->id)
            ->where('property_id', $propertyId)
            ->delete();

        if (!$deleted) {
            return response()->json(['message' => 'Favorite not found.'], 404);
        }

        return response()->json(['message' => 'Property removed from favorites']);
    }
    /**
     * Clear all properties from favorites.
     */
    public function clearAll(Request $request)
    {
        Favorite::where('user_id', $request->user()->id)->delete();
        return response()->json(['message' => 'All favorites cleared.']);
    }
}
