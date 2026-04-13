<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Sale;
use App\Models\Property;
use Illuminate\Http\Request;

class SaleController extends Controller
{
    /**
     * List sales for the authenticated user (as seller or buyer).
     */
    public function index(Request $request)
    {
        $sales = Sale::with(['property.photos', 'seller', 'buyer'])
            ->where(function ($q) use ($request) {
                $q->where('seller_id', $request->user()->id)
                  ->orWhere('buyer_id', $request->user()->id);
            })->get();

        return response()->json($sales);
    }

    /**
     * Initiate a sale request (by buyer).
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'property_id' => 'required|exists:properties,id',
        ]);

        $property = Property::findOrFail($validated['property_id']);

        if ($property->type !== 'sale') {
            return response()->json(['message' => 'This property is not listed for sale.'], 422);
        }

        if ($property->user_id == $request->user()->id) {
            return response()->json(['message' => 'You cannot buy your own property.'], 422);
        }

        if ($property->sale()->whereIn('status', ['pending', 'completed'])->exists()) {
            return response()->json(['message' => 'This property already has an active or pending transaction.'], 409);
        }

        $sale = Sale::create([
            'property_id' => $validated['property_id'],
            'seller_id'   => $property->user_id,
            'buyer_id'    => $request->user()->id,
            'price'       => $property->price,
            'status'      => 'pending',
        ]);

        return response()->json([
            'message' => 'Sale request initiated successfully',
            'sale'    => $sale->load('property', 'seller', 'buyer'),
        ], 201);
    }

    /**
     * Update sale status (Owner confirming or rejecting).
     */
    public function update(Request $request, Sale $sale)
    {
        if ($sale->seller_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized. Only the owner can update the sale.'], 403);
        }

        $validated = $request->validate([
            'status'   => 'required|in:completed,canceled',
        ]);

        $sale->update(['status' => $validated['status']]);

        if ($validated['status'] === 'completed') {
            $sale->property->update(['status' => 'sold']);
        } elseif ($validated['status'] === 'canceled') {
            $sale->property->update(['status' => 'available']);
        }

        return response()->json([
            'message' => 'Sale status updated',
            'sale'    => $sale->load('property', 'seller', 'buyer'),
        ]);
    }

    /**
     * Display a specific sale.
     */
    public function show(Request $request, Sale $sale)
    {
        if ($sale->seller_id !== $request->user()->id && $sale->buyer_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        return response()->json($sale->load('property', 'seller', 'buyer'));
    }
}
