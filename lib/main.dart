import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Graph Editor',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xff0766AD),
        scaffoldBackgroundColor: const Color(0xff121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xff29ADB2),
          secondary: Color(0xffF31559), // Changed for better contrast
          surface: Color(0xff363636),
          error: Color(0xffF31559),
        ),
      ),
      home: const GraphScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Data model for our node
class NodeData {
  final int id;
  final List<NodeData> children;

  NodeData({required this.id, List<NodeData>? children})
      : children = children ?? [];
}

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  // Source of truth for our single tree data
  late NodeData _rootNodeData;

  // State for the graphview package
  final Graph _graph = Graph();
  late BuchheimWalkerConfiguration _builder;

  // State for node selection and UI
  NodeData? _selectedNode;
  int _treeDepth = 1;

  // Controllers and Keys
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _graphViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _rootNodeData = NodeData(id: 1);
    _builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = (75)
      ..levelSeparation = (100)
      ..subtreeSeparation = (100)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

    _rebuildGraph();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerView());
  }

  /// Finds the smallest integer ID not used in the tree.
  int _findSmallestAvailableId() {
    final Set<int> usedIds = {};
    _collectIds(_rootNodeData, usedIds);

    int smallestId = 1;
    while (usedIds.contains(smallestId)) {
      smallestId++;
    }
    return smallestId;
  }

  void _collectIds(NodeData node, Set<int> ids) {
    ids.add(node.id);
    for (var child in node.children) {
      _collectIds(child, ids);
    }
  }

  void _addNode() {
    if (_selectedNode == null) {
      _showErrorSnackBar("No node selected!");
      return;
    }

    int parentDepth = _getNodeDepth(_selectedNode!);
    if (parentDepth >= 100) {
      _showErrorSnackBar("Cannot add node. Maximum depth of 100 reached.");
      return;
    }

    setState(() {
      final int newId = _findSmallestAvailableId();
      final newNode = NodeData(id: newId);
      _selectedNode!.children.add(newNode);
      _rebuildGraph();
    });
  }

  void _deleteNode(NodeData nodeToDelete) {
    setState(() {
      if (nodeToDelete == _rootNodeData) {
        _rootNodeData = NodeData(id: 1);
        _selectedNode = null;
        _showErrorSnackBar("Root node has been reset.");
        WidgetsBinding.instance.addPostFrameCallback((_) => _centerView());
      } else {
        _findAndRemoveNode(_rootNodeData, nodeToDelete);
        _selectedNode = null;
      }
      _rebuildGraph();
    });
  }

  void _rebuildGraph() {
    _graph.nodes.clear();
    _graph.edges.clear();
    _addNodeToGraph(_rootNodeData);
    _treeDepth = _calculateMaxDepth(_rootNodeData);
  }

  void _addNodeToGraph(NodeData nodeData, {NodeData? parent}) {
    final graphNode = Node.Id(nodeData.id);
    _graph.addNode(graphNode);

    if (parent != null) {
      final parentGraphNode = Node.Id(parent.id);
      _graph.addEdge(parentGraphNode, graphNode);
    }

    for (var child in nodeData.children) {
      _addNodeToGraph(child, parent: nodeData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tree Depth: $_treeDepth'),
        backgroundColor: const Color(0xff222222),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Reset View',
            onPressed: _centerView,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  final newMatrix = _transformationController.value.clone()
                    ..translate(-pointerSignal.scrollDelta.dx,
                        -pointerSignal.scrollDelta.dy);
                  _transformationController.value = newMatrix;
                }
              },
              child: InteractiveViewer(
                key: _graphViewKey,
                transformationController: _transformationController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(200),
                minScale: 0.01,
                maxScale: 5.6,
                child: GraphView(
                  graph: _graph,
                  algorithm: BuchheimWalkerAlgorithm(
                      _builder, TreeEdgeRenderer(_builder)),
                  paint: Paint()
                    ..color = Colors.grey.withOpacity(0.5)
                    ..strokeWidth = 1.5
                    ..style = PaintingStyle.stroke,
                  builder: (Node node) {
                    int nodeId = node.key!.value as int;
                    bool isSelected = _selectedNode?.id == nodeId;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedNode = _findNodeDataById(nodeId);
                        });
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.surface,
                              border: isSelected
                                  ? Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 3)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 8)
                              ],
                            ),
                            child: Text(
                              '$nodeId',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (nodeId != _rootNodeData.id)
                            Positioned(
                              top: -10,
                              right: -10,
                              child: InkWell(
                                onTap: () {
                                  final nodeDataToDelete =
                                      _findNodeDataById(nodeId);
                                  if (nodeDataToDelete != null) {
                                    _deleteNode(nodeDataToDelete);
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Child'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _addNode,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              if (_selectedNode != null) {
                _deleteNode(_selectedNode!);
              } else {
                _showErrorSnackBar("No node selected to delete.");
              }
            },
          ),
        ],
      ),
    );
  }

  // --- UTILITY FUNCTIONS ---

  void _centerView() {
    final RenderBox? box =
        _graphViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final screenWidth = box.size.width;
      final screenHeight = box.size.height;
      final centerMatrix = Matrix4.identity()
        ..translate(screenWidth / 2, screenHeight / 4); // Center a bit higher
      _transformationController.value = centerMatrix;
      setState(() {});
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  NodeData? _findNodeDataById(int id) {
    return _recursiveFindById(_rootNodeData, id);
  }

  NodeData? _recursiveFindById(NodeData currentNode, int id) {
    if (currentNode.id == id) {
      return currentNode;
    }
    for (var child in currentNode.children) {
      final found = _recursiveFindById(child, id);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  int _calculateMaxDepth(NodeData? node) {
    if (node == null) return 0;
    if (node.children.isEmpty) return 1;
    int maxChildDepth = 0;
    for (var child in node.children) {
      maxChildDepth = max(maxChildDepth, _calculateMaxDepth(child));
    }
    return maxChildDepth + 1;
  }

  bool _findAndRemoveNode(NodeData currentNode, NodeData targetNode) {
    if (currentNode.children.contains(targetNode)) {
      currentNode.children.remove(targetNode);
      return true;
    }
    for (var child in currentNode.children) {
      if (_findAndRemoveNode(child, targetNode)) {
        return true;
      }
    }
    return false;
  }

  int _getNodeDepth(NodeData targetNode,
      {NodeData? currentNode, int depth = 1}) {
    currentNode ??= _rootNodeData;
    if (currentNode == targetNode) {
      return depth;
    }
    for (var child in currentNode.children) {
      int foundDepth =
          _getNodeDepth(targetNode, currentNode: child, depth: depth + 1);
      if (foundDepth != -1) {
        return foundDepth;
      }
    }
    return -1;
  }
}