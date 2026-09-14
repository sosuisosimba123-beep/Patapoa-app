<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('security_alerts', function (Blueprint $table) {
            $table->id();
            $table->string('type'); // critical, warning, info
            $table->string('title');
            $table->text('description');
            $table->string('source_ip')->nullable();
            $table->string('status')->default('active'); // active, investigating, resolved
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('security_alerts');
    }
};
