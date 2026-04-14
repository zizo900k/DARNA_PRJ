<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
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
                        'id'     => $other->id,
                        'name'   => $other->name,
                        'avatar' => $other->avatar,
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
                'id'     => $other->id,
                'name'   => $other->name,
                'avatar' => $other->avatar,
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
            ->where('status', 'sent')
            ->update(['status' => 'read']);

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
}
