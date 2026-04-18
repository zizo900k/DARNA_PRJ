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
            ->update(['delivered_at' => now()]);

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
}
