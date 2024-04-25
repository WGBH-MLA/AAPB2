# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w( background-video.js player.js transcript.js mobile-transcript.js exhibit_player.js videojs-offset.min.js iterable_forms.js timeline.js timeline.css leaflet.css MarkerCluster.css leaflet.js leaflet.markercluster.js map.css map.js )
