<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Category;
use App\Models\Property;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create Admin user
        User::firstOrCreate(
            ['email' => 'admindarna@gmail.com'],
            [
                'name' => 'DARNA Admin',
                'password' => bcrypt('darna2005'),
                'role' => 'admin'
            ]
        );

        // Find a fallback user, or create one if db is empty
        $user = User::firstOrCreate(
            ['email' => 'admin@darna.com'],
            [
                'name' => 'Test User',
                'password' => bcrypt('password'),
                'role' => 'user'
            ]
        );

        // Create Categories matching frontend PropertiesData
        $catAppartement = Category::firstOrCreate(['id' => 1], ['name' => 'Apartment']);
        $catVilla       = Category::firstOrCreate(['id' => 2], ['name' => 'Villa']);
        $catMaison      = Category::firstOrCreate(['id' => 3], ['name' => 'House']);
        $catStudio      = Category::firstOrCreate(['id' => 4], ['name' => 'Studio']);
        $catCommercial  = Category::firstOrCreate(['id' => 5], ['name' => 'Commercial']);
        $catRiad        = Category::firstOrCreate(['id' => 7], ['name' => 'Riad']);
        $catChalet      = Category::firstOrCreate(['id' => 8], ['name' => 'Chalet']);

        // Create Fake Properties
        Property::create([
            'title' => 'Superbe Appartement à Maarif',
            'description' => 'Un très bel appartement plein sud avec 2 chambres et salon, proche de toutes commodités.',
            'price' => null,
            'price_per_month' => 4500,
            'area' => 85,
            'location' => 'Maarif, Casablanca',
            'featured' => true,
            'facilities' => ['Parking', 'Ascenseur', 'Sécurité 24/7', 'Balcon'],
            'category_id' => $catAppartement->id,
            'user_id' => $user->id,
            'type' => 'rent',
            'status' => 'published',
            'phone_number' => '0624425449',
            'bedrooms' => 2,
            'bathrooms' => 1,
            'rating' => 4.8
        ]);

        Property::create([
            'title' => 'Villa de Luxe vue sur mer',
            'description' => 'Magnifique villa spacieuse avec piscine privée, jardin et une vue imprenable sur la mer.',
            'price' => 3500000,
            'price_per_month' => null,
            'area' => 400,
            'location' => 'Harhoura, Rabat',
            'featured' => true,
            'facilities' => ['Piscine', 'Jardin', 'Garage', 'Cheminée'],
            'category_id' => $catVilla->id,
            'user_id' => $user->id,
            'type' => 'sale',
            'status' => 'published',
            'phone_number' => '0624425449',
            'bedrooms' => 5,
            'bathrooms' => 3,
            'rating' => 5.0
        ]);

        Property::create([
            'title' => 'Studio moderne centre-ville',
            'description' => 'Idéal pour étudiant ou jeune actif, petit studio bien aménagé.',
            'price' => null,
            'price_per_month' => 2000,
            'area' => 35,
            'location' => 'Gueliz, Marrakech',
            'featured' => false,
            'facilities' => ['Meublé', 'Climatisation', 'Wifi inclus'],
            'category_id' => $catStudio->id,
            'user_id' => $user->id,
            'type' => 'rent',
            'status' => 'published',
            'phone_number' => '0624425449',
            'bedrooms' => 1,
            'bathrooms' => 1,
            'rating' => 4.2
        ]);

        Property::create([
            'title' => 'Maison traditionnelle',
            'description' => 'Maison avec belle architecture traditionnelle et cour intérieure.',
            'price' => 1200000,
            'price_per_month' => null,
            'area' => 150,
            'location' => 'Fès',
            'featured' => false,
            'facilities' => ['Terrasse', 'Cour'],
            'category_id' => $catMaison->id,
            'user_id' => $user->id,
            'type' => 'sale',
            'status' => 'published',
            'phone_number' => '0624425449',
            'bedrooms' => 4,
            'bathrooms' => 2,
            'rating' => 4.5
        ]);
        
        $user2 = User::firstOrCreate(
            ['email' => 'owner2@darna.com'],
            ['name' => 'John Seller', 'password' => bcrypt('123456'), 'role' => 'user']
        );

        Property::create([
            'title' => 'Test Maison a vendre',
            'description' => 'Maison a vendre test transaction.',
            'price' => 2000000,
            'price_per_month' => null,
            'area' => 150,
            'location' => 'Agadir',
            'featured' => true,
            'facilities' => ['Terrasse', 'Cour'],
            'category_id' => $catMaison->id,
            'user_id' => $user2->id,
            'type' => 'sale',
            'status' => 'published',
            'phone_number' => '0624425449',
            'bedrooms' => 4,
            'bathrooms' => 2,
            'rating' => 4.5
        ]);

        Property::create([
            'title' => 'Test Studio a louer',
            'description' => 'Studio a louer test transaction.',
            'price' => null,
            'price_per_month' => 3000,
            'area' => 50,
            'location' => 'Tanger',
            'featured' => true,
            'facilities' => ['WIFI', 'Kitchen'],
            'category_id' => $catStudio->id,
            'user_id' => $user2->id,
            'type' => 'rent',
            'status' => 'published',
            'phone_number' => '0624425449',
            'bedrooms' => 1,
            'bathrooms' => 1,
            'rating' => 4.5
        ]);
        
        echo "Fake data seeded properly!\n";
    }
}
