<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SecurityAlert extends Model
{
    protected $fillable = [
        'type',
        'title',
        'description',
        'source_ip',
        'status',
    ];
}
