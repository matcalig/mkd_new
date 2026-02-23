# Thermo Data Explorer

A Flutter Web application that lets you query thermodynamic and physical
property values from the
[MKS Web Editions API](https://molecularknowledge.com/Help/WebEditionsIntro/WebEditionsIntro.html).

---

## How the app works

1. **Select compounds** – Type at least 2 characters in the *Compound 1*
   field. The app queries the MKS API for matching chemicals and shows an
   autocomplete dropdown. An optional *Compound 2* field allows a second
   compound.

2. **Select properties** – The app automatically fetches the list of
   available thermodynamic / physical properties from the API when it starts.
   Choose up to **5 properties** by clicking the filter chips.

3. **Enter conditions** – Specify *Temperature* (Kelvin) and *Pressure* (kPa).
   Both fields validate that the input is a positive number.

4. **Calculate** – Click *Calculate* to send a "Get Values" request to the
   API for each selected compound. Results are displayed in a table with
   columns: **Compound**, **Property**, **Status**, **Value**, **Units**.

---

## How the API is used

All requests are HTTP GET to:

```
https://mkswebapi.com/process?request=<url-encoded-json>
```

| Request type    | Purpose                                    |
|-----------------|--------------------------------------------|
| `Hello`         | Connectivity check                         |
| `Get Entities`  | Compound autocomplete (pattern matching)   |
| `Get Properties`| Fetch available property names             |
| `Get Values`    | Retrieve property values at T & P          |

### Example "Get Entities" request

```json
{
  "Type": "Get Entities",
  "Arguments": {
    "EntityType": "Chemical",
    "NamePattern": "water"
  }
}
```

### Example "Get Values" request

```json
{
  "Type": "Get Values",
  "Arguments": {
    "EntityType": "Chemical",
    "Identifier": "Water",
    "Properties": ["Density"],
    "Temperature": {"Value": "293.15", "Units": "K"},
    "Pressure":    {"Value": "101.325", "Units": "kPa"}
  }
}
```

---

## How to run locally

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.18
- Google Chrome (or another supported browser)

### Steps

```bash
# Install dependencies
flutter pub get

# Run in Chrome
flutter run -d chrome
```

The app will open at `http://localhost:<port>` in Chrome.

### Run tests

```bash
flutter test
```

