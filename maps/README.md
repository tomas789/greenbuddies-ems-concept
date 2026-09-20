# Portfolio geography

`central-europe.json` bundles Natural Earth **1:10 million** country polygons, all **14 Czech kraje**, and rivers including the European supplement. City coordinates in `ems.config.json → map.cities` are from the same populated-places dataset, with corrected Czech spelling; the existing central-Prague point is retained. Installation markers are separate application data.

- Source: [Natural Earth vector repository](https://github.com/nvkelso/natural-earth-vector/tree/ca96624a56bd078437bca8184e78163e5039ad19/geojson), revision `ca96624a56bd078437bca8184e78163e5039ad19`.
- Layers: `ne_10m_admin_0_countries`, `ne_10m_admin_1_states_provinces`, `ne_10m_rivers_lake_centerlines`, `ne_10m_rivers_europe`, `ne_10m_populated_places_simple`.
- License: [public domain, including commercial use](https://www.naturalearthdata.com/about/terms-of-use/).
- Preparation: selected six Central European countries and Czech regions; cropped river runs to the surrounding area; merged river and lake-centerline records by name; rounded coordinates to five decimal places. Boundary vertices are not simplified. Region label points are supplied by Natural Earth; river labels are placed on nearby river vertices.

## Update the bundled geography

Run `node scripts/map-data.mjs` from the project directory. It downloads the pinned sources and replaces only `public/maps/central-europe.json`. Optional local source cache: `node scripts/map-data.mjs /path/to/sources` (files named `admin_0_countries.json`, etc.). Normal builds and browser visits do not download external map data. City positions remain editable in the EMS configuration.

## File format

A JSON array of `{ name, kind?, label?, geometry }`. Omitted `kind` means `country`, preserving the original country-only format. Optional kinds are `region` and `river`. `geometry` uses GeoJSON `Polygon`, `MultiPolygon`, `LineString`, or `MultiLineString` with `[longitude, latitude]` coordinates in WGS84. Optional `label` is `{ lon, lat }`. Geographic names use the existing UI translation catalog.

The renderer caches SVG paths. Labels keep their screen size and avoid installation markers, controls, and one another. City labels have priority; region and river labels appear as space allows when zooming. There are no map SDKs, tile servers, or API keys.
