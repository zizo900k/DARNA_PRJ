<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->string('slug')->nullable()->after('name');
        });

        // Backfill slugs
        $categories = DB::table('categories')->get();
        foreach ($categories as $cat) {
            $nameLower = strtolower(trim($cat->name));
            $slug = Str::slug($nameLower);
            
            // Map common French/English names to standard english slugs
            if (str_contains($nameLower, 'appart') || str_contains($nameLower, 'apart')) {
                $slug = 'apartment';
            } elseif (str_contains($nameLower, 'maison') || str_contains($nameLower, 'house')) {
                $slug = 'house';
            } elseif (str_contains($nameLower, 'commercial') || str_contains($nameLower, 'bureau')) {
                $slug = 'commercial';
            } elseif (str_contains($nameLower, 'terrain') || str_contains($nameLower, 'land')) {
                $slug = 'land';
            } elseif (str_contains($nameLower, 'riad')) {
                $slug = 'riad';
            } elseif (str_contains($nameLower, 'chalet')) {
                $slug = 'chalet';
            } elseif (str_contains($nameLower, 'studio')) {
                $slug = 'studio';
            } elseif (str_contains($nameLower, 'villa')) {
                $slug = 'villa';
            }
            
            // Ensure uniqueness
            $baseSlug = $slug;
            $counter = 1;
            while (DB::table('categories')->where('slug', $slug)->where('id', '!=', $cat->id)->exists()) {
                $slug = $baseSlug . '-' . $counter;
                $counter++;
            }

            DB::table('categories')->where('id', $cat->id)->update(['slug' => $slug]);
        }

        Schema::table('categories', function (Blueprint $table) {
            $table->unique('slug');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropUnique(['slug']);
            $table->dropColumn('slug');
        });
    }
};
