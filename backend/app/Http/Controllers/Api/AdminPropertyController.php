<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Property;
use App\Models\Notification;
use Illuminate\Http\Request;

class AdminPropertyController extends Controller
{
    /**
     * Display a listing of properties for admin.
     * Filter by status (pending, published, rejected).
     */
    public function index(Request $request)
    {
        // Must be admin
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $query = Property::with(['user', 'category', 'photos']);

        if ($request->has('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $properties = $query->latest()->paginate($request->input('limit', 20));

        return response()->json($properties);
    }

    /**
     * Display the specified property.
     */
    public function show(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $property = Property::with(['user', 'category', 'photos'])->findOrFail($id);

        return response()->json($property);
    }

    /**
     * Approve a property.
     */
    public function approve(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $property = Property::findOrFail($id);
        $property->status = 'published';
        $property->rejection_reason = null;
        $property->save();

        // Notify user
        Notification::create([
            'user_id' => $property->user_id,
            'type' => 'property_approved',
            'title' => 'Property Approved',
            'body' => "Your property '{$property->title}' has been approved and is now published.",
            'data' => ['property_id' => $property->id],
        ]);

        return response()->json([
            'message' => 'Property approved successfully.',
            'property' => $property
        ]);
    }

    /**
     * Reject a property.
     */
    public function reject(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'rejection_reason' => 'required|string|max:1000'
        ]);

        $property = Property::findOrFail($id);
        $property->status = 'rejected';
        $property->rejection_reason = $request->rejection_reason;
        $property->save();

        // Notify user
        Notification::create([
            'user_id' => $property->user_id,
            'type' => 'property_rejected',
            'title' => 'Property Rejected',
            'body' => "Your property '{$property->title}' has been rejected. Reason: {$request->rejection_reason}",
            'data' => ['property_id' => $property->id, 'reason' => $request->rejection_reason],
        ]);

        return response()->json([
            'message' => 'Property rejected.',
            'property' => $property
        ]);
    }

    /**
     * Admin stats.
     */
    public function stats(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $pending = Property::where('status', 'pending')->count();
        $published = Property::where('status', 'published')->count();
        $rejected = Property::where('status', 'rejected')->count();

        return response()->json([
            'pending' => $pending,
            'published' => $published,
            'rejected' => $rejected,
        ]);
    }
}
