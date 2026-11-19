// poteto — preferences for a clean, minimal Firefox (paired with userChrome.css)
//
// Firefox re-applies this file on every start, so these win over the settings UI.
// Delete a line (and restart) to hand that setting back to about:preferences.

// load chrome/userChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// websites follow Firefox, and Firefox follows the system's light/dark mode, live
// (0 = always dark, 1 = always light, 2 = follow)
user_pref("layout.css.prefers-color-scheme.content-override", 2);

// AccentColor (focus rings, selections, and userChrome.css) from the GTK theme, which carries
// the shell's accent color, instead of Firefox's own blue
user_pref("widget.non-native-theme.use-theme-accent", true);

// compact density
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);

// bookmarks bar only on the new tab page
user_pref("browser.toolbars.bookmarks.visibility", "newtab");

// no Pocket. (The Firefox View button has no pref any more; userChrome.css hides it.)
user_pref("extensions.pocket.enabled", false);

// new tab page: keep search and your wallpaper, drop the sponsored noise
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.showWeather", false);
