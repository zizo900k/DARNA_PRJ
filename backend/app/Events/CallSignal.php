<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CallSignal implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $senderId;
    public $recipientId;
    public $conversationId;
    public $signalData;

    /**
     * Create a new event instance.
     */
    public function __construct(int $senderId, int $recipientId, int $conversationId, array $signalData)
    {
        $this->senderId = $senderId;
        $this->recipientId = $recipientId;
        $this->conversationId = $conversationId;
        $this->signalData = $signalData;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('user.' . $this->recipientId),
        ];
    }
    
    public function broadcastAs()
    {
        return 'call.signal';
    }
}
