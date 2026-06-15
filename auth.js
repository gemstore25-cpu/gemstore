const API_BASE = "/api";

/**
 * Show a message inside an alert box.
 * @param {HTMLElement} el
 * @param {string} msg
 * @param {"error"|"success"} type
 */
function showMessage(el, msg, type = "error") {
  if (!el) return;
  el.textContent = msg;
  el.className = `alert alert-${type}`;
  el.style.display = "block";
}

/**
 * Make a JSON request to the backend API, sending cookies along
 * so the auth session (JWT cookie) is included automatically.
 */
async function apiRequest(path, options = {}) {
  const res = await fetch(`${API_BASE}${path}`, {
    credentials: "include",
    headers: { "Content-Type": "application/json" },
    ...options,
  });

  let data = {};
  try {
    data = await res.json();
  } catch (_) {
    // no JSON body
  }

  if (!res.ok) {
    throw new Error(data.error || "Something went wrong. Please try again.");
  }

  return data;
}

/**
 * Populate the navbar based on whether the user is currently logged in.
 */
async function updateNav() {
  const navAuth = document.getElementById("nav-auth");
  if (!navAuth) return;

  try {
    const { user } = await apiRequest("/auth/me");
    navAuth.innerHTML = `
      <span class="nav-user">Hi, ${escapeHtml(user.username)}</span>
      <a href="dashboard.html">Dashboard</a>
      <a href="#" id="logout-link">Logout</a>
    `;

    document.getElementById("logout-link").addEventListener("click", async (e) => {
      e.preventDefault();
      try {
        await apiRequest("/auth/logout", { method: "POST" });
      } finally {
        window.location.href = "index.html";
      }
    });
  } catch (_) {
    navAuth.innerHTML = `
      <a href="login.html">Login</a>
      <a href="register.html" class="btn-nav">Register</a>
    `;
  }
}

function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str;
  return div.innerHTML;
}

document.addEventListener("DOMContentLoaded", updateNav);
