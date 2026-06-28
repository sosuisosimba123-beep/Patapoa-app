// Merchant Product Model
class MerchantProduct {
  const MerchantProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.sku,
    required this.description,
    required this.stock,
    required this.imageUrl,
    this.deliveryAvailable = true,
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final String sku;
  final String description;
  final int stock;
  final String imageUrl;
  final bool deliveryAvailable;
}

// Merchant Order Model
class MerchantOrder {
  const MerchantOrder({
    required this.id,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.earnings,
  });

  final String id;
  final String customerName;
  final List<String> items;
  final int totalAmount;
  final String status; // pending, preparing, ready, completed
  final DateTime orderDate;
  final int? earnings;
}

// Merchant Wallet Transaction
class MerchantTransaction {
  const MerchantTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.status,
  });

  final String id;
  final String type; // sale, commission, payout
  final int amount;
  final String description;
  final DateTime date;
  final String status;
}

// Merchant Profile Data
class MerchantProfile {
  const MerchantProfile({
    required this.storeName,
    required this.email,
    required this.location,
    required this.phoneNumber,
    this.mpesaNumber,
    this.bankAccount,
  });

  final String storeName;
  final String email;
  final String location;
  final String phoneNumber;
  final String? mpesaNumber;
  final String? bankAccount;
}

// Demo Data
class MerchantDemoData {
  static List<MerchantProduct> getProducts() {
    return [
      MerchantProduct(
        id: '1',
        name: 'Pro Run Alpha v2',
        category: 'Footwear',
        price: 145000,
        sku: 'FTW-9902-RD',
        description: 'Premium athletic footwear with responsive cushioning',
        stock: 15,
        imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
        deliveryAvailable: true,
      ),
      MerchantProduct(
        id: '2',
        name: 'Nexus SmartWatch Lite',
        category: 'Electronics',
        price: 89000,
        sku: 'ELC-2031-WH',
        description: 'Minimalist white smartwatch with matte finish',
        stock: 0,
        imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
        deliveryAvailable: true,
      ),
      MerchantProduct(
        id: '3',
        name: 'Aura Sound ANC',
        category: 'Electronics',
        price: 320000,
        sku: 'AUD-1105-BK',
        description: 'High-end wireless headphones with ANC',
        stock: 42,
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
        deliveryAvailable: true,
      ),
      MerchantProduct(
        id: '4',
        name: 'Luna Tote Leather',
        category: 'Accessories',
        price: 210000,
        sku: 'BAG-4421-BN',
        description: 'Designer leather handbag',
        stock: 3,
        imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400',
        deliveryAvailable: true,
      ),
    ];
  }

  static List<MerchantOrder> getOrders() {
    final now = DateTime.now();
    return [
      MerchantOrder(
        id: 'ORD-001',
        customerName: 'Sarah Mushi',
        items: ['2x Kilimanjaro Water 1.5L', '1x Fresh Cassava Pack'],
        totalAmount: 12500,
        status: 'pending',
        orderDate: now.subtract(const Duration(minutes: 2)),
        earnings: 4500,
      ),
      MerchantOrder(
        id: 'ORD-002',
        customerName: 'Said Bakari',
        items: ['1x Local Eggs (Tray)', '2kg Maize Flour'],
        totalAmount: 24200,
        status: 'pending',
        orderDate: now.subtract(const Duration(minutes: 15)),
        earnings: 8500,
      ),
      MerchantOrder(
        id: 'ORD-003',
        customerName: 'Juma Hamisi',
        items: ['3x Soft Drinks', '2x Bread'],
        totalAmount: 46500,
        status: 'preparing',
        orderDate: now.subtract(const Duration(hours: 1)),
        earnings: 18000,
      ),
      MerchantOrder(
        id: 'ORD-004',
        customerName: 'Aisha Mohamed',
        items: ['1x Rice 5kg', '2x Cooking Oil'],
        totalAmount: 18500,
        status: 'preparing',
        orderDate: now.subtract(const Duration(hours: 2)),
        earnings: 7000,
      ),
      MerchantOrder(
        id: 'ORD-005',
        customerName: 'Bakari M.',
        items: ['1x Sugar 2kg'],
        totalAmount: 12500,
        status: 'completed',
        orderDate: now.subtract(const Duration(hours: 3)),
        earnings: 5000,
      ),
    ];
  }

  static List<MerchantTransaction> getTransactions() {
    final now = DateTime.now();
    return [
      MerchantTransaction(
        id: 'TXN-001',
        type: 'sale',
        amount: 45000,
        description: 'Order #SL-8921',
        date: now,
        status: 'settled',
      ),
      MerchantTransaction(
        id: 'TXN-002',
        type: 'commission',
        amount: -6750,
        description: 'Platform Commission (15%)',
        date: now,
        status: 'settled',
      ),
      MerchantTransaction(
        id: 'TXN-003',
        type: 'sale',
        amount: 112000,
        description: 'Order #SL-8919',
        date: now.subtract(const Duration(days: 1)),
        status: 'settled',
      ),
      MerchantTransaction(
        id: 'TXN-004',
        type: 'commission',
        amount: -16800,
        description: 'Platform Commission (15%)',
        date: now.subtract(const Duration(days: 1)),
        status: 'settled',
      ),
      MerchantTransaction(
        id: 'TXN-005',
        type: 'sale',
        amount: 85000,
        description: 'Order #SL-8915',
        date: now.subtract(const Duration(days: 3)),
        status: 'settled',
      ),
    ];
  }

  static MerchantProfile getProfile() {
    return const MerchantProfile(
      storeName: 'Zanzibar Spice & Tech',
      email: 'contact@zanzibarspice.tz',
      location: 'Kariakoo, Dar es Salaam',
      phoneNumber: '+255 754 000 000',
      mpesaNumber: '+255 754 000 000',
    );
  }
}

// Utility function for TZS formatting
String formatTzs(int amount) {
  return 'TZS ${amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  )}';
}
