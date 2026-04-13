<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rent;
use App\Models\Property;
use Illuminate\Http\Request;

class RentController extends Controller
{
    /**
     * List rents for the authenticated user (as owner or tenant).
     */
    public function index(Request $request)
    {
        $rents = Rent::with(['property.photos', 'owner', 'tenant'])
            ->where(function ($q) use ($request) {
                $q->where('owner_id', $request->user()->id)
                  ->orWhere('tenant_id', $request->user()->id);
            })->get();

        return response()->json($rents);
    }

    /**
     * Initiate a rent request (by tenant).
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'property_id'    => 'required|exists:properties,id',
            'start_date'     => 'required|date',
            'number_of_months'=> 'required|integer|min:1',
        ]);

        $property = Property::findOrFail($validated['property_id']);

        if ($property->type !== 'rent') {
            return response()->json(['message' => 'This property is not listed for rent.'], 422);
        }

        if ($property->user_id == $request->user()->id) {
            return response()->json(['message' => 'You cannot rent your own property.'], 422);
        }

        if ($property->rent()->whereIn('status', ['pending', 'active'])->exists()) {
            return response()->json(['message' => 'This property already has an active or pending rent request.'], 409);
        }

        $endDate = \Carbon\Carbon::parse($validated['start_date'])->addMonths($validated['number_of_months'])->toDateString();

        $rent = Rent::create([
            'property_id'     => $validated['property_id'],
            'owner_id'        => $property->user_id,
            'tenant_id'       => $request->user()->id,
            'price_per_month' => $property->price_per_month,
            'start_date'      => $validated['start_date'],
            'end_date'        => $endDate,
            'status'          => 'pending',
        ]);

        return response()->json([
            'message' => 'Rent request initiated successfully',
            'rent'    => $rent->load('property', 'owner', 'tenant'),
        ], 201);
    }

    /**
     * Display a specific rent.
     */
    public function show(Request $request, Rent $rent)
    {
        if ($rent->owner_id !== $request->user()->id && $rent->tenant_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        return response()->json($rent->load('property', 'owner', 'tenant'));
    }

    /**
     * Update rent status (Owner confirming, rejecting, or terminating).
     */
    public function update(Request $request, Rent $rent)
    {
        if ($rent->owner_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $validated = $request->validate([
            'status'   => 'required|in:active,terminated,canceled',
            'end_date' => 'nullable|date',
        ]);

        $rent->update($validated);

        if ($validated['status'] === 'active') {
            $rent->property->update(['status' => 'rented']);
        } elseif (in_array($validated['status'], ['terminated', 'canceled'])) {
            $rent->property->update(['status' => 'available']);
        }

        return response()->json([
            'message' => 'Rent updated successfully',
            'rent'    => $rent->load('property', 'owner', 'tenant'),
        ]);
    }
}
