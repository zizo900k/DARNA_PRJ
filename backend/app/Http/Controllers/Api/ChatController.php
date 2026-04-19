<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Events\ConversationUpdated;
use App\Events\MessageSent;
use App\Events\MessageStatusUpdated;
use App\Events\MessageDeleted;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ChatController extends Controller
{
    /**
     * List all conversations for the authenticated user.
     */
    public function conversations(Request $request)
    {
        $userId = $request->user()->id;

        $conversations = Conversation::where('user1_id', $userId)
            ->orWhere('user2_id', $userId)
            ->with(['user1:id,name,avatar', 'user2:id,name,avatar', 'property:id,title'])
            ->orderByDesc('last_message_at')
            ->get()
            ->map(function ($conv) use ($userId) {
                $other = $conv->getOtherUser($userId);
                return [
                    'id'             => $conv->id,
                    'other_user'     => $other ? [
                        'id'              => $other->id,
                        'name'            => $other->name,
                        'avatar'          => $other->avatar,
                        'full_avatar_url' => $other->full_avatar_url,
                    ] : null,
                    'property'       => $conv->property ? [
                        'id'    => $conv->property->id,
                        'title' => $conv->property->title,
                    ] : null,
                    'last_message'    => $conv->last_message,
                    'last_message_at' => $conv->last_message_at,
                    'unread_count'    => $conv->unreadCountFor($userId),
                    'created_at'      => $conv->created_at,
                ];
            });

        return response()->json($conversations);
    }

    /**
     * Create a new conversation or return existing one.
     */
    public function createOrGet(Request $request)
    {
        $request->validate([
            'user2_id'    => 'required|integer|exists:users,id',
            'property_id' => 'nullable|integer|exists:properties,id',
        ]);

        $userId  = $request->user()->id;
        $user2Id = $request->user2_id;

        if ($userId === $user2Id) {
            return response()->json(['message' => 'Cannot chat with yourself.'], 422);
        }

        // Check if conversation already exists between these two users for this property
        $conversation = Conversation::where(function ($q) use ($userId, $user2Id) {
                $q->where('user1_id', $userId)->where('user2_id', $user2Id);
            })
            ->orWhere(function ($q) use ($userId, $user2Id) {
                $q->where('user1_id', $user2Id)->where('user2_id', $userId);
            })
            ->when($request->property_id, function ($q) use ($request) {
                $q->where('property_id', $request->property_id);
            })
            ->first();

        $isNew = false;

        if (!$conversation) {
            $conversation = Conversation::create([
                'user1_id'    => $userId,
                'user2_id'    => $user2Id,
                'property_id' => $request->property_id,
            ]);
            $isNew = true;
        }

        $conversation->load(['user1:id,name,avatar', 'user2:id,name,avatar', 'property:id,title']);

        $other = $conversation->getOtherUser($userId);

        return response()->json([
            'id'         => $conversation->id,
            'is_new'     => $isNew,
            'other_user' => $other ? [
                'id'              => $other->id,
                'name'            => $other->name,
                'avatar'          => $other->avatar,
                'full_avatar_url' => $other->full_avatar_url,
            ] : null,
            'property'   => $conversation->property ? [
                'id'    => $conversation->property->id,
                'title' => $conversation->property->title,
            ] : null,
        ], $isNew ? 201 : 200);
    }

    /**
     * Get messages for a conversation.
     */
    public function messages(Request $request, int $conversationId)
    {
        $userId = $request->user()->id;

        $conversation = Conversation::where('id', $conversationId)
            ->where(function ($q) use ($userId) {
                $q->where('user1_id', $userId)->orWhere('user2_id', $userId);
            })
            ->firstOrFail();

        $messages = $conversation->messages()
            ->with('sender:id,name,avatar')
            ->where(function ($q) use ($userId) {
                $q->whereNull('deleted_by_users')
                  ->orWhereRaw('NOT JSON_CONTAINS(deleted_by_users, ?)', [json_encode($userId)]);
            })
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json($messages);
    }

    /**
     * Send a message.
     */
    public function sendMessage(Request $request, int $conversationId)
    {
        $request->validate([
            'message' => 'required|string|max:2000',
        ]);

        $userId = $request->user()->id;

        $conversation = Conversation::where('id', $conversationId)
            ->where(function ($q) use ($userId) {
                $q->where('user1_id', $userId)->orWhere('user2_id', $userId);
            })
            ->firstOrFail();

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id'       => $userId,
            'message'         => $request->message,
            'status'          => 'sent',
        ]);

        // Update conversation's last message
        $conversation->update([
            'last_message'    => $request->message,
            'last_message_at' => now(),
        ]);

        $message->load('sender:id,name,avatar');

        // Dispatch broadcasting events
        broadcast(new MessageSent($message));

        $receiverId = $conversation->user1_id === $userId ? $conversation->user2_id : $conversation->user1_id;
        broadcast(new ConversationUpdated($receiverId, $conversation->id));

        return response()->json($message, 201);
    }

    /**
     * Stream audio file with CORS support and security checks.
     */
    public function streamAudio(Request $request, int $conversationId, string $filename)
    {
        // For Web compatibility (headers not supported in audio tag), we check token in query if needed
        $token = $request->query('token');
        $user = null;

        if ($token) {
            // Support both full token (1|abc) and just the plain part
            if (str_contains($token, '|')) {
                $token = explode('|', $token)[1];
            }
            
            $accessToken = \Laravel\Sanctum\PersonalAccessToken::findToken($token);
            if ($accessToken) {
                $user = $accessToken->tokenable;
            }
        } else {
            $user = $request->user();
        }

        if (!$user) {
            $reason = $token ? "Invalid token provided" : "No token provided";
            \Illuminate\Support\Facades\Log::warning("Audio streaming failed: Unauthorized - $reason");
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        $userId = $user->id;

        // Check if user is part of the conversation
        $exists = \App\Models\Conversation::where('id', $conversationId)
            ->where(function ($q) use ($userId) {
                $q->where('user1_id', $userId)->orWhere('user2_id', $userId);
            })
            ->exists();

        if (!$exists) {
            \Illuminate\Support\Facades\Log::warning("Audio streaming failed: Forbidden - User $userId not in conversation $conversationId");
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $path = storage_path("app/public/audio/$filename");
        if (!file_exists($path)) {
            \Illuminate\Support\Facades\Log::warning("Audio streaming failed: File not found at $path");
            return response()->json(['error' => 'File not found'], 404);
        }

        return response()->file($path, [
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Access-Control-Allow-Headers' => 'Content-Type, Authorization',
        ]);
    }


    /**
     * Send an audio message.
     */
    public function sendAudioMessage(Request $request, int $conversationId)
    {
        $request->validate([
            'audio'    => 'required|file|max:10240', // Relaxed validation to support all browser formats
            'duration' => 'nullable|integer',
        ]);

        $userId = $request->user()->id;

        $conversation = Conversation::where('id', $conversationId)
            ->where(function ($q) use ($userId) {
                $q->where('user1_id', $userId)->orWhere('user2_id', $userId);
            })
            ->firstOrFail();

        if ($request->hasFile('audio')) {
            $file = $request->file('audio');
            $filename = Str::random(40) . '.' . $file->getClientOriginalExtension();
            $path = $file->storeAs('audio', $filename, 'public');
            $url = Storage::url($path);

            $message = Message::create([
                'conversation_id' => $conversation->id,
                'sender_id'       => $userId,
                'message'         => 'Voice message 🎤',
                'type'            => 'audio',
                'audio_url'       => $url,
                'audio_duration'  => $request->duration,
                'status'          => 'sent',
            ]);

            // Update conversation's last message
            $conversation->update([
                'last_message'    => 'Voice message 🎤',
                'last_message_at' => now(),
            ]);

            $message->load('sender:id,name,avatar');

            // Dispatch broadcasting events
            broadcast(new MessageSent($message));

            $receiverId = $conversation->user1_id === $userId ? $conversation->user2_id : $conversation->user1_id;
            broadcast(new ConversationUpdated($receiverId, $conversation->id));

            return response()->json($message, 201);
        }

        return response()->json(['message' => 'Audio file is required.'], 422);
    }

    /**
     * Mark all messages in a conversation as read (messages NOT sent by current user).
     */
    public function markAsRead(Request $request, int $conversationId)
    {
        $userId = $request->user()->id;

        $conversation = Conversation::where('id', $conversationId)
            ->where(function ($q) use ($userId) {
                $q->where('user1_id', $userId)->orWhere('user2_id', $userId);
            })
            ->firstOrFail();

        $updated = $conversation->messages()
            ->where('sender_id', '!=', $userId)
            ->whereNull('read_at')
            ->update([
                'status' => 'read',
                'read_at' => now(),
                // If it wasn't marked delivered yet, mark it delivered too
                'delivered_at' => \DB::raw('COALESCE(delivered_at, NOW())')
            ]);

        if ($updated > 0) {
            broadcast(new MessageStatusUpdated($conversationId));
            
            // Note: the original unread count also decreased, we could update global count
            // but the front-end will just fetchUnreadCount on receiving status event.
        }

        return response()->json(['updated' => $updated]);
    }

    /**
     * Mark specific messages as delivered.
     */
    public function markDelivered(Request $request, int $conversationId)
    {
        $userId = $request->user()->id;

        $conversation = Conversation::where('id', $conversationId)
            ->where(function ($q) use ($userId) {
                $q->where('user1_id', $userId)->orWhere('user2_id', $userId);
            })
            ->firstOrFail();

        $updated = $conversation->messages()
            ->where('sender_id', '!=', $userId)
            ->whereNull('delivered_at')
            ->update(['status' => 'delivered', 'delivered_at' => now()]);

        if ($updated > 0) {
            broadcast(new MessageStatusUpdated($conversationId));
        }

        return response()->json(['updated' => $updated]);
    }

    /**
     * Get total unread count for the authenticated user.
     */
    public function unreadCount(Request $request)
    {
        $userId = $request->user()->id;

        $count = Message::whereHas('conversation', function ($q) use ($userId) {
                $q->where('user1_id', $userId)->orWhere('user2_id', $userId);
            })
            ->where('sender_id', '!=', $userId)
            ->where('status', 'sent')
            ->count();

        return response()->json(['unread_count' => $count]);
    }

    /**
     * Delete a message for the current user only.
     */
    public function deleteForMe(Request $request, int $conversationId, int $messageId)
    {
        $userId = $request->user()->id;

        $conversation = Conversation::where('id', $conversationId)
            ->where(function ($q) use ($userId) {
                $q->where('user1_id', $userId)->orWhere('user2_id', $userId);
            })
            ->firstOrFail();

        $message = $conversation->messages()->findOrFail($messageId);

        $deletedBy = $message->deleted_by_users ?? [];
        if (!in_array($userId, $deletedBy)) {
            $deletedBy[] = $userId;
        }
        $message->update(['deleted_by_users' => $deletedBy]);

        return response()->json(['status' => 'deleted_for_me']);
    }

    /**
     * Delete a message for everyone (sender only).
     */
    public function deleteForEveryone(Request $request, int $conversationId, int $messageId)
    {
        $userId = $request->user()->id;

        $conversation = Conversation::where('id', $conversationId)
            ->where(function ($q) use ($userId) {
                $q->where('user1_id', $userId)->orWhere('user2_id', $userId);
            })
            ->firstOrFail();

        $message = $conversation->messages()
            ->where('sender_id', $userId)  // Only the sender can delete for everyone
            ->findOrFail($messageId);

        $message->update([
            'deleted_for_everyone_at' => now(),
        ]);

        broadcast(new MessageDeleted($conversationId, $messageId, true));

        return response()->json(['status' => 'deleted_for_everyone']);
    }

    /**
     * Handle WebRTC call signaling
     */
    public function sendCallSignal(Request $request, int $conversationId)
    {
        $userId = $request->user()->id;

        $conversation = Conversation::where('id', $conversationId)
            ->where(function ($q) use ($userId) {
                $q->where('user1_id', $userId)->orWhere('user2_id', $userId);
            })
            ->firstOrFail();

        $recipientId = ($conversation->user1_id == $userId) ? $conversation->user2_id : $conversation->user1_id;

        $data = $request->validate([
            'type' => 'required|string',
            'sdp' => 'nullable|string',
            'candidate' => 'nullable|array',
            'status' => 'nullable|string', // missed, declined, canceled, ended
        ]);

        $user = $request->user();
        $data['sender'] = [
            'id' => $user->id,
            'name' => $user->name,
            'avatar' => $user->full_avatar_url ?? $user->avatar
        ];

        // Insert a system message if this is a terminal event
        if ($data['type'] === 'end_call' && !empty($data['status']) && in_array($data['status'], ['missed', 'declined', 'canceled'])) {
            $msgText = 'Call ended';
            if ($data['status'] === 'missed') $msgText = 'Missed voice call';
            if ($data['status'] === 'declined') $msgText = 'Call declined';
            if ($data['status'] === 'canceled') $msgText = 'Canceled call';

            $systemMessage = $conversation->messages()->create([
                'sender_id' => $userId,
                'type' => 'system',
                'message' => $msgText,
                'status' => 'sent',
            ]);

            // Broadcast the system message so it appears immediately in the chat
            broadcast(new \App\Events\MessageSent($systemMessage))->toOthers();
        }

        // Broadcast to the user's private channel
        broadcast(new \App\Events\CallSignal($userId, $recipientId, $conversation->id, $data));

        return response()->json(['status' => 'signal_sent']);
    }
}
