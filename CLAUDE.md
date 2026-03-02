## Project: Thermo Data Explorer
Flutter web app for querying thermodynamic and physical property data 
from the MKS Web Editions API (mkswebapi.com).

## Stack
- Framework: Flutter / Dart
- UI: Material Design 3
- HTTP: http package (Dart)
- Target: Web ONLY — do not add mobile or desktop platform code
- API: GET https://mkswebapi.com/process?request=<url-encoded-json>

## File Structure
- lib/main.dart — root, owns all state
- lib/models/compound.dart — compound model
- lib/models/result_value.dart — result data model
- lib/services/mks_api_service.dart — all API calls
- lib/widgets/compound_autocomplete.dart — search field
- lib/widgets/property_selector.dart — filter chips
- lib/widgets/results_table.dart — results display

## Rules
- Always plan before coding — explain what you'll change and why
- Make one focused change at a time
- Do NOT break existing caching, error handling, or form validation
- Do NOT add mobile/desktop/app-specific code
- Keep max content width at 800px
- Ask before restructuring any files
- After any correction, update Lessons Learned below

## Known Working Features (don't break these)
- Compound search with 2-char minimum and 300ms debounce
- Property selection with 5-property limit
- Temperature (K) and Pressure (kPa) inputs with validation
- Results table with loading/error/data states
- In-memory caching for search results and property list
- 30-second API timeout

## Lessons Learned
[Claude will add notes here after any mistakes]