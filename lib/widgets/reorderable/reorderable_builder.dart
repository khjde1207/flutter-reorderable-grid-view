import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_reorderable_grid_view/entities/reorderable_entity.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable/reorderable_animated_child.dart';

typedef DraggableBuilder = Widget Function(
  List<Widget> children,
  ScrollController scrollController,
);

class ReorderableBuilder extends StatefulWidget {
  final List<Widget> children;
  final DraggableBuilder builder;
  final ReorderCallback onReorder;
  final List<int> lockedIndices;
  final bool enableAnimation;
  final bool enableLongPress;
  final Duration longPressDelay;
  final bool enableDraggable;

  final ScrollController? scrollController;
  final BoxDecoration? dragChildBoxDecoration;

  const ReorderableBuilder({
    required this.children,
    required this.onReorder,
    required this.builder,
    this.lockedIndices = const [],
    this.enableAnimation = true,
    this.enableLongPress = true,
    this.longPressDelay = kLongPressTimeout,
    this.enableDraggable = true,
    this.dragChildBoxDecoration,
    this.scrollController,
    Key? key,
  }) : super(key: key);

  @override
  _ReorderableBuilderState createState() => _ReorderableBuilderState();
}

class _ReorderableBuilderState extends State<ReorderableBuilder>
    with WidgetsBindingObserver {
  ReorderableEntity? draggedReorderableEntity;

  var _childrenMap = <int, ReorderableEntity>{};

  final _offsetMap = <int, Offset>{};

  late final ScrollController _scrollController;

  double scrollPositionPixels = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);

    _scrollController = widget.scrollController ?? ScrollController();

    _updateChildren();
  }

  @override
  void didChangeMetrics() {
    final orientationBefore = MediaQuery.of(context).orientation;
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final orientationAfter = MediaQuery.of(context).orientation;
      if (orientationBefore != orientationAfter) {
        // rebuild all items
      }
    });
  }

  @override
  void didUpdateWidget(covariant ReorderableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.children != widget.children) {
      _updateChildren();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      _getDraggableChildren(),
      _scrollController,
    );
  }

  List<Widget> _getDraggableChildren() {
    final draggableChildren = <Widget>[];
    final sortedChildren = _childrenMap.values.toList()
      ..sort((a, b) => a.originalOrderId.compareTo(b.originalOrderId));

    final enableAnimation =
        draggedReorderableEntity != null && widget.enableAnimation;

    for (final reorderableEntity in sortedChildren) {
      draggableChildren.add(
        ReorderableAnimatedChild(
          key: reorderableEntity.child.key,
          draggedReorderableEntity: draggedReorderableEntity,
          enableAnimation: enableAnimation,
          enableLongPress: widget.enableLongPress,
          longPressDelay: widget.longPressDelay,
          enableDraggable: widget.enableDraggable,
          onDragUpdate: _handleDragUpdate,
          onCreated: _handleCreated,
          onDragStarted: _handleDragStarted,
          onDragEnd: _handleDragEnd,
          reorderableEntity: reorderableEntity,
          dragChildBoxDecoration: widget.dragChildBoxDecoration,
        ),
      );
    }

    return draggableChildren;
  }

  void _updateChildren() {
    var orderId = 0;

    final checkDuplicatedKeyList = <int>[];

    final updatedChildrenMap = <int, ReorderableEntity>{};

    for (final child in widget.children) {
      final hashKey = child.key.hashCode;

      if (!checkDuplicatedKeyList.contains(hashKey)) {
        checkDuplicatedKeyList.add(hashKey);
      } else {
        throw Exception('Duplicated key $hashKey found in children');
      }

      final reorderableEntity = _childrenMap[hashKey];
      bool isBuilding = !_offsetMap.containsKey(orderId);

      if (reorderableEntity == null) {
        updatedChildrenMap[hashKey] = ReorderableEntity(
          child: child,
          originalOrderId: orderId,
          updatedOrderId: orderId,
          updatedOffset: _offsetMap[orderId] ?? Offset.zero,
          originalOffset: _offsetMap[orderId] ?? Offset.zero,
          isBuilding: isBuilding,
        );
      } else {
        updatedChildrenMap[hashKey] = reorderableEntity.copyWith(
          child: child,
          originalOrderId: orderId,
          updatedOrderId: orderId,
          updatedOffset: _offsetMap[orderId],
          originalOffset: _offsetMap[orderId],
          isBuilding: isBuilding,
        );
      }

      orderId++;
    }
    setState(() {
      _childrenMap = updatedChildrenMap;
    });
  }

  ReorderableEntity? _handleCreated(int hashKey, GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      // assert(false, 'RenderBox of child should not be null!');
    } else {
      final reorderableEntity = _childrenMap[hashKey]!;
      final localOffset = renderBox.localToGlobal(Offset.zero);
      final offset = Offset(
        localOffset.dx,
        localOffset.dy + _scrollPixels,
      );
      final size = renderBox.size;
      final updatedReorderableEntity = reorderableEntity.copyWith(
        size: size,
        originalOffset: offset,
        updatedOffset: offset,
        isBuilding: false,
      );
      _childrenMap[hashKey] = updatedReorderableEntity;
      _offsetMap[reorderableEntity.updatedOrderId] = offset;

      return updatedReorderableEntity;
    }

    return null;
  }

  void _handleDragStarted(ReorderableEntity reorderableEntity) {
    setState(() {
      draggedReorderableEntity = reorderableEntity;
      scrollPositionPixels = _scrollPixels;
    });
  }

  void _handleDragUpdate(int hashKey, DragUpdateDetails details) {
    _checkForCollisions(details: details);
  }

  /// Updates all children in map when dragging ends.
  ///
  /// Every updated child gets a new offset and orderId.
  void _handleDragEnd(DraggableDetails details) {
    int? oldIndex;
    int? newIndex;

    final originalOffset = draggedReorderableEntity!.originalOffset;
    final updatedOffset = draggedReorderableEntity!.updatedOffset;

    // the dragged item has changed position
    if (originalOffset != updatedOffset) {
      // looking for the old and new index
      for (final offsetMapEntry in _offsetMap.entries) {
        final offset = offsetMapEntry.value;

        if (offset == draggedReorderableEntity!.originalOffset) {
          oldIndex = offsetMapEntry.key;
        } else if (offset == draggedReorderableEntity!.updatedOffset) {
          newIndex = offsetMapEntry.key;
        }

        if (oldIndex != 0 && newIndex != 0) {
          break;
        }
      }

      final updatedChildrenMap = <int, ReorderableEntity>{};

      // updating all entries in childrenMap
      for (final childrenMapEntry in _childrenMap.entries) {
        final reorderableEntity = childrenMapEntry.value;

        final updatedEntryValue = childrenMapEntry.value.copyWith(
          originalOrderId: reorderableEntity.updatedOrderId,
          originalOffset: reorderableEntity.updatedOffset,
        );

        updatedChildrenMap[childrenMapEntry.key] = updatedEntryValue;
      }

      _childrenMap = updatedChildrenMap;
    }

    setState(() {
      draggedReorderableEntity = null;
    });

    if (oldIndex != null && newIndex != null) {
      widget.onReorder(oldIndex, newIndex);
    }
  }

  /// some more logical functions

  void _checkForCollisions({
    required DragUpdateDetails details,
  }) {
    final draggedHashKey = draggedReorderableEntity!.child.key.hashCode;

    var draggedOffset = Offset(
      details.localPosition.dx,
      details.localPosition.dy + scrollPositionPixels,
    );

    final collisionMapEntry = _getCollisionMapEntry(
      draggedHashKey: draggedHashKey,
      draggedOffset: draggedOffset,
    );

    if (collisionMapEntry != null) {
      final draggedOrderId = draggedReorderableEntity!.updatedOrderId;
      final collisionOrderId = collisionMapEntry.value.updatedOrderId;

      final difference = draggedOrderId - collisionOrderId;
      if (difference > 1) {
        _updateMultipleCollisions(
          collisionOrderId: collisionOrderId,
          draggedHashKey: draggedHashKey,
          isBackwards: true,
        );
      } else if (difference < -1) {
        _updateMultipleCollisions(
          collisionOrderId: collisionOrderId,
          draggedHashKey: draggedHashKey,
          isBackwards: false,
        );
      } else {
        _updateCollision(
          draggedHashKey: draggedHashKey,
          collisionMapEntry: collisionMapEntry,
        );
      }
    }
  }

  void _updateMultipleCollisions({
    required int draggedHashKey,
    required int collisionOrderId,
    required bool isBackwards,
  }) {
    final summands = isBackwards ? -1 : 1;
    var currentCollisionOrderId = draggedReorderableEntity!.updatedOrderId;

    while (currentCollisionOrderId != collisionOrderId) {
      currentCollisionOrderId += summands;

      if (!widget.lockedIndices.contains(currentCollisionOrderId)) {
        final collisionMapEntry = _childrenMap.entries.firstWhere(
          (entry) => entry.value.updatedOrderId == currentCollisionOrderId,
        );
        _updateCollision(
          draggedHashKey: draggedHashKey,
          collisionMapEntry: collisionMapEntry,
        );
      }
    }
  }

  void _updateCollision({
    required int draggedHashKey,
    required MapEntry<int, ReorderableEntity> collisionMapEntry,
  }) {
    final collisionOrderId = collisionMapEntry.value.updatedOrderId;
    if (widget.lockedIndices.contains(collisionOrderId)) {
      return;
    }

    // update for collision entity
    final updatedCollisionEntity = collisionMapEntry.value.copyWith(
      updatedOffset: draggedReorderableEntity!.updatedOffset,
      updatedOrderId: draggedReorderableEntity!.updatedOrderId,
    );
    _childrenMap[collisionMapEntry.key] = updatedCollisionEntity;

    // update for dragged entity
    final updatedDraggedEntity = draggedReorderableEntity!.copyWith(
      updatedOffset: collisionMapEntry.value.updatedOffset,
      updatedOrderId: collisionMapEntry.value.updatedOrderId,
    );
    _childrenMap[draggedHashKey] = updatedDraggedEntity;

    setState(() {
      draggedReorderableEntity = updatedDraggedEntity;
    });
  }

  MapEntry<int, ReorderableEntity>? _getCollisionMapEntry({
    required int draggedHashKey,
    required Offset draggedOffset,
  }) {
    for (final entry in _childrenMap.entries) {
      final localPosition = entry.value.updatedOffset;
      final size = entry.value.size;

      if (entry.key == draggedHashKey) {
        continue;
      }

      // checking collision with full item size and local position
      if (draggedOffset.dx >= localPosition.dx &&
          draggedOffset.dy >= localPosition.dy &&
          draggedOffset.dx <= localPosition.dx + size.width &&
          draggedOffset.dy <= localPosition.dy + size.height) {
        return entry;
      }
    }
  }

  /// Returning the current scroll position.
  ///
  /// There are two possibilities to get the scroll position.
  ///
  /// First one is, that the built child is scrollable.
  /// In this case, it is important, the [_scrollController] is added
  /// to the scrollable child.
  ///
  /// Another possibility is that one of the parents is scrollable.
  /// In that case, the position of the scroll is accessible inside [context].
  double get _scrollPixels {
    var pixels = Scrollable.of(context)?.position.pixels;
    if (pixels != null) {
      return pixels;
    } else {
      return _scrollController.position.pixels;
    }
  }
}

/*
    ///
    /// some prints for me
    ///

    final draggedOrderIdBefore = draggedReorderableEntity?.updatedOrderId;
    final draggedOrderIdAfter = updatedDraggedEntity.updatedOrderId;

    final draggedOriginalOffset = updatedDraggedEntity.originalOffset;
    final draggedOffsetBefore = draggedReorderableEntity?.updatedOffset;
    final draggedOffsetAfter = updatedDraggedEntity.updatedOffset;

    final collisionOrderIdBefore = collisionMapEntry.value.updatedOrderId;
    final collisionOrderIdAfter = updatedCollisionEntity.updatedOrderId;

    final collisionOriginalOffset = collisionMapEntry.value.originalOffset;
    final collisionOffsetBefore = collisionMapEntry.value.updatedOffset;
    final collisionOffsetAfter = updatedCollisionEntity.updatedOffset;

    print('');
    print('---- Dragged child at position $draggedOrderIdBefore ----');
    print(
    'Dragged child from position $draggedOrderIdBefore to $draggedOrderIdAfter');
    print('Dragged child original offset $draggedOriginalOffset');
    print(
    'Dragged child from offset $draggedOffsetBefore to $draggedOffsetAfter');
    print('----');
    print(
    'Collisioned child from position $collisionOrderIdBefore to $collisionOrderIdAfter');
    print('Collisioned child original offset $collisionOriginalOffset');
    print(
    'Collisioned child from offset $collisionOffsetBefore to $collisionOffsetAfter');
    print('---- END ----');
    print('');

 */