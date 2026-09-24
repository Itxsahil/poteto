// poteto — preferences for a clean, minimal Firefox (paired with userChrome.css)
//
// Firefox re-applies this file on every start, so these win over the settings UI.
// Delete a line (and restart) to hand that setting back to about:preferences.

// load chrome/userChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// dark chrome and dark web content, whatever the GTK theme says
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 0);

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
