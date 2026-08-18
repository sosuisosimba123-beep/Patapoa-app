<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $isSqlite = DB::getDriverName() === 'sqlite';

        Schema::table('delivery_partners', function (Blueprint $table) use ($isSqlite) {
            if ($isSqlite) {
                $table->text('location')->nullable()->after('current_longitude');
            } else {
                $table->point('location')->nullable()->after('current_longitude');
            }
        });

        if (!$isSqlite) {
            DB::statement("UPDATE delivery_partners SET location = ST_PointFromText(CONCAT('POINT(', current_longitude, ' ', current_latitude, ')')) WHERE current_latitude IS NOT NULL AND current_longitude IS NOT NULL");
            DB::statement("UPDATE delivery_partners SET location = ST_PointFromText('POINT(39.2083 -6.7924)') WHERE location IS NULL");

            DB::statement("ALTER TABLE delivery_partners MODIFY location POINT NOT NULL");

            Schema::table('delivery_partners', function (Blueprint $table) {
                $table->spatialIndex('location');
            });
        }
    }

    public function down(): void
    {
        Schema::table('delivery_partners', function (Blueprint $table) {
            $table->dropSpatialIndex(['location']);
            $table->dropColumn('location');
        });
    }
};
