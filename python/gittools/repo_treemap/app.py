"""Flask routes for the repository treemap viewer."""

from __future__ import annotations

from pathlib import Path

from flask import Flask, jsonify, redirect, render_template, request, url_for

from .git_analysis import RepoTreemapAnalyzer


def create_app(analyzer: RepoTreemapAnalyzer) -> Flask:
    base_dir = Path(__file__).resolve().parent
    app = Flask(
        __name__,
        template_folder=str(base_dir / "templates"),
        static_folder=str(base_dir / "static"),
    )
    app.config["TREEMAP_ANALYZER"] = analyzer

    @app.get("/")
    def index():
        return redirect(url_for("view", path=""))

    @app.get("/view")
    def view():
        requested_path = request.args.get("path", "")
        try:
            path = analyzer.sanitize_path(requested_path)
            node = analyzer.find_node(path)
        except (ValueError, KeyError):
            return "Path not found in HEAD", 404
        if node["type"] == "file":
            return redirect(url_for("view", path=analyzer.parent_dir(path)))
        return render_template(
            "view.html",
            repo_root_name=analyzer.repo_root.name,
            current_path=path,
        )

    @app.get("/api/node")
    def api_node():
        requested_path = request.args.get("path", "")
        try:
            return jsonify(analyzer.api_node(requested_path))
        except (ValueError, KeyError):
            return jsonify({"error": "Path not found in HEAD"}), 404

    @app.get("/api/legend")
    def api_legend():
        requested_path = request.args.get("path", "")
        try:
            return jsonify({"legend": analyzer.api_node(requested_path)["legend"]})
        except (ValueError, KeyError):
            return jsonify({"error": "Path not found in HEAD"}), 404

    @app.get("/api/cache")
    def api_cache():
        return jsonify(analyzer.cache_metadata())

    return app
