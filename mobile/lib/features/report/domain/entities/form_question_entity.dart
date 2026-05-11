class FormOption {
  const FormOption({required this.id, required this.label});
  final String id;
  final String label;
}

class FormQuestion {
  const FormQuestion({
    required this.id,
    required this.text,
    required this.options,
  });
  final String id;
  final String text;
  final List<FormOption> options;
}

class DynamicFormSchema {
  const DynamicFormSchema({required this.questions});
  final List<FormQuestion> questions;
}
