<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class AgentController extends Controller
{
    public function index(Request $request)
    {
        $query = User::withCount('properties');

        if ($request->has('search') && !empty($request->search)) {
            $keyword = '%' . $request->search . '%';
            $query->where(function ($q) use ($keyword) {
                $q->where('name', 'like', $keyword)
                  ->orWhere('email', 'like', $keyword);
            });
        }

        // Only show users who actually have properties (they are agents)
        $query->having('properties_count', '>', 0);

        return response()->json($query->paginate(15));
    }

    public function show($id)
    {
        $user = User::with(['properties.photos'])->withCount('properties')->findOrFail($id);
        return response()->json([
            'agent' => $user,
            'properties' => $user->properties,
        ]);
    }
}
