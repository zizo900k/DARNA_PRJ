<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Changing enum columns is only supported in SQLite if we use a raw statement, 
        // or in MySQL with DB::statement. To be safe across DBs, we drop it or use string.
        // It's safer to avoid DB::statement on SQLite constraint changes. Let's make it a string column.
        Schema::table('messages', function (Blueprint $table) {
            $table->string('type')->default('text')->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No safe down
    }
};
