"""App Store Connect API helper for the Gallery TestFlight workflow.

  asc.py prepare   — register the Gallery bundle id, require the App Store Connect app record,
                     revoke stale CI development certificates (team-wide limit).
  asc.py whats-new — wait until the uploaded build shows up, set its "What to Test".

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (path to the .p8), BUNDLE_ID;
whats-new also VERSION, BUILD, WHATS_NEW, WAIT_MINUTES.
"""
import datetime, json, os, sys, time, urllib.error, urllib.parse, urllib.request

import jwt

API = "https://api.appstoreconnect.apple.com/v1"
BUNDLE_ID = os.environ["BUNDLE_ID"]


def token():
    now = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
        open(os.environ["ASC_KEY_PATH"]).read(),
        algorithm="ES256",
        headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"},
    )


def call(method, path, body=None, fatal=True):
    request = urllib.request.Request(
        API + path,
        method=method,
        data=json.dumps(body).encode() if body else None,
        headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request) as response:
            raw = response.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        message = f"App Store Connect API {method} {path}: HTTP {error.code} " + error.read().decode(errors="replace")[:500]
        if not fatal:
            print("::warning::" + message)
            return None
        print("::error::" + message)
        if error.code in (401, 403):
            print("::error::The API key needs the Admin role (docs/testflight.md, step 2).")
        sys.exit(1)


def query(path, **params):
    return call("GET", path + "?" + urllib.parse.urlencode(params))


def app_id():
    apps = query("/apps", **{"filter[bundleId]": BUNDLE_ID}).get("data", [])
    return apps[0]["id"] if apps else None


def prepare():
    found = query("/bundleIds", **{"filter[identifier]": BUNDLE_ID, "limit": 200}).get("data", [])
    if any(item["attributes"]["identifier"] == BUNDLE_ID for item in found):
        print(f"{BUNDLE_ID}: already registered")
    else:
        call("POST", "/bundleIds", {"data": {"type": "bundleIds", "attributes": {
            "identifier": BUNDLE_ID, "name": "DesignKit Gallery", "platform": "IOS"}}})
        print(f"{BUNDLE_ID}: registered")

    # The API cannot create the app record itself — it is a one-time step in App Store Connect.
    if app_id() is None:
        print(f"::error::No App Store Connect app with bundle id {BUNDLE_ID}. Create it once: "
              "App Store Connect → Apps → + → New App (docs/testflight.md, step 1).")
        sys.exit(1)
    print(f"{BUNDLE_ID}: App Store Connect app found")

    # Every cloud archive creates an "Apple Development: Created via API" certificate whose private
    # key dies with the runner; the team has a limit. Revoke the ones older than two hours — a
    # younger one may belong to a build running right now (this repo's or Dalada's).
    now = datetime.datetime.now(datetime.timezone.utc)
    certificates = query("/certificates", limit=200).get("data", [])
    for certificate in certificates:
        attributes = certificate["attributes"]
        if attributes.get("certificateType") not in ("DEVELOPMENT", "IOS_DEVELOPMENT"):
            continue
        if "Created via API" not in (attributes.get("name") or ""):
            continue
        expires = attributes.get("expirationDate")
        if not expires:
            continue
        created = datetime.datetime.fromisoformat(expires.replace("Z", "+00:00")) - datetime.timedelta(days=365)
        if now - created < datetime.timedelta(hours=2):
            continue
        if call("DELETE", "/certificates/" + certificate["id"], fatal=False) is not None:
            print(f"Revoked CI certificate {attributes.get('name')} (expires {expires[:10]})")


def whats_new():
    version, build = os.environ["VERSION"], os.environ["BUILD"]
    text = os.environ.get("WHATS_NEW", "").strip()[:3900] or f"DesignKit {version}"
    deadline = time.time() + 60 * int(os.environ.get("WAIT_MINUTES", "45"))
    app = app_id()
    build_id = None
    while build_id is None:
        builds = query("/builds", **{"filter[app]": app, "filter[version]": build,
                                     "filter[preReleaseVersion.version]": version}).get("data", [])
        if builds:
            build_id = builds[0]["id"]
            break
        if time.time() > deadline:
            print(f"::warning::Build {version} ({build}) did not appear in App Store Connect in time; "
                  "What to Test not set.")
            return
        time.sleep(60)
    print(f"Build {version} ({build}) found: {build_id}")

    existing = query(f"/builds/{build_id}/betaBuildLocalizations").get("data", [])
    if existing:
        for localization in existing:
            call("PATCH", "/betaBuildLocalizations/" + localization["id"], {"data": {
                "type": "betaBuildLocalizations", "id": localization["id"],
                "attributes": {"whatsNew": text}}})
            print(f"What to Test updated ({localization['attributes'].get('locale')})")
        return
    locales = [item["attributes"]["locale"] for item in
               query(f"/apps/{app}/betaAppLocalizations").get("data", [])] or ["en-US"]
    for locale in locales:
        call("POST", "/betaBuildLocalizations", {"data": {
            "type": "betaBuildLocalizations",
            "attributes": {"locale": locale, "whatsNew": text},
            "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}}, fatal=False)
        print(f"What to Test set ({locale})")


{"prepare": prepare, "whats-new": whats_new}[sys.argv[1]]()
