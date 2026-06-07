import 'package:flutter/material.dart';

abstract class BaseFormController {
  GlobalKey<FormState> formKey;

  BaseFormController() : formKey = GlobalKey<FormState>();

  bool validate();

  void init();

  void clear();

  Widget buildForm(BuildContext context) {
    return Container();
  }
}
