<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    protected $fillable = [
        'conversation_id',
        'sender_id',
        'message',
        'status',
        'delivered_at',
        'read_at',
        'deleted_for_everyone_at',
        'deleted_by_users',
    ];

    protected $casts = [
        'delivered_at'            => 'datetime',
        'read_at'                 => 'datetime',
        'deleted_for_everyone_at' => 'datetime',
        'deleted_by_users'        => 'array',
    ];

    public function conversation()
    {
        return $this->belongsTo(Conversation::class);
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
