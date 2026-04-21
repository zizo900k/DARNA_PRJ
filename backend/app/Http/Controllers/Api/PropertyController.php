<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Property;
use Illuminate\Http\Request;

class PropertyController extends Controller
{
    /**
     * Display a listing of properties with filters.
     */
    public function index(Request $request)
    {
        $query = Property::with(['user', 'category', 'photos']);

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('location')) {
            $query->where('location', 'like', '%' . $request->location . '%');
        }

        if ($request->has('featured')) {
            $query->where('featured', true);
        }

        // Search by title or description or location or owner name
        if ($request->has('search') && !empty($request->search)) {
            $keyword = '%' . $request->search . '%';
            $query->where(function ($q) use ($keyword) {
                $q->where('title', 'like', $keyword)
                  ->orWhere('description', 'like', $keyword)
                  ->orWhere('location', 'like', $keyword)
                  ->orWhereHas('user', function($qUser) use ($keyword) {
                      $qUser->where('name', 'like', $keyword);
                  });
            });
        }

        // Price filter: handle both rent (price_per_month) and sale (price)
        if ($request->has('min_price')) {
            $query->where(function ($q) use ($request) {
                $q->where('price', '>=', $request->min_price)
                  ->orWhere('price_per_month', '>=', $request->min_price);
            });
        }

        if ($request->has('max_price')) {
            $query->where(function ($q) use ($request) {
                $q->where('price', '<=', $request->max_price)
                  ->orWhere('price_per_month', '<=', $request->max_price);
            });
        }

        if ($request->has('cashInHand')) {
            $query->where('price', '<=', $request->cashInHand);
        }

        if ($request->has('monthlyInstallment')) {
            $query->where('price_per_month', '<=', $request->monthlyInstallment);
        }

        if ($request->has('numberOfRooms')) {
            $query->where('bedrooms', '>=', $request->numberOfRooms);
        }

        if ($request->has('propertyStatus') && $request->propertyStatus !== 'all') {
            $query->where('status', $request->propertyStatus);
        }

        // Sort
        if ($request->has('random')) {
            $query->inRandomOrder();
            $limit = $request->input('limit', 15);
            $properties = $query->limit($limit)->get();
            // Return in same format as paginator for frontend compatibility
            return response()->json([
                'data' => $properties,
                'current_page' => 1,
                'last_page' => 1,
                'total' => $properties->count()
            ]);
        }

        $sortBy  = $request->input('sort_by', 'created_at');
        $sortDir = $request->input('sort_dir', 'desc');
        $allowed = ['created_at', 'price', 'price_per_month', 'rating', 'area'];
        if (in_array($sortBy, $allowed)) {
            $query->orderBy($sortBy, $sortDir === 'asc' ? 'asc' : 'desc');
        } else {
            $query->latest();
        }

        $properties = $query->paginate($request->input('limit', 15));

        return response()->json($properties);
    }

    /**
     * Store a newly created property.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title'          => 'required|string|max:255',
            'description'    => 'nullable|string',
            'price'          => 'nullable|numeric|min:0',
            'price_per_month'=> 'nullable|numeric|min:0',
            'area'           => 'nullable|numeric|min:0',
            'location'       => 'nullable|string|max:255',
            'latitude'       => 'nullable|numeric',
            'longitude'      => 'nullable|numeric',
            'featured'       => 'boolean',
            'facilities'     => 'nullable|array',
            'category_id'    => 'required|exists:categories,id',
            'type'           => 'required|in:rent,sale',
            'status'         => 'nullable|string',
            'phone_number'   => 'nullable|string|max:20',
            'bedrooms'       => 'nullable|integer|min:0',
            'bathrooms'      => 'nullable|integer|min:0',
            'balcony'        => 'nullable|integer|min:0',
            'kitchens'       => 'nullable|integer|min:0',
            'toilets'        => 'nullable|integer|min:0',
            'living_rooms'   => 'nullable|integer|min:0',
            'total_rooms'    => 'nullable|integer|min:0',
        ]);

        // Business logic: if type is rent, price_per_month is required
        if ($validated['type'] === 'rent' && empty($validated['price_per_month'])) {
            return response()->json([
                'message' => 'price_per_month is required for rental properties.',
            ], 422);
        }

        // Business logic: if type is sale, price is required
        if ($validated['type'] === 'sale' && empty($validated['price'])) {
            return response()->json([
                'message' => 'price is required for sale properties.',
            ], 422);
        }

        $property = $request->user()->properties()->create($validated);

        return response()->json([
            'message'  => 'Property created successfully',
            'property' => $property->load(['user', 'category', 'photos']),
        ], 201);
    }

    /**
     * Display the specified property.
     */
    public function show(Property $property)
    {
        return response()->json(
            $property->load(['user', 'category', 'photos', 'reviews.user'])
        );
    }

    /**
     * Update the specified property.
     */
    public function update(Request $request, Property $property)
    {
        // Only the owner can update
        if ($property->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized. You do not own this property.'], 403);
        }

        $validated = $request->validate([
            'title'          => 'sometimes|string|max:255',
            'description'    => 'nullable|string',
            'price'          => 'nullable|numeric|min:0',
            'price_per_month'=> 'nullable|numeric|min:0',
            'area'           => 'nullable|numeric|min:0',
            'location'       => 'nullable|string|max:255',
            'latitude'       => 'nullable|numeric',
            'longitude'      => 'nullable|numeric',
            'featured'       => 'boolean',
            'facilities'     => 'nullable|array',
            'category_id'    => 'sometimes|exists:categories,id',
            'type'           => 'sometimes|in:rent,sale',
            'status'         => 'nullable|string',
            'phone_number'   => 'nullable|string|max:20',
            'bedrooms'       => 'nullable|integer|min:0',
            'bathrooms'      => 'nullable|integer|min:0',
            'balcony'        => 'nullable|integer|min:0',
            'kitchens'       => 'nullable|integer|min:0',
            'toilets'        => 'nullable|integer|min:0',
            'living_rooms'   => 'nullable|integer|min:0',
            'total_rooms'    => 'nullable|integer|min:0',
        ]);

        $property->update($validated);

        return response()->json([
            'message'  => 'Property updated successfully',
            'property' => $property->load(['user', 'category', 'photos']),
        ]);
    }

    /**
     * Remove the specified property.
     */
    public function destroy(Request $request, Property $property)
    {
        // Only the owner can delete
        if ($property->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized. You do not own this property.'], 403);
        }

        $property->delete();

        return response()->json(['message' => 'Property deleted successfully']);
    }
    public function nearby(Request $request, $id)
    {
        $property = Property::findOrFail($id);
        $limit = $request->query('limit', 10);

        // If the main property has lat/lng, use geolocation distance
        if ($property->latitude && $property->longitude) {
            $lat = $property->latitude;
            $lng = $property->longitude;
            $radiusKm = $request->query('radius', 50); // default 50km

            $nearby = Property::with(['user', 'category', 'photos'])
                ->where('id', '!=', $id)
                ->whereNotNull('latitude')
                ->whereNotNull('longitude')
                ->selectRaw("*, (6371 * acos(cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude)))) AS distance", [$lat, $lng, $lat])
                ->having('distance', '<', $radiusKm)
                ->orderBy('distance')
                ->limit($limit)
                ->get();
        } else {
            // Fallback: match by location string
            $nearby = Property::with(['user', 'category', 'photos'])
                ->where('id', '!=', $id)
                ->where('location', $property->location)
                ->limit($limit)
                ->get();
        }
            
        return response()->json($nearby);
    }

    public function topLocations()
    {
        $targetCities = ['Laayoune', 'Dakhla', 'Boujdour', 'Smara'];

        // Get counts for these specific cities
        $counts = Property::whereIn('location', $targetCities)
            ->groupBy('location')
            ->selectRaw('location as name, count(*) as count')
            ->get()
            ->keyBy('name');

        // Ensure all 4 cities are returned, even if count is 0
        $result = collect($targetCities)->map(function ($city) use ($counts) {
            return [
                'name' => $city,
                'count' => $counts->has($city) ? $counts[$city]->count : 0
            ];
        });

        return response()->json($result);
    }

    public function locations()
    {
        $locations = Property::select('location')->distinct()->whereNotNull('location')->pluck('location');
        return response()->json($locations);
    }

    public function stats()
    {
        $total = Property::count();
        $rent = Property::where('type', 'rent')->count();
        $sale = Property::where('type', 'sale')->count();
        return response()->json([
            'total' => $total,
            'rent' => $rent,
            'sale' => $sale,
        ]);
    }

    public function types()
    {
        return response()->json(['rent', 'sale']);
    }

    public function statuses()
    {
        return response()->json(['available', 'rented', 'sold']);
    }
}
