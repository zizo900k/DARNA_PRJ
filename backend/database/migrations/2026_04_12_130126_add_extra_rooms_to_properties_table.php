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
        Schema::table('properties', function (Blueprint $table) {
            $table->integer('balcony')->default(0);
            $table->integer('kitchens')->default(0);
            $table->integer('toilets')->default(0);
            $table->integer('living_rooms')->default(0);
            $table->integer('total_rooms')->default(0);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('properties', function (Blueprint $table) {
            $table->dropColumn(['balcony', 'kitchens', 'toilets', 'living_rooms', 'total_rooms']);
        });
    }
};
