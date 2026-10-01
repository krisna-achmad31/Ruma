import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> seedFirestoreIfNeeded() async {
  final firestore = FirebaseFirestore.instance;

  final alreadySeeded =
      (await firestore.collection('families').doc('family_demo').get())
          .exists;
  if (alreadySeeded) {
    return;
  }

  final raw = await rootBundle.loadString('assets/firestore_seed_data.json');
  final Map<String, dynamic> data = jsonDecode(raw);

  for (final entry in data.entries) {
    final path = entry.key;
    final value = entry.value as Map<String, dynamic>;

    if (path.contains('/')) {
      final parts = path.split('/');
      final subcollectionRef = firestore
          .collection(parts[0])
          .doc(parts[1])
          .collection(parts[2]);

      for (final doc in value.entries) {
        await subcollectionRef.doc(doc.key).set(doc.value as Map<String, dynamic>);
      }
    } else {
      final collectionRef = firestore.collection(path);
      for (final doc in value.entries) {
        await collectionRef.doc(doc.key).set(doc.value as Map<String, dynamic>);
      }
    }
  }
}
