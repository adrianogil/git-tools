import sys


def build_tree(paths):
    tree = {}
    for path in paths:
        parts = path.split("/")
        node = tree
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node.setdefault("__files__", []).append(parts[-1])
    return tree


def print_tree(node, prefix=""):
    dirs = sorted([key for key in node.keys() if key != "__files__"])
    files = sorted(node.get("__files__", []))
    entries = dirs + files

    for index, name in enumerate(entries):
        last = index == len(entries) - 1
        connector = "└── " if last else "├── "
        print(prefix + connector + name)

        if name in node:
            extension = "    " if last else "│   "
            print_tree(node[name], prefix + extension)


def main():
    paths = [line.strip() for line in sys.stdin if line.strip()]
    tree = build_tree(paths)
    print_tree(tree)


main()
