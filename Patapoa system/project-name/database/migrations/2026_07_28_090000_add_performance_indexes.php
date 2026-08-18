<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('merchants', function (Blueprint $table) {
            $table->index(['latitude', 'longitude']);
            // is_verified and is_online already indexed in 2026_06_28_100000_add_performance_indexes.php
        });

        // products indexes (is_available, price) already indexed in 2026_06_28_100000_add_performance_indexes.php

        Schema::table('search_logs', function (Blueprint $table) {
            $table->index('query');
            $table->index(['latitude', 'longitude']);
        });
    }

    public function down(): void
    {
        Schema::table('merchants', function (Blueprint $table) {
            $table->dropIndex(['latitude', 'longitude']);
        });

        Schema::table('search_logs', function (Blueprint $table) {
            $table->dropIndex(['query']);
            $table->dropIndex(['latitude', 'longitude']);
        });
    }
};
