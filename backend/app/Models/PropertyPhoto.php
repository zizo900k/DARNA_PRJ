<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PropertyPhoto extends Model
{
    protected $fillable = ['url', 'order', 'property_id'];

    public function property()
    {
        return $this->belongsTo(Property::class);
    }
}
