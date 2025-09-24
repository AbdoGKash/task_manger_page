import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class Task {
  final String id;
  String title;
  bool completed;

  Task({required this.id, required this.title, this.completed = false});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TaskManager(),
    );
  }
}

class TaskManager extends StatefulWidget {
  const TaskManager({super.key});

  @override
  State<TaskManager> createState() => _TaskManagerState();
}

class _TaskManagerState extends State<TaskManager> {
  List<Task> tasks = [
    Task(id: 't1', title: 'Buy groceries'),
    Task(id: 't2', title: 'Walk the dog'),
    Task(id: 't3', title: 'Complete Flutter project'),
  ];

  Task? _recentlyDeletedTask;
  int? _recentlyDeletedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Manager')),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = tasks.removeAt(oldIndex);
            tasks.insert(newIndex, item);
          });
        },
        // important: each child must have a key (Dismissible has it)
        children: List.generate(tasks.length, (index) {
          final task = tasks[index];

          return Dismissible(
            key: ValueKey(task.id),

            // swipe from right to left to delete
            direction: DismissDirection.endToStart,

            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.check, color: Colors.white),
            ),

            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),

            confirmDismiss: (direction) async {
              // only confirm on delete swipe (endToStart)
              if (direction == DismissDirection.endToStart) {
                return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: Text(
                          'Are you sure you want to delete "${task.title}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
              }
              return false;
            },

            onDismissed: (direction) {
              // capture values before setState changes the list
              final deletedTask = task;
              final deletedIndex = index;

              setState(() {
                _recentlyDeletedTask = deletedTask;
                _recentlyDeletedIndex = deletedIndex;
                tasks.removeAt(deletedIndex);
              });

              // clear previous snackbars to avoid stacking
              ScaffoldMessenger.of(context).clearSnackBars();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Task "${deletedTask.title}" deleted'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      setState(() {
                        if (_recentlyDeletedTask != null &&
                            _recentlyDeletedIndex != null) {
                          tasks.insert(
                            _recentlyDeletedIndex!,
                            _recentlyDeletedTask!,
                          );
                        }
                        _recentlyDeletedTask = null;
                        _recentlyDeletedIndex = null;
                      });
                    },
                  ),
                ),
              );
            },

            child: ListTile(
              // give the ListTile a secondary key (not strictly required)
              key: ValueKey('tile-${task.id}'),

              // drag handle — wrap the icon so user can drag from it
              leading: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),

              title: Text(
                task.title,
                style: task.completed
                    ? const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      )
                    : null,
              ),

              // checkbox that toggles completed and draws a line-through on the text
              trailing: Checkbox(
                value: task.completed,
                onChanged: (value) {
                  setState(() {
                    task.completed = value ?? false;
                  });
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}
