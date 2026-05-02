<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    /**
     * Display a listing of categories (public).
     */
    public function index()
    {
        $categories = Category::withCount('properties')->get();
        return response()->json($categories);
    }

    /**
     * Store a newly created category (admin only).
     */
    public function store(Request $request)
    {
        // Admin authorization
        if (!$request->user() || $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized. Admin access required.'], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'nullable|string|max:255|unique:categories,slug',
        ]);

        // Normalize: trim and title-case
        $validated['name'] = ucwords(trim($validated['name']));
        
        $slug = $validated['slug'] ?? \Illuminate\Support\Str::slug(strtolower($validated['name']));
        if (empty($slug)) {
            return response()->json(['message' => 'Could not generate a valid slug. Please provide one.'], 422);
        }
        
        // Ensure uniqueness
        $baseSlug = $slug;
        $counter = 1;
        while (Category::where('slug', $slug)->exists()) {
            $slug = $baseSlug . '-' . $counter;
            $counter++;
        }
        $validated['slug'] = strtolower($slug);

        $category = Category::create($validated);

        return response()->json([
            'message'  => 'Category created successfully',
            'category' => $category->loadCount('properties'),
        ], 201);
    }

    /**
     * Display the specified category.
     */
    public function show(Category $category)
    {
        return response()->json($category->load('properties'));
    }

    /**
     * Update the specified category (admin only).
     */
    public function update(Request $request, Category $category)
    {
        // Admin authorization
        if (!$request->user() || $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized. Admin access required.'], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'nullable|string|max:255|unique:categories,slug,' . $category->id,
        ]);

        // Normalize: trim and title-case
        $validated['name'] = ucwords(trim($validated['name']));
        
        if (isset($validated['slug'])) {
            $validated['slug'] = strtolower(\Illuminate\Support\Str::slug($validated['slug']));
        }

        $category->update($validated);

        return response()->json([
            'message'  => 'Category updated successfully',
            'category' => $category->loadCount('properties'),
        ]);
    }

    /**
     * Remove the specified category (admin only).
     * Prevents deletion if properties are still assigned.
     */
    public function destroy(Request $request, Category $category)
    {
        // Admin authorization
        if (!$request->user() || $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized. Admin access required.'], 403);
        }

        // Safe deletion: prevent if category has properties
        $propertyCount = $category->properties()->count();
        if ($propertyCount > 0) {
            return response()->json([
                'message' => "Cannot delete this category. It is currently used by {$propertyCount} properties. Please reassign them first.",
                'properties_count' => $propertyCount,
            ], 422);
        }

        $category->delete();
        return response()->json(['message' => 'Category deleted successfully']);
    }
}
