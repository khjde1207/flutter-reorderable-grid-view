import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';

enum ReorderableType {
  wrap,
  gridView,
  gridViewCount,
  gridViewExtent,
  gridViewBuilder,
}

// Todo:
// - Rotieren: alle Positionen neu berechnen
// - mit ScrollView außerhalb des Widgets umgehen können
// - FadeIn oder Out wäre nice
// - Flackern vom letzten neuen Item wegkriegen
void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _startCounter = 100;
  final lockedIndices = <int>[];

  int keyCounter = _startCounter;
  List<int> children = List.generate(_startCounter, (index) => index);
  ReorderableType reorderableType = ReorderableType.gridView;

  @override
  Widget build(BuildContext context) {
    /*return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            _getReorderableWidget(),
          ],
        ),
      ),
    );*/
    return Scaffold(
      backgroundColor: Colors.grey,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      ContainerButton(
                        onTap: () {
                          if (children.isNotEmpty) {
                            children[0] = 999;
                            setState(() {
                              children = children;
                            });
                          }
                        },
                        color: Colors.deepOrangeAccent,
                        icon: Icons.find_replace,
                      ),
                      ContainerButton(
                        onTap: () {
                          setState(() {
                            // children = children..add(keyCounter++);
                            children.insert(0, keyCounter++);
                          });
                        },
                        color: Colors.green,
                        icon: Icons.add,
                      ),
                      ContainerButton(
                        onTap: () {
                          if (children.isNotEmpty) {
                            setState(() {
                              // children = children..removeLast();
                              children.removeAt(1);
                            });
                          }
                        },
                        color: Colors.red,
                        icon: Icons.remove,
                      ),
                      ContainerButton(
                        onTap: () {
                          if (children.isNotEmpty) {
                            setState(() {
                              children = <int>[];
                            });
                          }
                        },
                        color: Colors.yellowAccent,
                        icon: Icons.delete,
                      ),
                    ],
                  ),
                ),
              ),
              DropdownButton<ReorderableType>(
                value: reorderableType,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 24,
                elevation: 16,
                itemHeight: 60,
                underline: Container(
                  height: 2,
                  color: Colors.white,
                ),
                onChanged: (ReorderableType? reorderableType) {
                  setState(() {
                    this.reorderableType = reorderableType!;
                  });
                },
                items: ReorderableType.values.map((e) {
                  return DropdownMenuItem<ReorderableType>(
                    value: e,
                    child: Text(e.toString()),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Expanded(child: _getReorderableWidget()),
            ],
          ),
        ),
      ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      final child = children.removeAt(oldIndex);
      children.insert(newIndex, child);
    });
  }

  Widget _getReorderableWidget() {
    final generatedChildren = List<Widget>.generate(
      children.length,
      (index) => Container(
        key: Key(children[index].toString()),
        decoration: BoxDecoration(
          color: lockedIndices.contains(index) ? Colors.black : Colors.blue,
        ),
        height: 100.0,
        width: 100.0,
        child: Center(
          child: Text(
            'test ${children[index]}',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    switch (reorderableType) {
      case ReorderableType.wrap:
        return ReorderableBuilder(
          children: generatedChildren,
          onReorder: _handleReorder,
          lockedIndices: lockedIndices,
          builder: (children, _) {
            return Wrap(
              key: const Key('wrap'),
              children: children,
            );
          },
        );

      case ReorderableType.gridView:
        return AnimatedReorderableBuilder(
          children: generatedChildren,
          onReorder: _handleReorder,
          lockedIndices: lockedIndices,
          builder: (children, contentGlobalKey, scrollController) {
            return GridView(
              key: contentGlobalKey,
              controller: scrollController,
              children: children,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 8,
              ),
            );
          },
        );

      case ReorderableType.gridViewCount:
        return ReorderableBuilder(
          children: generatedChildren,
          onReorder: _handleReorder,
          lockedIndices: lockedIndices,
          builder: (children, scrollController) {
            return GridView.count(
              controller: scrollController,
              key: const Key('count'),
              children: children,
              crossAxisCount: 3,
            );
          },
        );

      case ReorderableType.gridViewExtent:
        return ReorderableBuilder(
          children: generatedChildren,
          onReorder: _handleReorder,
          lockedIndices: lockedIndices,
          builder: (children, scrollController) {
            return GridView.extent(
              controller: scrollController,
              key: const Key('extent'),
              children: children,
              maxCrossAxisExtent: 200,
            );
          },
        );

      case ReorderableType.gridViewBuilder:
        return ReorderableBuilder(
          children: generatedChildren,
          onReorder: _handleReorder,
          lockedIndices: lockedIndices,
          builder: (children, scrollController) {
            return GridView.builder(
              key: const Key('builder'),
              controller: scrollController,
              itemBuilder: (context, index) {
                return children[index];
              },
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 8,
              ),
            );
          },
        );
    }
  }
}

class ContainerButton extends StatelessWidget {
  final GestureTapCallback onTap;
  final IconData icon;
  final Color color;

  const ContainerButton({
    required this.onTap,
    required this.icon,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: color,
        height: 50,
        width: 50,
        child: Center(
          child: Icon(
            icon,
            size: 20,
          ),
        ),
      ),
    );
  }
}
