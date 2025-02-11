import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/data/services/env_service.dart';
import '../../../data/models/env_variable.dart';

class EnvForm extends ConsumerStatefulWidget {
  final EnvVariable? initialValue;
  final bool isGlobal;
  final bool isEditing;

  const EnvForm({
    super.key,
    this.initialValue,
    required this.isGlobal,
    this.isEditing = false
  });

  @override
  ConsumerState<EnvForm> createState() => _EnvFormState();
}

class _EnvFormState extends ConsumerState<EnvForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialValue?.name);
    _valueController = TextEditingController(text: widget.initialValue?.value);
  }

  Future<void> _onSubmit() async {
    if(_formKey.currentState!.validate()) {
      try {
        final service = EnvService(ref: ref);
        if(widget.isEditing) {
          // Update the var
          await service.updateVariable(
            widget.initialValue!.name,
            widget.initialValue!
          );
        }
        else {
          // Create new var
          await service.createVariable(
            EnvVariable(
                name: _nameController.text.toString(),
                value: _valueController.text.toString(),
                isGlobal: widget.isGlobal
            )
          );
        }

        if(!mounted) return;
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Environmental variable created locally"),
            backgroundColor: Colors.green,
          )
        );
        // Pop and return true to trigger the refresh
        Navigator.pop(context, true);
      }
      catch(e) {
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create an environmental variable: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          )
        );

        // Pop and return false
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        slivers: <Widget>[
          // Custom App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              title: Text(
                  "${widget.isEditing ? 'Update' : 'Create'}"
                  " ${widget.isGlobal ? 'Global' : 'Local'}"
                  " Env"
              ),
            ),
          ),

          // Main Body
          SliverFillRemaining(
            hasScrollBody: true,
            fillOverscroll: true,
            child: SizedBox(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: <Widget>[
                    // Variable Input
                    TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.text,
                        maxLines: 1,
                        maxLength: 255,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Variable name is required';
                          } else if (!EnvVariable.isValidName(val)) {
                            return 'Invalid Variable Name';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(labelText: 'Variable Name', border: OutlineInputBorder())),

                    // Space
                    const SizedBox(height: 25),

                    // Variable Input
                    TextFormField(
                        controller: _valueController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 3,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Variable value is required';
                          } else if (!EnvVariable.isValidValue(val)) {
                            return 'Invalid Variable Value';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                            labelText: 'Variable Value',
                            border: OutlineInputBorder()
                        )
                    ),

                    // Space
                    const SizedBox(height: 30),

                    // Submit Button
                    CupertinoButton.filled(
                      onPressed: _onSubmit,
                      child: const Text("Save"),
                    ),

                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }
}
