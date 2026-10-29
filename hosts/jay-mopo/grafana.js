import Gtk4LayerShell from "gi://Gtk4LayerShell?version=1.0";
import Gdk from "gi://Gdk?version=4.0";
import GLib from "gi://GLib?version=2.0";
import Gtk from "gi://Gtk?version=4.0";
import WebKit from "gi://WebKit?version=6.0";

const url = "https://grafana.mopo.co/d/TBBfZyJ7z/server-overview?orgId=1&from=now-24h&to=now&timezone=browser&var-datasource=1iHaz7Jnk&refresh=30s&kiosk";
const profilePath = GLib.build_filenamev([GLib.get_user_data_dir(), "grafana-wallpaper"]);
const cachePath = GLib.build_filenamev([GLib.get_user_cache_dir(), "grafana-wallpaper"]);
GLib.mkdir_with_parents(profilePath, 0o700);
GLib.mkdir_with_parents(cachePath, 0o700);
const networkSession = WebKit.NetworkSession.new(profilePath, cachePath);
networkSession.get_cookie_manager().set_persistent_storage(
  GLib.build_filenamev([profilePath, "cookies.sqlite"]),
  WebKit.CookiePersistentStorage.SQLITE,
);
const stylesheet = `
  html,
  body,
  #reactRoot,
  #reactRoot > *,
  #reactRoot > * > *,
  [class*="dashboard-scene"],
  [data-testid="dashboard-grid"],
  .grafana-app,
  .app,
  .page,
  .page-body,
  .page-scrollbar,
  .dashboard-container,
  .react-grid-layout,
  main,
  [role="main"] {
    background: transparent !important;
  }

  .react-grid-item {
    background: transparent !important;
  }

  .panel-container,
  [data-testid="panel-container"],
  .react-grid-item > * {
    background: rgba(20, 25, 32, 0.55) !important;
  }

`;
const contentManager = new WebKit.UserContentManager();
contentManager.add_style_sheet(new WebKit.UserStyleSheet(
  stylesheet,
  WebKit.UserContentInjectedFrames.ALL_FRAMES,
  WebKit.UserStyleLevel.USER,
  null,
  null,
));

const injectStylesheet = (view) => {
  const script = `
    (() => {
      const apply = () => {
        document.getElementById("grafana-wallpaper-style")?.remove();
        const style = document.createElement("style");
        style.id = "grafana-wallpaper-style";
        style.textContent = ${JSON.stringify(stylesheet)};
        document.head.appendChild(style);

        for (const root of document.querySelectorAll(
          ".react-grid-layout, [data-testid='dashboard-grid'], [class*='dashboard-scene']",
        )) {
          for (let node = root; node && node !== document.documentElement; node = node.parentElement) {
            node.style.setProperty("background-color", "transparent", "important");
            node.style.setProperty("background-image", "none", "important");
          }
        }

        const controls = document.querySelector('[data-testid="dashboard controls"]');
        if (controls?.parentElement) {
          controls.parentElement.style.setProperty("background", "transparent", "important");
          controls.parentElement.style.setProperty("background-color", "transparent", "important");
          controls.parentElement.style.setProperty("background-image", "none", "important");
        }

      };

      apply();
      [250, 1000, 3000].forEach((delay) => window.setTimeout(apply, delay));
    })();
  `;

  view.evaluate_javascript(script, -1, null, null, null, (webView, result) => {
    try {
      webView.evaluate_javascript_finish(result);
    } catch (error) {
      logError(error, "Could not apply Grafana wallpaper stylesheet");
    }
  });
};

const interactive = GLib.file_test(
  `${GLib.getenv("XDG_RUNTIME_DIR")}/grafana-wallpaper-interactive`,
  GLib.FileTest.EXISTS,
);
const dashboardToolbarHeight = 72;
const application = new Gtk.Application({ application_id: "co.mopo.grafana-wallpaper" });
const windows = [];

application.connect("activate", () => {
  if (windows.length > 0) {
    return;
  }

  const display = Gdk.Display.get_default();
  const transparentWidgets = new Gtk.CssProvider();
  transparentWidgets.load_from_string(`
    window,
    window.background,
    webkit-web-view {
      background-color: transparent;
      background-image: none;
    }
  `);
  Gtk.StyleContext.add_provider_for_display(
    display,
    transparentWidgets,
    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
  );

  const monitors = display.get_monitors();

  for (let index = 0; index < monitors.get_n_items(); index++) {
    const monitor = monitors.get_item(index);
    const geometry = monitor.get_geometry();
    const topClearance = 64;
    const bottomClearance = 24;
    const availableWidth = geometry.width - 48;
    const availableHeight = geometry.height - topClearance - bottomClearance;
    const width = Math.min(availableWidth, Math.floor(availableHeight * 16 / 9));
    const height = Math.floor(width * 9 / 16);
    const leftMargin = Math.floor((geometry.width - width) / 2);
    const topMargin = topClearance + Math.floor((availableHeight - height) / 2);
    const window = new Gtk.ApplicationWindow({ application, decorated: false });
    window.set_default_size(width, height);
    window.set_resizable(false);
    window.set_opacity(interactive ? 1.0 : 0.60);
    Gtk4LayerShell.init_for_window(window);
    Gtk4LayerShell.set_namespace(window, "grafana-wallpaper");
    Gtk4LayerShell.set_layer(window, Gtk4LayerShell.Layer.BACKGROUND);
    Gtk4LayerShell.set_monitor(window, monitor);
    Gtk4LayerShell.set_anchor(window, Gtk4LayerShell.Edge.TOP, true);
    Gtk4LayerShell.set_anchor(window, Gtk4LayerShell.Edge.LEFT, true);
    Gtk4LayerShell.set_margin(window, Gtk4LayerShell.Edge.TOP, topMargin);
    Gtk4LayerShell.set_margin(window, Gtk4LayerShell.Edge.LEFT, leftMargin);
    Gtk4LayerShell.set_exclusive_zone(window, -1);
    Gtk4LayerShell.set_keyboard_mode(
      window,
      interactive ? Gtk4LayerShell.KeyboardMode.ON_DEMAND : Gtk4LayerShell.KeyboardMode.NONE,
    );
    const view = new WebKit.WebView({
      network_session: networkSession,
      user_content_manager: contentManager,
    });
    view.set_background_color(new Gdk.RGBA({ red: 0, green: 0, blue: 0, alpha: 0 }));
    view.set_can_target(interactive);
    const viewport = new Gtk.Fixed();
    const toolbarOffset = interactive ? 0 : dashboardToolbarHeight;
    view.set_size_request(width, height + toolbarOffset);
    viewport.put(view, 0, -toolbarOffset);
    view.connect("load-changed", (_view, event) => {
      if (event === WebKit.LoadEvent.FINISHED) {
        injectStylesheet(view);
      }
    });
    view.load_uri(url);
    window.set_child(viewport);
    window.present();
    windows.push(window);
  }
});

application.run([]);
