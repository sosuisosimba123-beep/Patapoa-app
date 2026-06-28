<?php

namespace App\Http\Controllers;

use App\Http\Traits\ApiResponse;
use App\Http\Traits\HasPagination;
use App\Http\Traits\HasCache;
use App\Http\Traits\SelectiveFields;

abstract class Controller
{
    use ApiResponse, HasPagination, HasCache, SelectiveFields;
}
