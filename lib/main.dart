import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyOsApp());

// ---------------------------------------------------------------------------
// Models. Data is plain JSON, so it works identically on web, Android,
// iOS, Windows, macOS and Linux. No server, no account.
// ---------------------------------------------------------------------------

class OsSystem {
  OsSystem({
    required this.id,
    required this.name,
    required this.icon,
    required this.desc,
    required this.group,
  });

  final String id;
  String name;
  String icon;
  String desc;
  String group;

  factory OsSystem.fromJson(Map<String, dynamic> j) => OsSystem(
        id: j['id'] as String,
        name: j['name'] as String,
        icon: j['icon'] as String? ?? '💫',
        desc: j['desc'] as String? ?? '',
        group: j['group'] as String? ?? 'custom',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'icon': icon, 'desc': desc, 'group': group};
}

class OsItem {
  OsItem({
    required this.id,
    required this.osId,
    required this.title,
    required this.status,
    required this.tag,
    required this.date,
    required this.link,
    required this.notes,
    required this.created,
  });

  final String id;
  final String osId;
  String title;
  String status;
  String tag;
  String date;
  String link;
  String notes;
  final int created;

  factory OsItem.fromJson(Map<String, dynamic> j) => OsItem(
        id: j['id'] as String,
        osId: j['osId'] as String,
        title: j['title'] as String,
        status: j['status'] as String? ?? 'To do',
        tag: j['tag'] as String? ?? '',
        date: j['date'] as String? ?? '',
        link: j['link'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        created: j['created'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'osId': osId,
        'title': title,
        'status': status,
        'tag': tag,
        'date': date,
        'link': link,
        'notes': notes,
        'created': created,
      };
}

String uid() =>
    '${DateTime.now().millisecondsSinceEpoch}${(DateTime.now().microsecond % 1000)}';

String groupTitle(String g) {
  switch (g) {
    case 'core':
      return 'Core';
    case 'life':
      return 'Life';
    case 'social':
      return 'Social Media OS';
    case 'books':
      return 'Book Note OS';
    default:
      return 'Your added systems';
  }
}

List<OsSystem> seedSystems() {
  OsSystem s(String id, String name, String icon, String desc, String group) =>
      OsSystem(id: id, name: name, icon: icon, desc: desc, group: group);
  return [
    s('project', 'Project', '💪', 'Your projects, in one place', 'core'),
    s('tasks', 'Tasks', '📝', 'Tasks linked to your projects', 'core'),
    s('todo', 'To-do list', '🔥', 'Daily to-dos', 'core'),
    s('knowledge', 'Knowledge Bank', '📆', 'Notes and knowledge you want to keep', 'core'),
    s('course', 'Course & Series Tracker', '🌍', 'Courses and series you follow', 'core'),
    s('relationship', 'My Relationship', '🌍', 'People and relationships', 'core'),
    s('health', 'My health information', '🩺', 'Health notes and records', 'life'),
    s('annual', 'আমার বার্ষিক পর্যালোচনা', '📅', 'Annual review', 'life'),
    s('finance', 'Finances Tracker', '💰', 'Money in and out', 'life'),
    s('plans', 'My Plans', '🗺️', 'Plans for life, study and work', 'life'),
    s('resource', 'Resource Collection', '📦', 'Useful resources, collected', 'life'),
    s('loan', 'সুদ মুক্ত ঋণ', '🤝', 'Interest-free loans', 'life'),
    s('mass', 'Mass OS', '🗂️', 'Your Mass system', 'life'),
    s('playstore', 'Play Store Purchases', '📱', 'Apps and games you bought', 'life'),
    s('games', 'Games OS', '🎮', 'Games you play and track', 'social'),
    s('podcast', 'Podcast OS', '🎙️', 'Podcasts you follow', 'social'),
    s('youtube', 'YouTube OS', '▶️', 'Channels and videos', 'social'),
    s('facebook', 'Facebook OS', '👍', 'Facebook pages and groups', 'social'),
    s('instagram', 'Instagram OS', '📸', 'Instagram accounts and ideas', 'social'),
    s('nonfiction', 'Non-fictional', '📖', 'Non-fiction book notes', 'books'),
    s('fiction', 'Fictional', '📚', 'Fiction book notes', 'books'),
  ];
}

// ---------------------------------------------------------------------------
// App state
// ---------------------------------------------------------------------------

class MyOsApp extends StatefulWidget {
  const MyOsApp({super.key});

  @override
  State<MyOsApp> createState() => _MyOsAppState();
}

class _MyOsAppState extends State<MyOsApp> {
  List<OsSystem> systems = [];
  List<OsItem> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('myos-v1');
    if (raw == null) {
      systems = seedSystems();
      items = [];
    } else {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        systems = (data['systems'] as List)
            .map((e) => OsSystem.fromJson(e as Map<String, dynamic>))
            .toList();
        items = (data['items'] as List)
            .map((e) => OsItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        systems = seedSystems();
        items = [];
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'myos-v1',
      jsonEncode({
        'version': 1,
        'systems': systems.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
      }),
    );
  }

  void _refresh() {
    setState(() {});
    _save();
  }

  void _openSystem(BuildContext context, OsSystem system) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SystemScreen(
          system: system,
          allItems: items,
          onToggle: (item) {
            item.status = item.status == 'Done' ? 'To do' : 'Done';
            _refresh();
          },
          onSaveItem: (item) {
            final i = items.indexWhere((e) => e.id == item.id);
            if (i >= 0) {
              items[i] = item;
            } else {
              items.add(item);
            }
            _refresh();
          },
          onDeleteItem: (item) {
            items.removeWhere((e) => e.id == item.id);
            _refresh();
          },
          onSaveSystem: (updated) {
            final i = systems.indexWhere((e) => e.id == updated.id);
            if (i >= 0) systems[i] = updated;
            _refresh();
          },
          onDeleteSystem: (deleted) {
            systems.removeWhere((e) => e.id == deleted.id);
            items.removeWhere((e) => e.osId == deleted.id);
            _refresh();
          },
        ),
      ),
    );
  }

  void _addSystem() async {
    final created = await showSystemDialog(context, null);
    if (created != null) {
      systems.add(created);
      _refresh();
    }
  }

  void _showBackup() async {
    await showBackupDialog(
      context,
      exportJson: jsonEncode({
        'version': 1,
        'systems': systems.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
      }),
      onRestore: (data) {
        try {
          systems = (data['systems'] as List)
              .map((e) => OsSystem.fromJson(e as Map<String, dynamic>))
              .toList();
          items = (data['items'] as List)
              .map((e) => OsItem.fromJson(e as Map<String, dynamic>))
              .toList();
          _refresh();
          return true;
        } catch (_) {
          return false;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Our OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
      home: loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : HomeScreen(
              systems: systems,
              items: items,
              onOpenSystem: (s) => _openSystem(context, s),
              onAddSystem: _addSystem,
              onBackup: _showBackup,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.systems,
    required this.items,
    required this.onOpenSystem,
    required this.onAddSystem,
    required this.onBackup,
  });

  final List<OsSystem> systems;
  final List<OsItem> items;
  final void Function(OsSystem) onOpenSystem;
  final VoidCallback onAddSystem;
  final VoidCallback onBackup;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String query = '';

  int countFor(String osId) =>
      widget.items.where((i) => i.osId == osId).length;

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final filtered = q.isEmpty
        ? widget.systems
        : widget.systems
            .where((s) => ('${s.name} ${s.desc}').toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('💫 Our OS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup_outlined),
            tooltip: 'Backup',
            onPressed: widget.onBackup,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddSystem,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _stat('Systems', '${widget.systems.length}')),
              const SizedBox(width: 10),
              Expanded(child: _stat('Items', '${widget.items.length}')),
              const SizedBox(width: 10),
              Expanded(
                child: _stat(
                  'Done',
                  '${widget.items.where((i) => i.status == 'Done').length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search your systems…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.onAddSystem,
            icon: const Icon(Icons.add),
            label: const Text('Add a new OS'),
          ),
          const SizedBox(height: 8),
          if (q.isNotEmpty) ...[
            _section('Search results', filtered),
          ] else ...[
            _section(
              'Core',
              filtered.where((s) => s.group == 'core').toList(),
            ),
            _section(
              'Life',
              filtered.where((s) => s.group == 'life').toList(),
            ),
            _section(
              '📺 Social Media OS',
              filtered.where((s) => s.group == 'social').toList(),
            ),
            _section(
              '📘 Book Note OS',
              filtered.where((s) => s.group == 'books').toList(),
            ),
            _section(
              'Your added systems',
              filtered.where((s) => s.group == 'custom').toList(),
              emptyText:
                  'No custom system yet. Tap “Add a new OS” to create one — for example: Study OS, Prayer OS, or Business OS.',
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Our OS — personal, open-source, GPL-3.0.\n'
            'Data stays on this device. Use Backup to export / import it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<OsSystem> list, {String? emptyText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (list.isEmpty && emptyText != null)
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(emptyText)))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.15,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final s = list[i];
              final n = countFor(s.id);
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => widget.onOpenSystem(s),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.icon, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 6),
                        Text(
                          s.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (s.desc.isNotEmpty)
                          Text(
                            s.desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        const Spacer(),
                        Text(
                          '$n item${n == 1 ? '' : 's'}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// One system
// ---------------------------------------------------------------------------

class SystemScreen extends StatefulWidget {
  const SystemScreen({
    super.key,
    required this.system,
    required this.allItems,
    required this.onToggle,
    required this.onSaveItem,
    required this.onDeleteItem,
    required this.onSaveSystem,
    required this.onDeleteSystem,
  });

  final OsSystem system;
  final List<OsItem> allItems;
  final void Function(OsItem) onToggle;
  final void Function(OsItem) onSaveItem;
  final void Function(OsItem) onDeleteItem;
  final void Function(OsSystem) onSaveSystem;
  final void Function(OsSystem) onDeleteSystem;

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  String query = '';
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final s = widget.system;
    final q = query.toLowerCase();
    final list = widget.allItems
        .where((i) => i.osId == s.id)
        .where((i) => filter == 'All' || i.status == filter)
        .where(
          (i) =>
              q.isEmpty ||
              ('${i.title} ${i.notes} ${i.tag}').toLowerCase().contains(q),
        )
        .toList()
      ..sort((a, b) => b.created.compareTo(a.created));

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.icon} ${s.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit system',
            onPressed: () async {
              final updated = await showSystemDialog(context, s);
              if (updated != null) {
                widget.onSaveSystem(updated);
                if (mounted) setState(() {});
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete system',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete this system?'),
                  content: const Text(
                    'This deletes the system and ALL its items. Export a backup first if you need it.',
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
              );
              if (ok == true && mounted) {
                widget.onDeleteSystem(s);
                navigator.pop();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final item = await showItemDialog(context, s.id, null);
          if (item != null) widget.onSaveItem(item);
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (s.desc.isNotEmpty)
            Text(s.desc, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search inside this system…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['All', 'To do', 'Doing', 'Done'].map((f) {
              return ChoiceChip(
                label: Text(f),
                selected: filter == f,
                onSelected: (_) => setState(() => filter = f),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final item = await showItemDialog(context, s.id, null);
              if (item != null) widget.onSaveItem(item);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No items here yet.\nTap “Add item” to start this system.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...list.map((item) {
              return Card(
                child: ListTile(
                  leading: Checkbox(
                    value: item.status == 'Done',
                    onChanged: (_) => widget.onToggle(item),
                  ),
                  title: Text(
                    item.title,
                    style: item.status == 'Done'
                        ? const TextStyle(decoration: TextDecoration.lineThrough)
                        : null,
                  ),
                  subtitle: Text(
                    [
                      item.status,
                      if (item.tag.isNotEmpty) item.tag,
                      if (item.date.isNotEmpty) item.date,
                      if (item.notes.isNotEmpty) '\n${item.notes}',
                    ].join(' • '),
                  ),
                  isThreeLine: item.notes.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        final updated =
                            await showItemDialog(context, s.id, item);
                        if (updated != null) widget.onSaveItem(updated);
                      } else if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete this item?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) widget.onDeleteItem(item);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

Future<OsSystem?> showSystemDialog(BuildContext context, OsSystem? existing) {
  final name = TextEditingController(text: existing?.name ?? '');
  final icon = TextEditingController(text: existing?.icon ?? '');
  final desc = TextEditingController(text: existing?.desc ?? '');
  String group = existing?.group ?? 'custom';

  return showDialog<OsSystem>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add a new OS' : 'Edit system'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    autofocus: true,
                  ),
                  TextField(
                    controller: icon,
                    decoration:
                        const InputDecoration(labelText: 'Icon (emoji)'),
                  ),
                  TextField(
                    controller: desc,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                  ),
                  DropdownButton<String>(
                    value: group,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'custom', child: Text('Your added systems')),
                      DropdownMenuItem(value: 'core', child: Text('Core')),
                      DropdownMenuItem(value: 'life', child: Text('Life')),
                      DropdownMenuItem(value: 'social', child: Text('Social Media OS')),
                      DropdownMenuItem(value: 'books', child: Text('Book Note OS')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => group = v ?? 'custom'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (name.text.trim().isEmpty) return;
                  if (existing != null) {
                    existing.name = name.text.trim();
                    existing.icon =
                        icon.text.trim().isEmpty ? '💫' : icon.text.trim();
                    existing.desc = desc.text.trim();
                    existing.group = group;
                    Navigator.of(context).pop(existing);
                  } else {
                    Navigator.of(context).pop(
                      OsSystem(
                        id: uid(),
                        name: name.text.trim(),
                        icon: icon.text.trim().isEmpty
                            ? '💫'
                            : icon.text.trim(),
                        desc: desc.text.trim(),
                        group: group,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<OsItem?> showItemDialog(
  BuildContext context,
  String osId,
  OsItem? existing,
) {
  final title = TextEditingController(text: existing?.title ?? '');
  final tag = TextEditingController(text: existing?.tag ?? '');
  final date = TextEditingController(text: existing?.date ?? '');
  final link = TextEditingController(text: existing?.link ?? '');
  final notes = TextEditingController(text: existing?.notes ?? '');
  String status = existing?.status ?? 'To do';

  return showDialog<OsItem>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add item' : 'Edit item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title *'),
                    autofocus: true,
                  ),
                  DropdownButton<String>(
                    value: status,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'To do', child: Text('To do')),
                      DropdownMenuItem(value: 'Doing', child: Text('Doing')),
                      DropdownMenuItem(value: 'Done', child: Text('Done')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => status = v ?? 'To do'),
                  ),
                  TextField(
                    controller: tag,
                    decoration:
                        const InputDecoration(labelText: 'Tag / category'),
                  ),
                  TextField(
                    controller: date,
                    decoration: const InputDecoration(
                      labelText: 'Date (tap calendar to pick)',
                    ),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        date.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                  TextField(
                    controller: link,
                    decoration: const InputDecoration(labelText: 'Link'),
                  ),
                  TextField(
                    controller: notes,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (title.text.trim().isEmpty) return;
                  Navigator.of(context).pop(
                    OsItem(
                      id: existing?.id ?? uid(),
                      osId: osId,
                      title: title.text.trim(),
                      status: status,
                      tag: tag.text.trim(),
                      date: date.text.trim(),
                      link: link.text.trim(),
                      notes: notes.text.trim(),
                      created: existing?.created ??
                          DateTime.now().millisecondsSinceEpoch,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showBackupDialog(
  BuildContext context, {
  required String exportJson,
  required bool Function(Map<String, dynamic>) onRestore,
}) {
  final importText = TextEditingController();
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('💾 Backup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export: copy this JSON and keep it somewhere safe. '
                'Import: paste a backup JSON below and tap Restore.',
              ),
              const SizedBox(height: 12),
              SelectableText(exportJson),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: exportJson));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup copied.')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy backup'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: importText,
                decoration: const InputDecoration(
                  labelText: 'Paste backup JSON here',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              try {
                final data =
                    jsonDecode(importText.text) as Map<String, dynamic>;
                if (onRestore(data)) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup restored.')),
                  );
                } else {
                  throw const FormatException('bad backup');
                }
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('That is not a valid Our OS backup.'),
                  ),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      );
    },
  );
}
