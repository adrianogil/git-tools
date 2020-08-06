from gittools.clitools import run_cmd


def get_hash_log(args=None):
    if args is None:
        args = []

    hashes = run_cmd('git log --pretty=format:"%h" ' + " ".join(args))
    hashes = hashes.split("\n")

    return hashes
