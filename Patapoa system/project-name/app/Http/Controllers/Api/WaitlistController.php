<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Waitlist;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class WaitlistController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required_without:phone|nullable|email',
            'phone' => 'required_without:email|nullable|string',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'city' => 'nullable|string',
            'requested_product' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $waitlist = Waitlist::create($request->all());

        return $this->successResponse($waitlist, 'You have been added to the waitlist. We will notify you when we expand to your area!', 201);
    }
}
