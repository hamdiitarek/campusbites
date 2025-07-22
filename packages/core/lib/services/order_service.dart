import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/models/order.dart' as app_models;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new order in both collections
  Future<String> createOrder(app_models.Order order) async {
    try {
      // Create a document reference with auto-generated ID in the main orders collection
      final orderRef = _firestore.collection('orders').doc();
      final String orderId = orderRef.id;

      // Create the order with the generated ID
      final orderWithId = app_models.Order(
        id: orderId,
        userId: order.userId,
        vendorId: order.vendorId,
        items: order.items,
        total: order.total,
        status: order.status,
        paymentMethod: order.paymentMethod,
        createdAt: order.createdAt,
      );

      // Convert to map for Firestore
      final orderData = orderWithId.toMap();

      // Use a batch to ensure consistency
      final batch = _firestore.batch();

      // Set in main orders collection
      batch.set(orderRef, orderData);

      // Set in vendor's orders subcollection
      final vendorOrderRef = _firestore
          .collection('vendors')
          .doc(order.vendorId)
          .collection('orders')
          .doc(orderId);

      batch.set(vendorOrderRef, orderData);

      // Commit the batch
      await batch.commit();

      return orderId;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  // Update order status in both collections
  Future<void> updateOrderStatus(
      String orderId, String vendorId, String newStatus) async {
    try {
      final batch = _firestore.batch();

      // Update in main orders collection
      final mainOrderRef = _firestore.collection('orders').doc(orderId);
      batch.update(mainOrderRef, {'status': newStatus});

      // Update in vendor's orders subcollection
      final vendorOrderRef = _firestore
          .collection('vendors')
          .doc(vendorId)
          .collection('orders')
          .doc(orderId);

      batch.update(vendorOrderRef, {'status': newStatus});

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  } // Get orders for a specific user

  Stream<List<app_models.Order>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => app_models.Order.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get orders for a specific vendor (from vendor's subcollection)
  Stream<List<app_models.Order>> getVendorOrders(String vendorId) {
    return _firestore
        .collection('vendors')
        .doc(vendorId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => app_models.Order.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get a specific order (checks both locations)
  Future<app_models.Order?> getOrderById(String orderId,
      {String? vendorId}) async {
    try {
      DocumentSnapshot? orderDoc;

      // If vendorId is provided, try the vendor subcollection first
      if (vendorId != null) {
        orderDoc = await _firestore
            .collection('vendors')
            .doc(vendorId)
            .collection('orders')
            .doc(orderId)
            .get();

        if (orderDoc.exists) {
          final data = orderDoc.data();
          if (data != null) {
            return app_models.Order.fromMap(
                orderDoc.id, data as Map<String, dynamic>);
          }
        }
      }

      // Try the main orders collection
      orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (orderDoc.exists) {
        final data = orderDoc.data();
        if (data != null) {
          return app_models.Order.fromMap(
              orderDoc.id, data as Map<String, dynamic>);
        }
      }

      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Handle order deletion (from both collections)
  Future<void> deleteOrder(String orderId, String vendorId) async {
    try {
      final batch = _firestore.batch();

      // Delete from main orders collection
      final mainOrderRef = _firestore.collection('orders').doc(orderId);
      batch.delete(mainOrderRef);

      // Delete from vendor's orders subcollection
      final vendorOrderRef = _firestore
          .collection('vendors')
          .doc(vendorId)
          .collection('orders')
          .doc(orderId);

      batch.delete(vendorOrderRef);

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }

  // Sync an order that might be out of sync
  Future<void> syncOrder(String orderId, String vendorId) async {
    try {
      // Get the order from main collection
      final mainOrderDoc =
          await _firestore.collection('orders').doc(orderId).get();

      if (!mainOrderDoc.exists) {
        // Order doesn't exist in main collection, try to get from vendor subcollection
        final vendorOrderDoc = await _firestore
            .collection('vendors')
            .doc(vendorId)
            .collection('orders')
            .doc(orderId)
            .get();

        if (vendorOrderDoc.exists) {
          // Copy from vendor subcollection to main collection
          await _firestore
              .collection('orders')
              .doc(orderId)
              .set(vendorOrderDoc.data() ?? {});
        }
      } else {
        // Order exists in main collection, sync to vendor subcollection
        await _firestore
            .collection('vendors')
            .doc(vendorId)
            .collection('orders')
            .doc(orderId)
            .set(mainOrderDoc.data() ?? {});
      }
    } catch (e) {
      print('Error syncing order: $e');
      rethrow;
    }
  }

  // Sync all orders for a vendor
  Future<void> syncAllVendorOrders(String vendorId) async {
    try {
      // Get all orders from the main collection for this vendor
      final mainOrdersQuery = await _firestore
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      // Get all orders from vendor's subcollection
      final vendorOrdersQuery = await _firestore
          .collection('vendors')
          .doc(vendorId)
          .collection('orders')
          .get();

      // Create maps for easy lookup
      final mainOrdersMap = {
        for (var doc in mainOrdersQuery.docs) doc.id: doc.data()
      };

      final vendorOrdersMap = {
        for (var doc in vendorOrdersQuery.docs) doc.id: doc.data()
      };

      // Batch for efficiency
      final batch = _firestore.batch();

      // Sync orders from main to vendor subcollection
      for (final entry in mainOrdersMap.entries) {
        final orderId = entry.key;
        final orderData = entry.value;

        final vendorOrderRef = _firestore
            .collection('vendors')
            .doc(vendorId)
            .collection('orders')
            .doc(orderId);

        batch.set(vendorOrderRef, orderData);
      }

      // Sync orders from vendor subcollection to main
      for (final entry in vendorOrdersMap.entries) {
        final orderId = entry.key;
        final orderData = entry.value;

        if (!mainOrdersMap.containsKey(orderId)) {
          final mainOrderRef = _firestore.collection('orders').doc(orderId);
          batch.set(mainOrderRef, orderData);
        }
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error syncing all vendor orders: $e');
      rethrow;
    }
  }
}
