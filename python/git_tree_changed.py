import sys

def build_tree(entries):
    tree = {}
    for path, additions, deletions in entries:
        parts = path.split("/")
        node = tree
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node.setdefault("__files__", []).append((parts[-1], additions, deletions))
    return tree


def format_count(value):
    if value == "-":
        return "?"
    return value


def print_tree(node, prefix=""):
    dirs = sorted([key for key in node.keys() if key != "__files__"])
    files = sorted(node.get("__files__", []), key=lambda item: item[0])
    entries = [("dir", name) for name in dirs] + [("file", item) for item in files]

    for index, (entry_type, entry) in enumerate(entries):
        last = index == len(entries) - 1
        connector = "└── " if last else "├── "
        if entry_type == "dir":
            name = entry
            print(prefix + connector + name)
            extension = "    " if last else "│   "
            print_tree(node[name], prefix + extension)
        else:
            name, additions, deletions = entry
            additions_display = format_count(additions)
            deletions_display = format_count(deletions)
            print(f"{prefix}{connector}{name} (+{additions_display} -{deletions_display})")


def main():
    entries = []
    for line in sys.stdin:
        line = line.rstrip("\n")
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        additions, deletions, path = parts[0], parts[1], "\t".join(parts[2:])
        entries.append((path, additions, deletions))
    tree = build_tree(entries)
    print_tree(tree)


if __name__ == "__main__":
    main()
