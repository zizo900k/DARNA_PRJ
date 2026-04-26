<?php

namespace App\Http\Controllers;

use App\Models\Property;
use App\Models\PropertyRequest;
use Illuminate\Http\Request;

class PropertyRequestController extends Controller
{
    // Create a new request
    public function store(Request $request, $property_id)
    {
        $validated = $request->validate([
            'request_type' => 'required|in:visit,buy_interest,rent_interest',
            'preferred_date' => 'nullable|date',
            'preferred_time' => 'nullable|string',
            'message' => 'nullable|string'
        ]);

        $property = Property::findOrFail($property_id);

        $existingRequest = PropertyRequest::where('property_id', $property->id)
            ->where('sender_id', auth()->id())
            ->whereIn('status', ['pending', 'accepted'])
            ->first();

        if ($existingRequest) {
            return response()->json([
                'message' => 'You already have an active request for this property.'
            ], 422);
        }

        $propRequest = PropertyRequest::create([
            'property_id' => $property->id,
            'sender_id' => auth()->id(),
            'owner_id' => $property->user_id,
            'request_type' => $validated['request_type'],
            'preferred_date' => $validated['preferred_date'] ?? null,
            'preferred_time' => $validated['preferred_time'] ?? null,
            'message' => $validated['message'] ?? null,
            'status' => 'pending'
        ]);

        $notification = \App\Models\Notification::create([
            'user_id' => $property->user_id,
            'type' => 'new_request',
            'title' => 'New Property Request',
            'body' => auth()->user()->name . ' has requested a ' . str_replace('_', ' ', $validated['request_type']) . ' for your property: ' . $property->title,
            'data' => ['request_id' => $propRequest->id, 'property_id' => $property->id],
        ]);
        broadcast(new \App\Events\NotificationCreated($notification));

        return response()->json([
            'message' => 'Request sent successfully',
            'request' => $propRequest
        ], 201);
    }

    // List user's requests (both sent and received)
    public function index()
    {
        $user = auth()->user();

        $sentRequests = PropertyRequest::with(['property.photos', 'owner'])
            ->where('sender_id', $user->id)
            ->get();

        $receivedRequests = PropertyRequest::with(['property.photos', 'sender'])
            ->where('owner_id', $user->id)
            ->get();

        return response()->json([
            'sent' => $sentRequests,
            'received' => $receivedRequests
        ]);
    }

    // Update status (for owner)
    public function updateStatus(Request $request, $id)
    {
        $validated = $request->validate([
            'status' => 'required|in:pending,accepted,rejected,completed'
        ]);

        $propRequest = PropertyRequest::findOrFail($id);

        // Only owner can update the status
        if ($propRequest->owner_id !== auth()->id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $propRequest->update([
            'status' => $validated['status']
        ]);

        if (in_array($validated['status'], ['accepted', 'rejected'])) {
            $propRequest->load('property');
            $notification = \App\Models\Notification::create([
                'user_id' => $propRequest->sender_id,
                'type' => 'request_' . $validated['status'],
                'title' => 'Request ' . ucfirst($validated['status']),
                'body' => 'Your request for ' . ($propRequest->property->title ?? 'a property') . ' has been ' . $validated['status'] . '.',
                'data' => ['request_id' => $propRequest->id, 'property_id' => $propRequest->property_id],
            ]);
            broadcast(new \App\Events\NotificationCreated($notification));
        }

        return response()->json([
            'message' => 'Status updated successfully',
            'request' => $propRequest
        ]);
    }
}
