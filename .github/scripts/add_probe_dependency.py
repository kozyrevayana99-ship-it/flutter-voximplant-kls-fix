from pathlib import Path

path = Path('.ci_probe/pubspec.yaml')
source = path.read_text()
needle = '\ndependencies:\n'
assert source.count(needle) == 1
path.write_text(source.replace(needle,
    '\ndependencies:\n  flutter_voximplant:\n    path: ../\n', 1))
