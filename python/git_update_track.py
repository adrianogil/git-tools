import sys
import subprocess


def get_branches(line):
    branches = []
    print(line)

    for i in range(0, len(line)):
        if line[i:i + 7] == 'origin/':
            for j in range(i + 7, len(line)):
                if line[j] in '), ':
                    branches.append(line[i + 7:j])
                    break

    return branches


get_hashes_cmd = "git --no-pager log "
get_hashes_cmd += "--simplify-by-decoration "
get_hashes_cmd += "--tags --branches --remotes "
get_hashes_cmd += "--date-order "
get_hashes_cmd += "--decorate "
get_hashes_cmd += '--pretty=tformat:"%Cblue %h %C(auto)%d%Creset"'
get_hashes_output = subprocess.check_output(get_hashes_cmd, shell=True)
get_hashes_output = get_hashes_output.decode("utf8")
get_hashes_output = get_hashes_output.strip()

# print(get_hashes_output)

hashes_lines = get_hashes_output.split("\n")

for line in hashes_lines:
    hash_data = line.split("  ")
    # print(str(hash_data))
    if len(hash_data) >= 2 and 'origin/' in hash_data[1]:
        branches = get_branches(hash_data[1])
        print(str(branches))
        # print(hash_data[0] + " " + hash_data[1])
