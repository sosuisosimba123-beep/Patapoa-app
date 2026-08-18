<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Merchant;
use App\Models\DeliveryPartner;
use App\Models\Order;
use App\Models\Address;
use App\Models\Wallet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseCleanupSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $driver = DB::getDriverName();

        // 1. Disable foreign key checks to allow truncating/deleting
        if ($driver === 'mysql') {
            DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        } elseif ($driver === 'sqlite') {
            DB::statement('PRAGMA foreign_keys = OFF;');
        }

        // 2. Identify Admin User(s) to preserve
        $adminIds = User::where('user_type', 'admin')->pluck('id')->toArray();

        // 3. Delete non-admin associated data
        // Delete all orders, as they are likely test data
        DB::table('orders')->truncate();
        DB::table('order_items')->truncate();

        // Delete all wallets except admins'
        Wallet::whereNotIn('user_id', $adminIds)->delete();

        // Delete all addresses except admins'
        Address::whereNotIn('user_id', $adminIds)->delete();

        // Delete all merchants and riders (since they are users)
        DB::table('merchants')->truncate();
        DB::table('delivery_partners')->truncate();

        // Delete all non-admin users
        User::whereNotIn('id', $adminIds)->delete();

        // 4. Re-enable foreign key checks
        if ($driver === 'mysql') {
            DB::statement('SET FOREIGN_KEY_CHECKS=1;');
        } elseif ($driver === 'sqlite') {
            DB::statement('PRAGMA foreign_keys = ON;');
        }

        $this->command->info('Database cleaned! All non-admin credentials have been removed.');
    }
}
