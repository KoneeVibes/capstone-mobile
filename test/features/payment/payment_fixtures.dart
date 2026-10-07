import 'package:propertyintelmobileapp/features/payment/domain/entities/invoice.dart';
import 'package:propertyintelmobileapp/features/payment/domain/entities/payment_session.dart';

/// The live invoice for the throwaway case `PI-DU2964LK`, 6 Oct 2026.
const Map<String, Object?> invoiceJson = {
  '_id': '6ac53c577b31cdfa796c6e6b',
  'id': 'b2516f32-14e9-41ad-9671-0b1dede6f602',
  'caseId': '0219cf66-eb3a-4b71-8f84-ce3d277c3fa6',
  'items': [
    {
      'name': 'Registry Search',
      'description': 'Lagos Land Registry',
      'quantity': 1,
      'unitPrice': 5062,
    },
    {
      'name': 'Title Verification',
      'description': 'Certificate of Occupancy (C of O)',
      'quantity': 1,
      'unitPrice': 3937,
    },
    {
      'name': 'Survey Chart Verification',
      'description': "Surveyor General's Office",
      'quantity': 1,
      'unitPrice': 2251,
    },
  ],
  'transactionAccessCode': null,
  'transactionReference': null,
  'currency': 'NGN',
  'status': 'unpaid',
  'totalPayable': 11250,
};

/// The live settle reply, 7 Oct 2026.
const Map<String, Object?> sessionJson = {
  'accessCode': '97y8x8lhufrm25y',
  'reference': 'T354204543241066',
};

const session = PaymentSession(
  accessCode: '97y8x8lhufrm25y',
  reference: 'T354204543241066',
);

Invoice invoice({bool isPaid = false}) => Invoice(
  id: 'inv',
  items: const [],
  total: 4500,
  currency: 'NGN',
  isPaid: isPaid,
);
