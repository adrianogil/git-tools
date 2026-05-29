(function () {
  const currentPath = document.body.dataset.currentPath || "";
  const treemapEl = document.getElementById("treemap");
  const emptyEl = document.getElementById("empty-state");
  const tooltipEl = document.getElementById("tooltip");
  const breadcrumbsEl = document.getElementById("breadcrumbs");
  const legendEl = document.getElementById("legend");
  const cacheMetaEl = document.getElementById("cache-meta");

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function fmtNumber(value) {
    return new Intl.NumberFormat().format(value || 0);
  }

  function fmtPct(value) {
    return `${Number(value || 0).toFixed(2)}%`;
  }

  function nodeValue(node) {
    return Math.max(Number(node.size_metric || node.loc || node.aggregate_loc || 0), 1);
  }

  function navigateTo(path) {
    window.location.href = `/view?path=${encodeURIComponent(path || "")}`;
  }

  function renderBreadcrumbs(data) {
    breadcrumbsEl.innerHTML = "";
    data.breadcrumbs.forEach((crumb, index) => {
      if (index > 0) {
        const sep = document.createElement("span");
        sep.className = "breadcrumb-sep";
        sep.textContent = "/";
        breadcrumbsEl.appendChild(sep);
      }
      const link = document.createElement("a");
      link.href = `/view?path=${encodeURIComponent(crumb.path)}`;
      link.textContent = crumb.name;
      breadcrumbsEl.appendChild(link);
    });
  }

  function renderLegend(data) {
    legendEl.innerHTML = "";
    if (!data.legend.length) {
      legendEl.hidden = true;
      return;
    }
    legendEl.hidden = false;
    data.legend.forEach((contributor) => {
      const item = document.createElement("div");
      item.className = "legend-item";
      item.innerHTML = `
        <span class="legend-swatch" style="background:${contributor.color}"></span>
        <span class="legend-name">${escapeHtml(contributor.display_name)}</span>
        <span class="legend-percent">${fmtPct(contributor.percentage)}</span>
      `;
      legendEl.appendChild(item);
    });
  }

  function renderCacheMeta(data) {
    const cache = data.cache || {};
    const cacheState = cache.cache_used ? "cache reused" : "cache rebuilt";
    cacheMetaEl.textContent = `${cacheState} · ${String(cache.head || "").slice(0, 12)}`;
  }

  function tooltipHtml(node) {
    const contributors = (node.contributors || [])
      .map((c) => {
        return `
          <div class="tooltip-contributor">
            <span class="tooltip-swatch" style="background:${c.color}"></span>
            <span>${escapeHtml(c.display_name)}</span>
            <strong>${fmtPct(c.percentage)}</strong>
            <span class="muted">${fmtNumber(c.raw_value)}</span>
          </div>
        `;
      })
      .join("");

    if (node.type === "dir") {
      return `
        <div class="tooltip-title">${escapeHtml(node.path || node.name)}</div>
        <div>Directory</div>
        <div>LOC: <strong>${fmtNumber(node.loc)}</strong></div>
        <div>Total commits touching descendants: <strong>${fmtNumber(node.total_commits_touching)}</strong></div>
        <div>Total changed lines: <strong>${fmtNumber(node.total_changed_lines)}</strong></div>
        <div class="tooltip-section">${contributors || "<span class='muted'>No contributor data</span>"}</div>
      `;
    }

    return `
      <div class="tooltip-title">${escapeHtml(node.path)}</div>
      <div>LOC: <strong>${fmtNumber(node.loc)}</strong></div>
      <div>Last modified: <strong>${escapeHtml(node.last_modified_date || "Unknown")}</strong></div>
      <div>Total commits touching file: <strong>${fmtNumber(node.total_commits_touching)}</strong></div>
      <div>Total changed lines: <strong>${fmtNumber(node.total_changed_lines)}</strong></div>
      <div>Contribution source: <strong>${escapeHtml(node.contribution_mode || "unknown")}</strong></div>
      <div>Binary/non-blameable: <strong>${node.is_binary ? "yes" : "no"}</strong></div>
      <div class="tooltip-section">${contributors || "<span class='muted'>No contributor data</span>"}</div>
    `;
  }

  function showTooltip(event, node) {
    tooltipEl.innerHTML = tooltipHtml(node);
    tooltipEl.hidden = false;
    moveTooltip(event);
  }

  function moveTooltip(event) {
    const pad = 16;
    const rect = tooltipEl.getBoundingClientRect();
    let left = event.clientX + pad;
    let top = event.clientY + pad;
    if (left + rect.width > window.innerWidth) {
      left = event.clientX - rect.width - pad;
    }
    if (top + rect.height > window.innerHeight) {
      top = event.clientY - rect.height - pad;
    }
    tooltipEl.style.left = `${Math.max(8, left)}px`;
    tooltipEl.style.top = `${Math.max(8, top)}px`;
  }

  function hideTooltip() {
    tooltipEl.hidden = true;
  }

  function renderTreemap(data) {
    treemapEl.innerHTML = "";
    emptyEl.hidden = data.children.length > 0;
    if (!data.children.length) {
      return;
    }

    const width = treemapEl.clientWidth;
    const height = treemapEl.clientHeight;
    const root = d3
      .hierarchy({ name: data.current_path || data.repo_root_name, children: data.children })
      .sum((d) => (d.children ? 0 : nodeValue(d)))
      .sort((a, b) => b.value - a.value);

    d3.treemap().size([width, height]).paddingInner(2).round(true)(root);

    const nodes = d3
      .select(treemapEl)
      .selectAll(".tile")
      .data(root.leaves())
      .join("div")
      .attr("class", (d) => `tile tile-${d.data.type}`)
      .style("left", (d) => `${d.x0}px`)
      .style("top", (d) => `${d.y0}px`)
      .style("width", (d) => `${Math.max(0, d.x1 - d.x0)}px`)
      .style("height", (d) => `${Math.max(0, d.y1 - d.y0)}px`)
      .style("background", (d) => (d.data.type === "dir" ? "#f4f6f8" : "#ffffff"))
      .on("mouseenter", (event, d) => showTooltip(event, d.data))
      .on("mousemove", moveTooltip)
      .on("mouseleave", hideTooltip)
      .on("click", (event, d) => {
        if (d.data.type === "dir") {
          navigateTo(d.data.path);
        }
      });

    nodes.each(function (d) {
      const node = d.data;
      const tile = d3.select(this);
      const w = Math.max(0, d.x1 - d.x0);
      const h = Math.max(0, d.y1 - d.y0);

      if (node.type === "file") {
        const svg = tile.append("svg").attr("class", "bands").attr("width", w).attr("height", h);
        let y = 0;
        (node.contributors || []).forEach((contributor, index, list) => {
          const bandHeight =
            index === list.length - 1 ? h - y : Math.max(1, (h * contributor.percentage) / 100);
          svg
            .append("rect")
            .attr("x", 0)
            .attr("y", y)
            .attr("width", w)
            .attr("height", Math.max(0, bandHeight))
            .attr("fill", contributor.color);
          y += bandHeight;
        });
      }

      tile.append("div").attr("class", "tile-label").text(node.name);
      tile
        .append("div")
        .attr("class", "tile-meta")
        .text(node.type === "dir" ? `${fmtNumber(node.loc)} LOC` : `${fmtNumber(node.loc)} LOC`);
    });
  }

  function load() {
    fetch(`/api/node?path=${encodeURIComponent(currentPath)}`)
      .then((response) => {
        if (!response.ok) throw new Error(`Request failed: ${response.status}`);
        return response.json();
      })
      .then((data) => {
        renderBreadcrumbs(data);
        renderLegend(data);
        renderCacheMeta(data);
        renderTreemap(data);
      })
      .catch((error) => {
        treemapEl.innerHTML = `<div class="error">${escapeHtml(error.message)}</div>`;
      });
  }

  window.addEventListener("resize", d3.debounce ? d3.debounce(load, 150) : load);
  load();
})();
