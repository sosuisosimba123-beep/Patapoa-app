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
        $isSqlite = DB::getDriverName() === 'sqlite';

        // 1. Add the spatial point column as nullable first
        Schema::table('merchants', function (Blueprint $table) use ($isSqlite) {
            if ($isSqlite) {
                $table->text('location')->nullable()->after('longitude');
            } else {
                $table->point('location')->nullable()->after('longitude');
            }
        });

        if (!$isSqlite) {
            // 2. Populate the 'location' column from existing 'latitude' and 'longitude'
            DB::statement("UPDATE merchants SET location = ST_PointFromText(CONCAT('POINT(', longitude, ' ', latitude, ')')) WHERE latitude IS NOT NULL AND longitude IS NOT NULL");

            // 3. Set a fallback point for any remaining NULLs
            DB::statement("UPDATE merchants SET location = ST_PointFromText('POINT(39.2083 -6.7924)') WHERE location IS NULL");

            // 4. Change column to NOT NULL and add spatial index
            DB::statement("ALTER TABLE merchants MODIFY location POINT NOT NULL");

            Schema::table('merchants', function (Blueprint $table) {
                $table->spatialIndex('location');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('merchants', function (Blueprint $table) {
            $table->dropSpatialIndex(['location']);
            $table->dropColumn('location');
        });
    }
};
