from pathlib import Path

shell = Path('lib/features/kitchen_shell.dart')
text = shell.read_text()
for line in [
    '  static const sageDeep = Color(0xFF173A2F);\n',
    '  static const canvas = Color(0xFFF4F1E8);\n',
    '  static const gold = Color(0xFFD3A443);\n',
]:
    text = text.replace(line, '')
shell.write_text(text)

test = Path('test/ios_premium_scaling_contract_test.dart')
text = test.read_text()
text = text.replace('          home: const Scaffold(', '          home: Scaffold(')
test.write_text(text)
