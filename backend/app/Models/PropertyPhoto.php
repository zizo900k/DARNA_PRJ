<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PropertyPhoto extends Model
{
    protected $fillable = ['url', 'order', 'property_id'];

    protected $appends = ['full_url'];

    /**
     * Get the full URL for the photo.
     * Rewrites localhost/storage URLs to use the proxy route for CORS.
     */
    public function getFullUrlAttribute(): string
    {
        $url = $this->attributes['url'] ?? '';

        // If it's an absolute URL from another domain (like unsplash), return as-is
        if ((str_starts_with($url, 'http://') || str_starts_with($url, 'https://')) && !str_contains($url, 'localhost') && !str_contains($url, '127.0.0.1')) {
            return $url;
        }

        // Build the URL using the proxy route to ensure CORS headers
        return url('/images/' . basename($url));
    }

    public function property()
    {
        return $this->belongsTo(Property::class);
    }
}
