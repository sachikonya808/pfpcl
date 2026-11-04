import 'package:flutter/material.dart';
import 'package:pfpcl/settings/connection_settings.dart';

class SettingsPage extends StatefulWidget {
  final ConnectionSettings settings;
  final String title;

  const SettingsPage({super.key, required this.title, required this.settings});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final _hostController = TextEditingController(text: widget.settings.host);
  late final _portController = TextEditingController(text: widget.settings.port.toString());

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }
  
  void _save() {
    if(!_formKey.currentState!.validate()) return;
    widget.settings.host = _hostController.text.trim();
    widget.settings.port = int.parse(_portController.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _hostController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  border: OutlineInputBorder()
                ),
              ),
              
              const SizedBox(height: 16),

              TextFormField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder()
                ),
                validator: (value) {
                  final port = int.tryParse(value?.trim() ?? '');
                  if(port == null || port < 1024 || port > 65535) {
                    return 'Enter a port between 1024 and 65535';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8,),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Changes apply the next time you connect.',
                  style: TextStyle(fontSize: 12),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _save, child: const Text('Save')),
              )
            ],
          ),
        ),
      )
    );
  }  
}