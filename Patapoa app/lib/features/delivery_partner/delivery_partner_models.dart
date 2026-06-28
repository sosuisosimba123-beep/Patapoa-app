// Delivery Partner (Rider) Data Models

// Rider Profile Model
class RiderProfile {
  const RiderProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.city,
    required this.rating,
    required this.totalDeliveries,
    required this.vehicleType,
    required this.licensePlate,
    required this.driverLicense,
    required this.isOnline,
    required this.balance,
    required this.owedToPlatform,
    required this.tier,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String city;
  final double rating;
  final int totalDeliveries;
  final String vehicleType; // bicycle, boda, car
  final String licensePlate;
  final String driverLicense;
  final bool isOnline;
  final double balance;
  final double owedToPlatform;
  final String tier; // Bronze, Silver, Gold, Platinum
}

// Order/Delivery Model
class DeliveryOrder {
  const DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.customerRating,
    required this.customerPhone,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupDistance,
    required this.items,
    required this.totalAmount,
    required this.deliveryFee,
    required this.earnings,
    required this.status,
    required this.orderDate,
    required this.isCashOnDelivery,
  });

  final String id;
  final String customerName;
  final double customerRating;
  final String customerPhone;
  final String pickupLocation;
  final String dropoffLocation;
  final double pickupDistance;
  final List<OrderItem> items;
  final double totalAmount;
  final double deliveryFee;
  final double earnings;
  final String status; // assigned, heading_to_pickup, at_pickup, heading_to_dropoff, at_dropoff, completed, cancelled
  final DateTime orderDate;
  final bool isCashOnDelivery;
}

// Order Item Model
class OrderItem {
  const OrderItem({
    required this.name,
    required this.quantity,
  });

  final String name;
  final int quantity;
}

// Transaction Model
class RiderTransaction {
  const RiderTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.status,
    required this.provider,
  });

  final String id;
  final String type; // earnings, withdrawal, cash_collection, payout
  final double amount;
  final String description;
  final DateTime date;
  final String status; // completed, pending, failed
  final String? provider; // M-Pesa, Tigo Pesa, etc.
}

// Weekly Stats Model
class WeeklyStats {
  const WeeklyStats({
    required this.earnings,
    required this.totalDistance,
    required this.tripsCompleted,
    required this.acceptanceRate,
    required this.percentChange,
  });

  final double earnings;
  final double totalDistance;
  final int tripsCompleted;
  final double acceptanceRate;
  final double percentChange;
}

// Demo Data
class RiderDemoData {
  static RiderProfile getProfile() {
    return const RiderProfile(
      id: 'RDR-99283',
      name: 'Juma Hamisi',
      phone: '+255 712 345 678',
      email: 'juma.hamisi@email.com',
      city: 'Dar es Salaam',
      rating: 4.9,
      totalDeliveries: 1248,
      vehicleType: 'boda',
      licensePlate: 'T 123 ABC',
      driverLicense: 'DL-882934',
      isOnline: false,
      balance: 45000,
      owedToPlatform: 0,
      tier: 'Platinum',
    );
  }

  static List<DeliveryOrder> getOrders() {
    return [
      DeliveryOrder(
        id: 'SL-8829',
        customerName: 'Juma H.',
        customerRating: 4.9,
        customerPhone: '+255 755 123 456',
        pickupLocation: 'Mlimani City Mall, Gate 4',
        dropoffLocation: 'Masaki, Plot 45',
        pickupDistance: 1.2,
        items: const [
          OrderItem(name: 'Kilimanjaro Water (1.5L)', quantity: 2),
          OrderItem(name: 'Hand Sanitizer (250ml)', quantity: 1),
        ],
        totalAmount: 12000,
        deliveryFee: 2500,
        earnings: 8500,
        status: 'assigned',
        orderDate: DateTime.now(),
        isCashOnDelivery: true,
      ),
      DeliveryOrder(
        id: 'SL-8830',
        customerName: 'Amina M.',
        customerRating: 4.7,
        customerPhone: '+255 755 789 012',
        pickupLocation: 'Shoprite, Sinza',
        dropoffLocation: 'Mikocheni, Block B',
        pickupDistance: 2.5,
        items: const [
          OrderItem(name: 'Rice (5kg)', quantity: 1),
          OrderItem(name: 'Cooking Oil (1L)', quantity: 2),
        ],
        totalAmount: 35000,
        deliveryFee: 4000,
        earnings: 12200,
        status: 'completed',
        orderDate: DateTime.now().subtract(const Duration(hours: 2)),
        isCashOnDelivery: false,
      ),
    ];
  }

  static List<RiderTransaction> getTransactions() {
    return [
      RiderTransaction(
        id: 'TX-001',
        type: 'earnings',
        amount: 8500,
        description: 'Order #SL-8829',
        date: DateTime.now(),
        status: 'completed',
        provider: null,
      ),
      RiderTransaction(
        id: 'TX-002',
        type: 'earnings',
        amount: 12200,
        description: 'Order #SL-8830',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'completed',
        provider: null,
      ),
      RiderTransaction(
        id: 'TX-003',
        type: 'withdrawal',
        amount: -15000,
        description: 'Cash Out to M-Pesa',
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: 'completed',
        provider: 'M-Pesa',
      ),
      RiderTransaction(
        id: 'TX-004',
        type: 'cash_collection',
        amount: -12400,
        description: 'Order #SL-88291 Cash Collection',
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: 'pending',
        provider: null,
      ),
      RiderTransaction(
        id: 'TX-005',
        type: 'payout',
        amount: 85000,
        description: 'Weekly Payout',
        date: DateTime.now(),
        status: 'completed',
        provider: 'M-Pesa',
      ),
    ];
  }

  static WeeklyStats getWeeklyStats() {
    return const WeeklyStats(
      earnings: 450000,
      totalDistance: 142,
      tripsCompleted: 14,
      acceptanceRate: 98,
      percentChange: 12,
    );
  }

  static String formatTZS(double amount) {
    return 'TZS ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}
