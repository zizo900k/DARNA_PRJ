<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'avatar', 'preferences', 'last_seen_at', 'google_id'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'preferences' => 'array',
            'last_seen_at' => 'datetime',
        ];
    }

    protected $appends = ['full_avatar_url'];

    public function getFullAvatarUrlAttribute(): ?string
    {
        $avatar = $this->attributes['avatar'] ?? null;
        if (!$avatar) {
            return null;
        }

        if (str_starts_with($avatar, 'http://') || str_starts_with($avatar, 'https://')) {
            if (str_contains($avatar, 'localhost') || str_contains($avatar, '127.0.0.1')) {
                // Local full URL -> extract path and use proxy
                $path = parse_url($avatar, PHP_URL_PATH);
                if (str_starts_with($path, '/storage/')) {
                    $path = substr($path, 9);
                }
                return url('/proxy/storage/' . ltrim($path, '/'));
            }
            // External URL (e.g. Google profile picture) -> proxy it to avoid CORS
            return url('/proxy/external?url=' . urlencode($avatar));
        }

        // Relative paths (e.g. avatars/xxx.jpg)
        return url('/proxy/storage/' . ltrim($avatar, '/'));
    }

    public function properties()
    {
        return $this->hasMany(Property::class);
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

    public function rentedProperties()
    {
        return $this->hasMany(Rent::class, 'tenant_id');
    }

    public function ownedRents()
    {
        return $this->hasMany(Rent::class, 'owner_id');
    }

    public function purchases()
    {
        return $this->hasMany(Sale::class, 'buyer_id');
    }

    public function sales()
    {
        return $this->hasMany(Sale::class, 'seller_id');
    }

    public function conversations()
    {
        return Conversation::where('user1_id', $this->id)
            ->orWhere('user2_id', $this->id);
    }
}
