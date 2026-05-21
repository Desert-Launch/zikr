import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

import 'package:hive_ce_flutter/hive_flutter.dart';

abstract class HiveBoxBase<T> {
  HiveBoxBase(this.boxName, [this.adapter]);

  final String boxName;
  final TypeAdapter<T>? adapter;

  Future<bool> init() async {
    try {
      // Check if Hive is initialized
      if (!Hive.isBoxOpen(boxName)) {
        // Register adapter if provided and not already registered
        if (adapter != null && !Hive.isAdapterRegistered(adapter!.typeId)) {
          Hive.registerAdapter(adapter!);
          developer.log('Registered adapter for $boxName with typeId: ${adapter!.typeId}');
        }
        await Hive.openBox<T>(boxName);
      }
    } catch (e) {
      developer.log('Error initializing box $boxName: $e');

      // Only try to delete and recreate if Hive is properly initialized
      try {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box<T>(boxName).close();
        }
        // await Hive.deleteBoxFromDisk(boxName);
        // developer.log('Deleted corrupted box $boxName');
      } catch (deleteError) {
        developer.log('Error deleting box $boxName: $deleteError');
        return false;
      }

      try {
        await Hive.openBox<T>(boxName);
        developer.log('Successfully recreated box $boxName');
      } catch (openBoxError2) {
        developer.log('Error opening box $boxName after deletion: $openBoxError2');
        return false;
      }
    }

    try {
      final boxInstance = Hive.box<T>(boxName);
      developer.log('HiveBoxBase: $boxName initialized - count: ${boxInstance.length}');
      return true;
    } catch (e) {
      developer.log('Error accessing box $boxName after initialization: $e');
      return false;
    }
  }

  String get getBoxName => boxName;

  Box<T> get box {
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError('Box $boxName is not open. Call init() first.');
    }
    return Hive.box<T>(boxName);
  }

  // get listenable()
  ValueListenable<Box<T>> get listenable {
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError('Box $boxName is not open. Call init() first.');
    }
    return Hive.box<T>(boxName).listenable();
  }
}
