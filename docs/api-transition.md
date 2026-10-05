# Reporting API transition

The migrated client uses `NF_API_URL` and `NF_API_KEY` to send sightings and read nearby reports through the public NuptialFlight REST API. It sends an anonymous per-install UUID; the app key is extractable from a client bundle and does not identify a user. The client no longer carries an ArangoDB password or falls back to direct database access when the API is unavailable.

Forecasts and on-device scoring use weather data and bundled models independently of the reporting API. If the API is unavailable, migrated clients cannot submit sightings or load nearby reports. The app should make those failures visible without claiming that a report was saved.

Older installed versions use direct database access. Their forecast calculations are independent of that connection, but reporting, nearby flights, map markers and background features may fail if it becomes unreachable. The exact failure behavior varies by version; a representative old build still needs validation before access is retired.

The compatibility policy is to retain the legacy connection for **21 days after the migrated app release**. The release date is not yet established, so this document does not state a calendar cutoff. Record the verified release timestamp and retire legacy access 21 days later, after checking the migrated client and the remaining authorized data consumers. There is no force-upgrade mechanism in existing versions.
