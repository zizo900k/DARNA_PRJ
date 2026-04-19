<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

class MessageDeleted implements ShouldBroadcastNow
{
    public int $conversationId;
    public int $messageId;
    public bool $deletedForEveryone;

    public function __construct(int $conversationId, int $messageId, bool $deletedForEveryone = true)
    {
        $this->conversationId = $conversationId;
        $this->messageId = $messageId;
        $this->deletedForEveryone = $deletedForEveryone;
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('conversation.' . $this->conversationId),
        ];
    }

    public function broadcastAs(): string
    {
        return 'message.deleted';
    }

    public function broadcastWith(): array
    {
        return [
            'message_id'           => $this->messageId,
            'conversation_id'      => $this->conversationId,
            'deleted_for_everyone' => $this->deletedForEveryone,
        ];
    }
}
