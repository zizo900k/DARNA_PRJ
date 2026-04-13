<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Property extends Model
{
    protected $fillable = [
        'title', 'description', 'price', 'price_per_month', 'area',
        'location', 'featured', 'facilities', 'type', 'status',
        'phone_number', 'user_id', 'category_id', 'bedrooms', 'bathrooms', 'rating',
        'balcony', 'kitchens', 'toilets', 'living_rooms', 'total_rooms'
    ];

    protected $casts = [
        'facilities' => 'array',
        'featured' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function photos()
    {
        return $this->hasMany(PropertyPhoto::class);
    }

    public function favorites()
    {
        return $this->hasMany(Favorite::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    public function rent()
    {
        return $this->hasOne(Rent::class);
    }

    public function sale()
    {
        return $this->hasOne(Sale::class);
    }
}
