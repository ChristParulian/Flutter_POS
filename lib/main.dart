import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'note.dart';

void main() {
  runApp(CrudApp());
}

class CrudApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test CRUD',
      home: NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _databaseHelper = DatabaseHelper();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() async {
    List<Note> notes = await _databaseHelper.getNotes();
    setState(() {
      _notes = notes;
    });
  }

  void _saveNote() async {
    String title = _titleController.text;
    String description = _descriptionController.text;

    if (title.isNotEmpty && description.isNotEmpty) {
      await _databaseHelper.insert(Note(
        title: title,
        description: description,
      ));
      _titleController.clear();
      _descriptionController.clear();
      _loadNotes();
    }
  }

  void _updateNote(Note note) async {
    note.title = _titleController.text;
    note.description = _descriptionController.text;

    await _databaseHelper.update(note);
    _titleController.clear();
    _descriptionController.clear();
    _loadNotes();
  }

  void _deleteNote(Note note) async {
    await _databaseHelper.delete(note.id!);
    _loadNotes();
  }

  void _showEditDialog(Note note) {
    _titleController.text = note.title;
    _descriptionController.text = note.description;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateNote(note);
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test CRUD'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                ElevatedButton(
                  onPressed: _saveNote,
                  child: Text('Add Note'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _showEditDialog(note);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteNote(note);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
