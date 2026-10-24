import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TodoApp());
}

class Task {
  String title;
  String category;
  String priority;
  bool completed;

  Task({
    required this.title,
    this.category = 'Personal',
    this.priority = 'Medium',
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'priority': priority,
        'completed': completed,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        title: json['title'] ?? '',
        category: json['category'] ?? 'Personal',
        priority: json['priority'] ?? 'Medium',
        completed: json['completed'] ?? false,
      );
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: TodoHomePage(
        darkMode: darkMode,
        onThemeChanged: (value) {
          setState(() => darkMode = value);
        },
      ),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  const TodoHomePage({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<Task> tasks = [];
  final TextEditingController controller = TextEditingController();

  String selectedCategory = 'All';
  bool loading = true;

  final List<String> categories = [
    'Personal',
    'Study',
    'Work',
    'Health',
  ];

  final List<String> priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('tasks');

    if (saved != null) {
      try {
        final List decoded = jsonDecode(saved);
        tasks.addAll(decoded.map(
          (item) => Task.fromJson(Map<String, dynamic>.from(item)),
        ));
      } catch (_) {
        // Ignore invalid saved data.
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'tasks',
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
  }

  Future<void> showTaskDialog({Task? task}) async {
    final isEditing = task != null;
    controller.text = task?.title ?? '';
    String category = task?.category ?? 'Personal';
    String priority = task?.priority ?? 'Medium';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Task' : 'Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => category = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: priorities.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => priority = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isEmpty) return;

                setState(() {
                  if (isEditing) {
                    task.title = title;
                    task.category = category;
                    task.priority = priority;
                  } else {
                    tasks.add(Task(
                      title: title,
                      category: category,
                      priority: priority,
                    ));
                  }
                });

                await saveTasks();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(isEditing ? 'Save Changes' : 'Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> toggleTask(Task task, bool? value) async {
    setState(() => task.completed = value ?? false);
    await saveTasks();
  }

  Future<void> deleteTask(Task task) async {
    setState(() => tasks.remove(task));
    await saveTasks();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = selectedCategory == 'All'
        ? tasks
        : tasks.where((t) => t.category == selectedCategory).toList();

    final completedCount = tasks.where((t) => t.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TaskMate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => widget.onThemeChanged(!widget.darkMode),
            icon: Icon(
              widget.darkMode ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
          const SizedBox(width: 8),
          ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay focused. Get things done.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Total tasks',
                          '${tasks.length}',
                          Icons.checklist,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Completed',
                          '$completedCount',
                          Icons.task_alt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', ...categories].map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: selectedCategory == category,
                            onSelected: (_) {
                              setState(() => selectedCategory = category);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: visibleTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.task_alt, size: 56),
                                const SizedBox(height: 12),
                                Text(
                                  tasks.isEmpty
                                      ? 'No tasks yet. Add your first!'
                                      : 'No tasks in this category.',
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: visibleTasks.length,
                            itemBuilder: (context, index) {
                              final task = visibleTasks[index];

                              return Card(
                                child: ListTile(
                                  leading: Checkbox(
                                    value: task.completed,
                                    onChanged: (value) =>
                                        toggleTask(task, value),
                                  ),
                                  title: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.completed
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${task.category} • ${task.priority} priority',
                                  ),
                                  onTap: () => showTaskDialog(task: task),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (choice) {
                                      if (choice == 'edit') {
                                        showTaskDialog(task: task);
                                      } else if (choice == 'delete') {
                                        deleteTask(task);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String title, String count, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 8),
            Text(title),
            Text(
              count,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}