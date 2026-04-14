<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Conversation extends Model
{
    protected $fillable = [
        'user1_id',
        'user2_id',
        'property_id',
        'last_message',
        'last_message_at',
    ];

    protected $casts = [
        'last_message_at' => 'datetime',
    ];

    public function user1()
    {
        return $this->belongsTo(User::class, 'user1_id');
    }

    public function user2()
    {
        return $this->belongsTo(User::class, 'user2_id');
    }

    public function property()
    {
        return $this->belongsTo(Property::class);
    }

    public function messages()
    {
        return $this->hasMany(Message::class);
    }

    /**
     * Get the other user in the conversation.
     */
    public function getOtherUser(int $userId): ?User
    {
        return $this->user1_id === $userId ? $this->user2 : $this->user1;
    }

    /**
     * Count unread messages for a specific user.
     */
    public function unreadCountFor(int $userId): int
    {
        return $this->messages()
            ->where('sender_id', '!=', $userId)
            ->where('status', 'sent')
            ->count();
    }
}
