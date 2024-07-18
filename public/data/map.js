$(document).ready(function () {
  // Initialize the map and set its view to the United States
  const map = L.map('map', {
    maxZoom: 10,
    minZoom: 2,
    zoomSnap: 0.5,
    zoomDelta: 1,
    maxBounds: [
      [80, -240],
      [-60, -30],
    ],
  }).setView([37.8, -130], 2.5)

  // Set up the OSM layer
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution:
      'Map data © <a href="https://openstreetmap.org">OpenStreetMap</a> contributors',
  }).addTo(map)

  const stateStyle = {
    fillColor: '#7c147c',
    weight: 1,
    color: '#ccc',
    dashArray: 3,
    fillOpacity: 0.5,
  }

  const stateStyleActive = {
    weight: 3,
    color: 'white',
    dashArray: 2,
    fillOpacity: 0.3,
  }

  function fetchJson(url) {
    return fetch(url).then(response => response.json())
  }

  function stationNameLink(org) {
    return `<a href="/participating-orgs/${org.id}" target="_blank" class="org-url" >${org.Name}</a><br>`
  }

  const geojson = fetchJson('/data/us-states.json')
  const orgs = fetchJson('/data/orgs.json')

  Promise.all([geojson, orgs]).then(([geojson, orgs]) => {
    // aggregate the orgs by state
    let orgsByState = {}
    Object.keys(orgs).forEach(org_id => {
      let org = orgs[org_id]
      org.id = org_id
      let state = org.State
      if (!orgsByState[state]) {
        orgsByState[state] = {}
      }
      orgsByState[state][org_id] = org
    })

    // Add the GeoJSON layer (States + Territories) to the map
    L.geoJson(geojson, {
      onEachFeature: (feature, layer) => {
        let region = feature.properties.name
        // let count = orgsByState[region]
        //   ? Object.keys(orgsByState[region]).length
        //   : null
        // let orgs = count ? Object.values(orgsByState[region]) : []

        layer.on({
          click: e => {
            window.open(`/participating-orgs#${region}`, '_blank').focus()
          },
          mouseover: e => {
            layer.setStyle(stateStyleActive)
            layer.bringToFront()
          },
          mouseout: e => {
            layer.setStyle(stateStyle)
          },
        })
        /* State popup */

        // .bindPopup(
        //   `<h4>${region}</h4>` +
        //     (orgs.length
        //       ? orgs.map(stationNameLink).join('')
        //       : 'No Participating Organizations in this region')
        // )
      },
      style: stateStyle,
    }).addTo(map)

    // Add the marker cluster layer
    const markers = L.markerClusterGroup({
      maxClusterRadius: 20,
      disableClusteringAtZoom: 10,
    }).on('clusterclick', a => {
      a.layer.zoomToBounds({ padding: [20, 20] })
    })
    map.addLayer(markers)

    // Add the markers to the map
    Object.keys(orgs).forEach(org_id => {
      let org = orgs[org_id]
      markers.addLayer(
        L.marker(org.location, {
          title: org.Name,
        }).bindPopup(
          `<a href="/participating-orgs/${org_id}" target="_blank" class="org-url"><h3>${org.Name}</h3></a>` +
            `${org.City}, ${org.State}<br>` +
            (org.Logo
              ? `<img src="https://s3.amazonaws.com/americanarchive.org/org-logos/${org.Logo}" class="map-logo"><br>`
              : '') +
            `<a href="/catalog?f%5Bcontributing_organizations%5D%5B%5D=${encodeURIComponent(
              org['Short name'] + ' (' + STATES[org.State] + ')'
            )}" target="_blank" class="btn btn-default btn-sm">View all records</a>`
        )
      )
    })
  })
})
