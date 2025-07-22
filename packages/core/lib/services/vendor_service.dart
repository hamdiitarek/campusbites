import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/models/vendor.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Vendor>> getVendors() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('vendors')
          .where('isApproved', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        return Vendor.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching vendors: $e');
      return [];
    }
  }

  Future<Vendor?> getVendorById(String vendorId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('vendors').doc(vendorId).get();

      if (doc.exists) {
        return Vendor.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching vendor: $e');
      return null;
    }
  }

  Future<void> createVendor(
      Map<String, Object> vendorData, String userId) async {}
}
