<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Property;
use App\Models\PropertyPhoto;
use Illuminate\Http\Request;

class PropertyPhotoController extends Controller
{
    /**
     * Add photos to a property (handles real file uploads).
     */
    public function store(Request $request, $propertyId)
    {
        $property = Property::findOrFail($propertyId);

        if ($property->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $request->validate([
            'photos'   => 'required|array',
            'photos.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:5120',
        ]);

        $uploaded = [];
        $order = PropertyPhoto::where('property_id', $property->id)->max('order') ?? 0;

        foreach ($request->file('photos') as $file) {
            $order++;
            $path = $file->store('property_photos', 'public');
            $url = asset('storage/' . $path);

            $photo = PropertyPhoto::create([
                'property_id' => $property->id,
                'url'         => $url,
                'order'       => $order,
            ]);
            $uploaded[] = $photo;
        }

        return response()->json([
            'message' => count($uploaded) . ' photo(s) uploaded successfully',
            'photos'  => $uploaded,
        ], 201);
    }

    /**
     * Delete a photo from a property.
     */
    public function destroy(Request $request, $propertyId, PropertyPhoto $photo)
    {
        $property = Property::findOrFail($propertyId);

        if ($property->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        if ($photo->property_id !== $property->id) {
            return response()->json(['message' => 'Photo does not belong to this property.'], 404);
        }

        $photo->delete();
        return response()->json(['message' => 'Photo deleted successfully']);
    }
}
