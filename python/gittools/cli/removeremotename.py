

def remove_remote_name(complete_branch_name):
    if '/' in complete_branch_name:
        branch_index = complete_branch_name.index('/')
        complete_branch_name = complete_branch_name[branch_index + 1:]
    return complete_branch_name


def get_remote_name(complete_branch_name):
    if '/' in complete_branch_name:
        branch_index = complete_branch_name.index('/')
        remote_name = complete_branch_name[:branch_index]
    return remote_name


if __name__ == '__main__':
    import sys

    complete_branch_name = sys.argv[1]

    if '--get-only-remote' in sys.argv:
        remote_name = get_remote_name(complete_branch_name)
        print(remote_name)
    else:
        complete_branch_name = remove_remote_name(complete_branch_name)
        print(complete_branch_name)
