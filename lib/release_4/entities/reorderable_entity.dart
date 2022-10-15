import 'package:flutter/cupertino.dart';

/// Represents [child] with some extra information.
///
/// When animating all children in this package, this entity is important
/// to have access to all needed values of [child].
///
/// With this entity, it is possible to know where the [child] is
/// positioned and which order that [child] has inside all children.
///
/// Also the current state of [child] is added as information: [isBuilding],
/// [isNew] and [hasSwappedOrder].
class ReorderableEntity {
  static const _isNewChildId = -1;

  final ValueKey key;

  final int originalOrderId;
  final int updatedOrderId;

  final Offset originalOffset;
  final Offset updatedOffset;

  final bool isBuildingOffset;
  final bool hasSwappedOrder;

  const ReorderableEntity({
    required this.key,
    required this.originalOrderId,
    required this.updatedOrderId,
    required this.originalOffset,
    required this.updatedOffset,
    required this.isBuildingOffset,
    required this.hasSwappedOrder,
  });

  factory ReorderableEntity.create({
    required ValueKey key,
    required int updatedOrderId,
    Offset? offset,
  }) =>
      ReorderableEntity(
        key: key,
        originalOrderId: _isNewChildId,
        updatedOrderId: updatedOrderId,
        originalOffset: offset ?? Offset.zero,
        updatedOffset: offset ?? Offset.zero,
        isBuildingOffset: offset == null,
        hasSwappedOrder: false,
      );

  @override
  bool operator ==(Object other) {
    return other is ReorderableEntity &&
        (other.key == key &&
            other.originalOffset == originalOffset &&
            other.originalOrderId == originalOrderId &&
            other.updatedOrderId == updatedOrderId &&
            other.updatedOffset == updatedOffset &&
            other.isBuildingOffset == isBuildingOffset &&
            other.hasSwappedOrder == hasSwappedOrder);
  }

  @override
  int get hashCode => originalOrderId + updatedOrderId;

  @override
  String toString() =>
      '[$key]: Original OrderId: $originalOrderId, Updated OrderId: $updatedOrderId, Original Offset: $originalOffset, Updated Offset: $updatedOffset';

  ReorderableEntity copyWith({
    int? originalOrderId,
    int? updatedOrderId,
    Offset? originalOffset,
    Offset? updatedOffset,
    bool? isBuildingOffset,
    bool? hasSwappedOrder,
  }) =>
      ReorderableEntity(
        key: key,
        originalOrderId: originalOrderId ?? this.originalOrderId,
        updatedOrderId: updatedOrderId ?? this.updatedOrderId,
        originalOffset: originalOffset ?? this.originalOffset,
        updatedOffset: updatedOffset ?? this.updatedOffset,
        isBuildingOffset: isBuildingOffset ?? this.isBuildingOffset,
        hasSwappedOrder: hasSwappedOrder ?? this.hasSwappedOrder,
      );

  ReorderableEntity fadedIn() => ReorderableEntity(
        key: key,
        originalOrderId: updatedOrderId,
        updatedOrderId: updatedOrderId,
        originalOffset: updatedOffset,
        updatedOffset: updatedOffset,
        isBuildingOffset: false,
        hasSwappedOrder: false,
      );

  ReorderableEntity creationFinished({
    required Offset? offset,
  }) {
    var updatedOffset = this.updatedOffset;
    if (offset != null) {
      updatedOffset = offset;
    }

    return ReorderableEntity(
      key: key,
      originalOrderId: originalOrderId,
      updatedOrderId: updatedOrderId,
      originalOffset: originalOffset,
      updatedOffset: updatedOffset,
      isBuildingOffset: false,
      hasSwappedOrder: false, // todo false wirklich richtig?
    );
  }

  ReorderableEntity updated({
    required int updatedOrderId,
    required Offset? updatedOffset,
  }) {
    var originalOrderId = this.originalOrderId;
    var originalOffset = this.originalOffset;

    // should only update original when previous updated orderId is different to previous one
    if (updatedOrderId != this.updatedOrderId) {
      originalOrderId = this.updatedOrderId;
      originalOffset = this.updatedOffset;
    }

    return ReorderableEntity(
      key: key,
      originalOrderId: originalOrderId,
      updatedOrderId: updatedOrderId,
      originalOffset: originalOffset,
      updatedOffset: updatedOffset ?? this.updatedOffset,
      isBuildingOffset: updatedOffset == null,
      hasSwappedOrder:
          updatedOrderId != originalOrderId && updatedOffset != null,
    );
  }

  ReorderableEntity positionUpdated() => ReorderableEntity(
        key: key,
        originalOrderId: updatedOrderId,
        updatedOrderId: updatedOrderId,
        originalOffset: updatedOffset,
        updatedOffset: updatedOffset,
        isBuildingOffset: false,
        hasSwappedOrder: false,
      );

  bool get isNew => originalOrderId == _isNewChildId;
}