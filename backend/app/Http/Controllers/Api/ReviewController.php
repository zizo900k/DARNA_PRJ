<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Models\Property;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    /**
     * List reviews for a property.
     */
    public function index($propertyId)
    {
        $property = Property::findOrFail($propertyId);
        return response()->json($property->reviews()->with('user')->get());
    }

    /**
     * Add a review for a property.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'property_id' => 'required|exists:properties,id',
            'rating'      => 'required|integer|min:1|max:5',
            'comment'     => 'nullable|string|max:1000',
        ]);

        // Prevent reviewing own property
        $property = Property::findOrFail($validated['property_id']);
        if ($property->user_id === $request->user()->id) {
            return response()->json(['message' => 'You cannot review your own property.'], 403);
        }

        // Prevent duplicate reviews
        $exists = Review::where('user_id', $request->user()->id)
            ->where('property_id', $validated['property_id'])
            ->exists();

        if ($exists) {
            return response()->json(['message' => 'You have already reviewed this property.'], 409);
        }

        $review = Review::create([
            'user_id'     => $request->user()->id,
            'property_id' => $validated['property_id'],
            'rating'      => $validated['rating'],
            'comment'     => $validated['comment'] ?? null,
        ]);

        // Recalculate average rating
        $avgRating = Review::where('property_id', $property->id)->avg('rating');
        $property->update(['rating' => round($avgRating, 1)]);

        return response()->json([
            'message' => 'Review submitted successfully',
            'review'  => $review->load('user'),
        ], 201);
    }

    /**
     * Update a review.
     */
    public function update(Request $request, Review $review)
    {
        if ($review->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $validated = $request->validate([
            'rating'  => 'sometimes|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $review->update($validated);

        // Recalculate average rating
        $property = $review->property;
        $avgRating = Review::where('property_id', $property->id)->avg('rating');
        $property->update(['rating' => round($avgRating, 1)]);

        return response()->json([
            'message' => 'Review updated successfully',
            'review'  => $review->load('user'),
        ]);
    }

    /**
     * Delete a review.
     */
    public function destroy(Request $request, Review $review)
    {
        if ($review->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $property = $review->property;
        $review->delete();

        // Recalculate average rating
        $avgRating = Review::where('property_id', $property->id)->avg('rating');
        $property->update(['rating' => $avgRating ? round($avgRating, 1) : 0]);

        return response()->json(['message' => 'Review deleted successfully']);
    }
}
