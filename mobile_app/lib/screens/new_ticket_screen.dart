import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/enums.dart';
import '../services/firebase_service.dart';

class NewTicketScreen extends StatefulWidget {
  @override
  _NewTicketScreenState createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  TicketCategory _category = TicketCategory.general;
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _attachments = [];
  bool _isLoading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        String? path = result.files.single.path;
        if (path != null) {
           String url = await FirebaseService().uploadFile(path, result.files.single.name);
           setState(() => _attachments.add(url));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseService().createTicket(
          _category,
          _subjectController.text,
          _descriptionController.text,
          _attachments,
        );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Raise Issue')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<TicketCategory>(
                value: _category,
                decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: TicketCategory.values.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c.value));
                }).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Enter subject' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 5,
                validator: (val) => val!.isEmpty ? 'Enter description' : null,
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickFile,
                icon: Icon(Icons.attach_file),
                label: Text('Attach File'),
              ),
              if (_attachments.isNotEmpty) ...[
                SizedBox(height: 8),
                Text('${_attachments.length} files attached'),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? CircularProgressIndicator() : Text('Submit Ticket'),
                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
