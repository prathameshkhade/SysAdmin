import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/env_variable.dart';

class EnvForm extends StatefulWidget {
  final EnvVariable? initialValue;
  final bool isGlobal;
  final Function(EnvVariable) onSubmit;

  const EnvForm({
    super.key,
    this.initialValue,
    required this.isGlobal,
    required this.onSubmit,
  });

  @override
  State<EnvForm> createState() => _EnvFormState();
}

class _EnvFormState extends State<EnvForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialValue?.name);
    _valueController = TextEditingController(text: widget.initialValue?.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        slivers: <Widget>[
          // Custom App Bar
          const SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              title: Text("Create Local Env"),
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
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final envVariable = EnvVariable(
                            name: _nameController.text,
                            value: _valueController.text,
                            isGlobal: widget.isGlobal,
                          );
                          widget.onSubmit(envVariable);
                        }
                      },
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
