<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->string('type')->after('user_id')->nullable();
            $table->string('title')->after('type')->nullable();
            $table->text('body')->after('title')->nullable();
            $table->json('data')->after('body')->nullable();
            
            // Drop old columns if they exist
            if (Schema::hasColumn('notifications', 'message')) {
                $table->dropColumn('message');
            }
            if (Schema::hasColumn('notifications', 'property_id')) {
                $table->dropForeign(['property_id']);
                $table->dropColumn('property_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropColumn(['type', 'title', 'body', 'data']);
            $table->string('message')->nullable();
            $table->foreignId('property_id')->nullable()->constrained()->onDelete('cascade');
        });
    }
};
