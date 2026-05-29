"""Git data collection and cache handling for the repository treemap."""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import time
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any, Callable


CACHE_SCHEMA_VERSION = 2
ALIAS_CONFIG_NAME = ".repo_treemap_aliases.json"
UNKNOWN_AUTHOR_ID = "unknown"
AUTHOR_PALETTE = [
    "#4E79A7",
    "#F28E2B",
    "#59A14F",
    "#E15759",
    "#76B7B2",
    "#EDC948",
    "#B07AA1",
    "#FF9DA7",
    "#9C755F",
    "#BAB0AC",
    "#2F6F73",
    "#8CD17D",
    "#B6992D",
    "#499894",
    "#D37295",
    "#79706E",
    "#86BCB6",
    "#FABFD2",
]


class GitCommandError(RuntimeError):
    """Raised when a Git command needed by the analyzer fails."""


def _normalize_key(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip().lower())


def _slug(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.strip().lower()).strip("-")
    return slug or UNKNOWN_AUTHOR_ID


def _author_color(author_id: str) -> str:
    """Return a deterministic, readable color for a normalized author id."""
    digest = hashlib.sha1(author_id.encode("utf-8")).hexdigest()
    return AUTHOR_PALETTE[int(digest[:8], 16) % len(AUTHOR_PALETTE)]


@dataclass(frozen=True)
class Author:
    author_id: str
    display_name: str
    color: str


class AliasResolver:
    """Normalize Git author names/emails and merge configured aliases."""

    def __init__(self, repo_root: Path):
        self.repo_root = repo_root
        self.config_path = repo_root / ALIAS_CONFIG_NAME
        self.email_map: dict[str, Author] = {}
        self.name_map: dict[str, Author] = {}
        self.canonical_map: dict[str, Author] = {}
        self.fingerprint = self._fingerprint()
        self._load_config()

    def _fingerprint(self) -> dict[str, Any]:
        if not self.config_path.exists():
            return {"exists": False}
        data = self.config_path.read_bytes()
        stat = self.config_path.stat()
        return {
            "exists": True,
            "mtime_ns": stat.st_mtime_ns,
            "size": stat.st_size,
            "sha256": hashlib.sha256(data).hexdigest(),
        }

    def _load_config(self) -> None:
        if not self.config_path.exists():
            return
        try:
            config = json.loads(self.config_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise ValueError(f"Invalid {ALIAS_CONFIG_NAME}: {exc}") from exc

        aliases = config.get("aliases", {})
        if not isinstance(aliases, dict):
            raise ValueError(f"{ALIAS_CONFIG_NAME} must contain an object named 'aliases'")

        seen_emails: dict[str, str] = {}
        seen_names: dict[str, str] = {}
        for canonical_id, entry in aliases.items():
            if not isinstance(entry, dict):
                raise ValueError(f"Alias entry {canonical_id!r} must be an object")
            author_id = _slug(canonical_id)
            display_name = entry.get("display_name") or canonical_id
            author = Author(author_id, display_name, _author_color(author_id))
            self.canonical_map[author_id] = author

            for email in entry.get("emails", []):
                key = self._email_key(email)
                if not key:
                    continue
                if key in seen_emails and seen_emails[key] != author_id:
                    raise ValueError(
                        f"Alias collision: email {email!r} appears under "
                        f"{seen_emails[key]!r} and {author_id!r}"
                    )
                seen_emails[key] = author_id
                self.email_map[key] = author

            for name in entry.get("names", []):
                key = _normalize_key(name)
                if not key:
                    continue
                if key in seen_names and seen_names[key] != author_id:
                    raise ValueError(
                        f"Alias collision: name {name!r} appears under "
                        f"{seen_names[key]!r} and {author_id!r}"
                    )
                seen_names[key] = author_id
                self.name_map[key] = author

    @staticmethod
    def _email_key(email: str) -> str:
        return email.strip().strip("<>").lower()

    def resolve(self, name: str | None, email: str | None) -> Author:
        name = (name or "").strip()
        email = (email or "").strip().strip("<>")
        email_key = self._email_key(email)
        if email_key and email_key in self.email_map:
            return self.email_map[email_key]

        name_key = _normalize_key(name)
        if name_key and name_key in self.name_map:
            return self.name_map[name_key]

        if email_key:
            author_id = email_key
            display_name = name or email_key
        elif name_key:
            author_id = f"name:{name_key}"
            display_name = name
        else:
            author_id = UNKNOWN_AUTHOR_ID
            display_name = "Unknown"
        return Author(author_id, display_name, _author_color(author_id))


class RepoTreemapAnalyzer:
    """Build and serve cached Git metrics for one repository."""

    def __init__(
        self,
        repo_path: str | os.PathLike[str],
        rebuild: bool = False,
        jobs: int | None = None,
        progress: Callable[[str], None] | None = None,
    ):
        self.input_path = Path(repo_path).expanduser().resolve()
        self.repo_root = Path(self._git(["rev-parse", "--show-toplevel"], cwd=self.input_path).strip())

        # Git documents --absolute-git-dir as the canonical absolute path to the
        # actual Git metadata directory. This handles .git pointer files,
        # submodules, and linked worktrees where repo/.git is not a directory.
        self.git_dir = Path(self._git(["rev-parse", "--absolute-git-dir"], cwd=self.repo_root).strip())
        self.cache_path = self.git_dir / ".repo_treemap_cache.json"
        self.head = self._read_head()
        self.aliases = AliasResolver(self.repo_root)
        self.jobs = max(1, jobs or min(8, os.cpu_count() or 1))
        self.progress = progress
        self.cache: dict[str, Any] = {}
        self.files: dict[str, dict[str, Any]] = {}
        self.tree: dict[str, Any] = {}
        self.cache_used = False
        self.load_or_build(rebuild=rebuild)

    def _progress(self, message: str) -> None:
        if self.progress is not None:
            self.progress(message)

    def _git(
        self,
        args: list[str],
        cwd: Path | None = None,
        *,
        check: bool = True,
        text: bool = True,
    ) -> str | bytes:
        cmd = ["git"]
        if cwd is not None:
            cmd.extend(["-C", str(cwd)])
        cmd.extend(args)
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            text=text,
        )
        if check and result.returncode != 0:
            stderr = result.stderr if text else result.stderr.decode("utf-8", "replace")
            raise GitCommandError(f"{' '.join(cmd)} failed: {stderr.strip()}")
        return result.stdout

    def _read_head(self) -> str:
        result = self._git(["rev-parse", "HEAD"], cwd=self.repo_root, check=False)
        head = str(result).strip()
        return head if head else "EMPTY"

    def load_or_build(self, rebuild: bool = False) -> None:
        if not rebuild:
            cached = self._load_valid_cache()
            if cached is not None:
                self._progress("Using existing treemap cache.")
                self.cache = cached
                self.files = cached.get("files", {})
                self.cache_used = True
                self.tree = self._build_tree()
                return

        self.cache = self._build_cache()
        self.files = self.cache["files"]
        self.tree = self._build_tree()
        self._write_cache()

    def _load_valid_cache(self) -> dict[str, Any] | None:
        if not self.cache_path.exists():
            return None
        try:
            data = json.loads(self.cache_path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            return None
        if data.get("schema_version") != CACHE_SCHEMA_VERSION:
            return None
        if data.get("repo_root") != str(self.repo_root):
            return None
        if data.get("head") != self.head:
            return None
        if data.get("alias_config_fingerprint") != self.aliases.fingerprint:
            return None
        return data

    def _write_cache(self) -> None:
        self.git_dir.mkdir(parents=True, exist_ok=True)
        tmp_path = self.cache_path.with_suffix(".json.tmp")
        tmp_path.write_text(json.dumps(self.cache, indent=2, sort_keys=True), encoding="utf-8")
        tmp_path.replace(self.cache_path)

    def _build_cache(self) -> dict[str, Any]:
        entries = self._list_head_entries()
        total_entries = len(entries)
        if total_entries:
            self._progress(
                "Building treemap cache for "
                f"{total_entries} versioned entries with {self.jobs} worker(s). "
                "Cold analysis runs git blame/history and can take a few minutes on large repos."
            )

        files = {}
        if self.jobs == 1 or total_entries <= 1:
            for index, entry in enumerate(entries, start=1):
                path, file_metrics = self._analyze_entry(entry)
                files[path] = file_metrics
                self._progress_for_entry(index, total_entries, path)
        else:
            with ThreadPoolExecutor(max_workers=self.jobs) as executor:
                future_to_entry = {
                    executor.submit(self._analyze_entry, entry): entry
                    for entry in entries
                }
                for index, future in enumerate(as_completed(future_to_entry), start=1):
                    path, file_metrics = future.result()
                    files[path] = file_metrics
                    self._progress_for_entry(index, total_entries, path)

        if total_entries:
            self._progress("Treemap cache build complete.")

        return {
            "schema_version": CACHE_SCHEMA_VERSION,
            "repo_root": str(self.repo_root),
            "repo_root_name": self.repo_root.name,
            "git_dir": str(self.git_dir),
            "head": self.head,
            "timestamp": int(time.time()),
            "alias_config_fingerprint": self.aliases.fingerprint,
            "files": files,
        }

    def _progress_for_entry(self, index: int, total: int, path: str) -> None:
        if total <= 0:
            return
        interval = max(25, total // 20)
        if index == 1 or index == total or index % interval == 0:
            self._progress(f"Analyzed {index}/{total}: {path}")

    def _analyze_entry(self, entry: dict[str, str]) -> tuple[str, dict[str, Any]]:
        path = entry["path"]
        if entry["type"] == "blob":
            return path, self._analyze_blob(path)
        return path, self._analyze_non_blob(path, entry["type"])

    def _list_head_entries(self) -> list[dict[str, str]]:
        if self.head == "EMPTY":
            return []
        output = self._git(
            ["ls-tree", "-r", "-z", "--full-tree", "HEAD"],
            cwd=self.repo_root,
            check=False,
        )
        if not output:
            return []

        entries = []
        for raw in str(output).split("\0"):
            if not raw:
                continue
            meta, path = raw.split("\t", 1)
            parts = meta.split()
            entries.append({"mode": parts[0], "type": parts[1], "object": parts[2], "path": path})
        return entries

    def _analyze_blob(self, path: str) -> dict[str, Any]:
        content = self._git(["show", f"HEAD:{path}"], cwd=self.repo_root, text=False)
        assert isinstance(content, bytes)
        is_binary = self._is_binary(content)
        history = self._file_history(path)

        if is_binary:
            # Binary files cannot produce blame line ownership. We keep them
            # visible by assigning one LOC; the size metric is therefore still
            # deterministic and small while contribution bands use commit count.
            loc = 1
            contribution_mode = "commit_count"
            contributors = self._contributors_from_counts(history["commit_counts"])
        else:
            text = content.decode("utf-8", "replace")
            loc = self._count_lines(text)
            blame_counts = self._blame_counts(path)
            if blame_counts:
                contribution_mode = "blame"
                contributors = self._contributors_from_counts(blame_counts)
            else:
                contribution_mode = "commit_count"
                contributors = self._contributors_from_counts(history["commit_counts"])

        size_metric = max(loc, 1)
        return self._file_node(
            path=path,
            loc=loc,
            size_metric=size_metric,
            is_binary=is_binary,
            contribution_mode=contribution_mode,
            contributors=contributors,
            history=history,
        )

    def _analyze_non_blob(self, path: str, git_type: str) -> dict[str, Any]:
        history = self._file_history(path)
        return self._file_node(
            path=path,
            loc=1,
            size_metric=1,
            is_binary=True,
            contribution_mode="commit_count",
            contributors=self._contributors_from_counts(history["commit_counts"]),
            history=history,
            extra={"git_object_type": git_type},
        )

    @staticmethod
    def _is_binary(content: bytes) -> bool:
        sample = content[:8192]
        if b"\0" in sample:
            return True
        try:
            sample.decode("utf-8")
        except UnicodeDecodeError:
            return True
        return False

    @staticmethod
    def _count_lines(text: str) -> int:
        if text == "":
            return 0
        return len(text.splitlines())

    def _blame_counts(self, path: str) -> dict[str, dict[str, Any]]:
        output = self._git(
            ["blame", "--line-porcelain", "HEAD", "--", path],
            cwd=self.repo_root,
            check=False,
        )
        if not output:
            return {}

        counts: dict[str, dict[str, Any]] = {}
        current_name = ""
        current_email = ""
        for line in str(output).splitlines():
            if line.startswith("author "):
                current_name = line[len("author ") :]
            elif line.startswith("author-mail "):
                current_email = line[len("author-mail ") :].strip("<>")
            elif line.startswith("\t"):
                author = self.aliases.resolve(current_name, current_email)
                bucket = counts.setdefault(
                    author.author_id,
                    {"author": author, "count": 0},
                )
                bucket["count"] += 1
        return counts

    def _file_history(self, path: str) -> dict[str, Any]:
        output = self._git(
            [
                "log",
                "--follow",
                "--no-merges",
                "--date=iso-strict",
                "--format=%x1e%H%x1f%aN%x1f%aE%x1f%ad",
                "--numstat",
                "--",
                path,
            ],
            cwd=self.repo_root,
            check=False,
        )
        commit_counts: dict[str, dict[str, Any]] = {}
        changed_lines_by_author: dict[str, int] = defaultdict(int)
        total_changed_lines = 0
        total_commits = 0
        last_modified_date = None

        for raw_record in str(output).split("\x1e"):
            record = raw_record.strip("\n")
            if not record:
                continue
            lines = record.splitlines()
            meta = lines[0].split("\x1f")
            if len(meta) < 4:
                continue
            _commit, name, email, date = meta[:4]
            author = self.aliases.resolve(name, email)
            if last_modified_date is None:
                last_modified_date = date[:10]
            total_commits += 1
            commit_bucket = commit_counts.setdefault(
                author.author_id,
                {"author": author, "count": 0},
            )
            commit_bucket["count"] += 1

            changed = 0
            for stat_line in lines[1:]:
                parts = stat_line.split("\t")
                if len(parts) < 3 or parts[0] == "-" or parts[1] == "-":
                    continue
                try:
                    changed += int(parts[0]) + int(parts[1])
                except ValueError:
                    continue
            total_changed_lines += changed
            changed_lines_by_author[author.author_id] += changed

        return {
            "total_commits": total_commits,
            "commit_counts": commit_counts,
            "total_changed_lines": total_changed_lines,
            "changed_lines_by_author": dict(changed_lines_by_author),
            "last_modified_date": last_modified_date,
        }

    def _contributors_from_counts(self, counts: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
        total = sum(int(item["count"]) for item in counts.values())
        if total <= 0:
            return []
        contributors = []
        for author_id, item in counts.items():
            author = item["author"]
            raw_value = int(item["count"])
            contributors.append(
                {
                    "author_id": author_id,
                    "display_name": author.display_name,
                    "color": author.color,
                    "raw_value": raw_value,
                    "percentage": (raw_value / total) * 100,
                }
            )
        contributors.sort(key=lambda item: (-item["raw_value"], item["display_name"].lower()))
        return contributors

    def _file_node(
        self,
        *,
        path: str,
        loc: int,
        size_metric: int,
        is_binary: bool,
        contribution_mode: str,
        contributors: list[dict[str, Any]],
        history: dict[str, Any],
        extra: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        node = {
            "type": "file",
            "path": path,
            "name": PurePosixPath(path).name,
            "loc": loc,
            "size_metric": size_metric,
            "last_modified_date": history["last_modified_date"],
            "total_commits_touching": history["total_commits"],
            "total_changed_lines": history["total_changed_lines"],
            "contribution_mode": contribution_mode,
            "contributors": contributors,
            "dominant_contributor": contributors[0] if contributors else None,
            "is_binary": is_binary,
        }
        if extra:
            node.update(extra)
        return node

    def _build_tree(self) -> dict[str, Any]:
        root = {
            "type": "dir",
            "path": "",
            "name": self.repo_root.name,
            "children": {},
            "files": {},
        }
        for path, file_node in self.files.items():
            parts = path.split("/")
            current = root
            current_path = ""
            for part in parts[:-1]:
                current_path = f"{current_path}/{part}" if current_path else part
                current = current["children"].setdefault(
                    part,
                    {
                        "type": "dir",
                        "path": current_path,
                        "name": part,
                        "children": {},
                        "files": {},
                    },
                )
            current["files"][parts[-1]] = file_node

        self._aggregate_dir(root)
        return root

    def _aggregate_dir(self, node: dict[str, Any]) -> None:
        aggregate_loc = 0
        aggregate_size_metric = 0
        aggregate_total_commits = 0
        aggregate_total_changed = 0
        weighted_contributors: dict[str, dict[str, Any]] = {}

        for child in node["children"].values():
            self._aggregate_dir(child)
            aggregate_loc += child["aggregate_loc"]
            aggregate_size_metric += child["size_metric"]
            aggregate_total_commits += child["aggregate_total_commits_touching"]
            aggregate_total_changed += child["aggregate_total_changed_lines"]
            self._rollup_contributors(weighted_contributors, child["contributors"], child["size_metric"])

        for file_node in node["files"].values():
            aggregate_loc += file_node["loc"]
            aggregate_size_metric += file_node["size_metric"]
            aggregate_total_commits += file_node["total_commits_touching"]
            aggregate_total_changed += file_node["total_changed_lines"]
            self._rollup_contributors(
                weighted_contributors,
                file_node["contributors"],
                file_node["size_metric"],
            )

        node["aggregate_loc"] = aggregate_loc
        node["loc"] = aggregate_loc
        node["size_metric"] = max(aggregate_size_metric, 1 if node["files"] else 0)
        node["aggregate_total_commits_touching"] = aggregate_total_commits
        node["total_commits_touching"] = aggregate_total_commits
        node["aggregate_total_changed_lines"] = aggregate_total_changed
        node["total_changed_lines"] = aggregate_total_changed
        node["contributors"] = self._contributors_from_weighted_rollup(weighted_contributors)
        node["dominant_contributor"] = node["contributors"][0] if node["contributors"] else None

    @staticmethod
    def _rollup_contributors(
        target: dict[str, dict[str, Any]],
        contributors: list[dict[str, Any]],
        size_metric: int | float,
    ) -> None:
        for contributor in contributors:
            weight = (float(size_metric) * float(contributor["percentage"])) / 100
            bucket = target.setdefault(
                contributor["author_id"],
                {
                    "author_id": contributor["author_id"],
                    "display_name": contributor["display_name"],
                    "color": contributor["color"],
                    "raw_value": 0.0,
                },
            )
            bucket["raw_value"] += weight

    @staticmethod
    def _contributors_from_weighted_rollup(
        weighted: dict[str, dict[str, Any]]
    ) -> list[dict[str, Any]]:
        total = sum(item["raw_value"] for item in weighted.values())
        if total <= 0:
            return []
        contributors = []
        for item in weighted.values():
            contributors.append(
                {
                    "author_id": item["author_id"],
                    "display_name": item["display_name"],
                    "color": item["color"],
                    "raw_value": round(item["raw_value"], 2),
                    "percentage": (item["raw_value"] / total) * 100,
                }
            )
        contributors.sort(key=lambda item: (-item["raw_value"], item["display_name"].lower()))
        return contributors

    def sanitize_path(self, requested_path: str | None) -> str:
        value = (requested_path or "").replace("\\", "/").strip("/")
        if "\0" in value:
            raise ValueError("Path contains a NUL byte")
        if value in ("", "."):
            return ""
        pure = PurePosixPath(value)
        if pure.is_absolute() or any(part in ("..", "") for part in pure.parts):
            raise ValueError(f"Invalid repository path: {requested_path!r}")
        return pure.as_posix()

    def find_node(self, requested_path: str | None) -> dict[str, Any]:
        path = self.sanitize_path(requested_path)
        if path == "":
            return self.tree
        if path in self.files:
            return self.files[path]
        current = self.tree
        for part in path.split("/"):
            if part not in current["children"]:
                raise KeyError(path)
            current = current["children"][part]
        return current

    def parent_dir(self, path: str) -> str:
        sanitized = self.sanitize_path(path)
        parent = PurePosixPath(sanitized).parent.as_posix()
        return "" if parent == "." else parent

    def breadcrumbs(self, path: str) -> list[dict[str, str]]:
        sanitized = self.sanitize_path(path)
        crumbs = [{"name": self.repo_root.name, "path": ""}]
        current = ""
        for part in sanitized.split("/"):
            if not part:
                continue
            current = f"{current}/{part}" if current else part
            crumbs.append({"name": part, "path": current})
        return crumbs

    def api_node(self, requested_path: str | None) -> dict[str, Any]:
        path = self.sanitize_path(requested_path)
        node = self.find_node(path)
        if node["type"] == "file":
            path = self.parent_dir(path)
            node = self.find_node(path)

        children = []
        for child in sorted(node["children"].values(), key=lambda item: item["name"].lower()):
            children.append(self._dir_api_node(child))
        for file_node in sorted(node["files"].values(), key=lambda item: item["name"].lower()):
            children.append(file_node)

        legend_rollup: dict[str, dict[str, Any]] = {}
        for child in children:
            self._rollup_contributors(
                legend_rollup,
                child.get("contributors", []),
                child.get("size_metric") or child.get("loc") or 1,
            )
        legend = self._contributors_from_weighted_rollup(legend_rollup)
        return {
            "repo_root_name": self.repo_root.name,
            "repo_root": str(self.repo_root),
            "current_path": path,
            "breadcrumbs": self.breadcrumbs(path),
            "cache": self.cache_metadata(),
            "children": children,
            "legend": legend,
        }

    @staticmethod
    def _dir_api_node(node: dict[str, Any]) -> dict[str, Any]:
        return {
            "type": "dir",
            "name": node["name"],
            "path": node["path"],
            "loc": node["aggregate_loc"],
            "size_metric": node["size_metric"],
            "aggregate_loc": node["aggregate_loc"],
            "total_commits_touching": node["aggregate_total_commits_touching"],
            "aggregate_total_commits_touching": node["aggregate_total_commits_touching"],
            "total_changed_lines": node["aggregate_total_changed_lines"],
            "aggregate_total_changed_lines": node["aggregate_total_changed_lines"],
            "contributors": node["contributors"],
            "dominant_contributor": node["dominant_contributor"],
        }

    def cache_metadata(self) -> dict[str, Any]:
        return {
            "schema_version": self.cache.get("schema_version"),
            "head": self.head,
            "timestamp": self.cache.get("timestamp"),
            "cache_path": str(self.cache_path),
            "cache_used": self.cache_used,
            "alias_config_fingerprint": self.aliases.fingerprint,
        }
