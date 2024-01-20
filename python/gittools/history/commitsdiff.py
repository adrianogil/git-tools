from gittools.history.log import get_hash_log


def get_commits_diff(ref1, ref2):
	print(f"Diff between {ref1} and {ref2}")

	# Get the list of commit hashes for ref1 and ref2
	hashes_ref1 = get_hash_log([ref1])
	hashes_ref2 = get_hash_log([ref2])

	diff_hash1 = []
	# Find the commits in ref1 that are not in ref2
	for hash1 in hashes_ref1:
		if hash1 not in hashes_ref2:
			diff_hash1.append(hash1)

	print("Missing commits from " + str(ref1) + " (%s commits)" % (len(diff_hash1)))
	for hash1 in diff_hash1:
		print(hash1)

	diff_hash2 = []
	# Find the commits in ref2 that are not in ref1
	for hash2 in hashes_ref2:
		if hash2 not in hashes_ref1:
			diff_hash2.append(hash2)
	print("Missing commits from " + str(ref1) + " (%s commits)" % (len(diff_hash2)))
	for hash2 in diff_hash2:
		print(hash2)


if __name__ == '__main__':
	import sys
	ref1 = sys.argv[1]
	ref2 = sys.argv[2]

	get_commits_diff(ref1, ref2)
