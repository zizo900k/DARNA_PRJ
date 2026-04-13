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

        return response()->json([
            'message' => 'Review updated successfully',
            'review'  => $review,
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

        $review->delete();
        return response()->json(['message' => 'Review deleted successfully']);
    }
}
