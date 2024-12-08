window.onload = function go() {
	
	// Affichage du loader
	document.querySelector("body").style.visibility = "hidden";
	document.getElementById("load").style.visibility = "visible";
	/* console.log("Chargement de la carte ... ⛔"); */
	
	// Style des couches
	var style_regions = new ol.style.Style({
		stroke: new ol.style.Stroke({
			color: "black", width: 1
		})
	})
	
	var style_departements = new ol.style.Style({
		stroke: new ol.style.Stroke({
			color: "#3b609c", lineDash: [1, 6], width: 2
		})
	})
	
	// Création des couches vecteurs
	var layer_bdd1 = new ol.layer.Vector();
	var layer_bdd2 = new ol.layer.Vector();
	var layer_bdd3 = new ol.layer.Vector();
	var layer_bdd4 = new ol.layer.Vector();
	
	// Ajout des contours des régions/départements
	var regions = new ol.layer.Vector({
		source: new ol.source.Vector({
			url: 'https://cartes.cigalesdefrance.fr/DATA/regions.geojson',
			format: new ol.format.GeoJSON()
		}),
		minResolution: 200,
		style: style_regions
	});
	
	var departements = new ol.layer.Vector({
		source: new ol.source.Vector({
			url: 'https://cartes.cigalesdefrance.fr/DATA/departements.geojson',
			format: new ol.format.GeoJSON()
		}),
		minResolution: 10,
		maxResolution: 500,
		style: style_departements
	});
	
	// Fonds de carte de base : OSM et BDOrtho IGN
	var layer_osm = new ol.layer.Tile({
		source: new ol.source.OSM({attributions: [
		'<span style="color:#b70000; font-weight:bold">Version en développement</span> | <a href="https://github.com/CigalesdeFrance/CARTES/">Code source/Erreurs</a> | © <a href="https://www.cigalesdefrance.fr">Cigales de France</a> |',ol.source.OSM.ATTRIBUTION,'<br><a href="https://inpn.mnhn.fr"><img class="copyright" src="https://cartes.cigalesdefrance.fr/ASSETS/LOGOS/INPN.png" alt="Logo de l\'INPN"></a><a href="https://observation.org"><img class="copyright" src="https://cartes.cigalesdefrance.fr/ASSETS/LOGOS/OBSERVATION.svg" alt="Logo d\'Observation.org"></a><a href="https://www.gbif.org"><img class="copyright" src="https://cartes.cigalesdefrance.fr/ASSETS/LOGOS/GBIF.svg" alt="Logo de GBIF"></a><a href="https://www.inaturalist.org/"><img class="copyright" src="https://cartes.cigalesdefrance.fr/ASSETS/LOGOS/INATURALIST.svg" alt="Logo d\'iNaturalist"></a>']}),
		opacity: 1
	});
	
	// Ne fonctionne pas avec OL 7.0.0
	var layer_ortho = new ol.layer.Tile({
		source: new ol.source.GeoportalWMTS({layer: "ORTHOIMAGERY.ORTHOPHOTOS"}),
		/* minResolution: 200, */
		maxResolution: 200,
		opacity: 0.3
	});
	
	// Bloquage de la rotation sur téléphone
	//var interactions = ol.interaction.defaults({altShiftDragRotate:false, pinchRotate:false});
	
	// Création de la carte
	var map = new ol.Map({
		//interactions: interactions,
		target: 'map',
		layers: [
			layer_osm,
			layer_ortho,
			regions,
			departements,
			layer_bdd4,
			layer_bdd3,
			layer_bdd2,
			layer_bdd1
		],
		view: new ol.View({
			center: ol.proj.transform([2, 47], 'EPSG:4326', 'EPSG:3857'),
			zoom: 5.8
		})
	});
	
	// Désactivation du loader et affichage de la carte
	map.on('rendercomplete', e => {
		document.getElementById("load").style.display ="none";
		document.querySelector("body").style.visibility = "visible";
		/* console.log("Carte prête ✅") */
	});
	
	// Pointeur
 	map.on("pointermove", function (evt) {
		var hit = map.forEachFeatureAtPixel(evt.pixel, function(feature, layer) {
			if ( layer == layer_bdd1 || layer == layer_bdd2 || layer == layer_bdd3 || layer == layer_bdd4 ) return true;
		}); 
		if (hit) {
			map.getTargetElement().style.cursor = 'pointer';
			} else {
			map.getTargetElement().style.cursor = '';
		}
	});
	
	// Fonctionnalité de sélection d'entités
	var selectClick = new ol.interaction.Select({
		layers: [ layer_bdd1, layer_bdd2, layer_bdd3, layer_bdd4 ],
		condition: ol.events.click
	});
	map.addInteraction(selectClick);
	
	// Actions lors de la sélection
 	map.on('click', function(evt) {
		var pixel = evt.pixel;
		var features = [];
		map.forEachFeatureAtPixel(pixel, function(feature, layer) {
			if ( layer == layer_bdd1 || layer == layer_bdd2 || layer == layer_bdd3 || layer == layer_bdd4 ) { features.push(feature) };
		});
		if ( features[0] == undefined ) {/* console.log("Clic hors données ⛔") */}
		else {
			observation.innerHTML = '<button class="detail"><a href="' + features[0].get("description") + '" target="_blank">➤ Visualiser l\'observation</a></button>';
		}
	});
	
	// Création du Layer Switcher
	var lsControl = new ol.control.LayerSwitcher({
		layers : [
			{layer: layer_bdd1,
				config: {
					title: "Inaturalist",
					description: "Données provenant de Inaturalist, une base de données participative dont les identifications s'effectuent de manière communautaire à partir de photographies.",
				}
			},
			{layer: layer_bdd2,
				config: {
					title: "Observation.org",
					description: "Données provenant de Observation.org, une base de données internationale."
				}
			},
			{layer: layer_bdd3,
				config: {
					title: "GBIF",
					description: "Données provenant du Global Biodiversity Information Facility, qui a pour but de mettre à disposition toute l'information connue sur la biodiversité (données d'observations ou de collections sur les animaux, plantes, champignons, bactéries et archaea)."
				}
			},
			{layer: layer_bdd4,
				config: {
					title: "INPN",
					description: "Données provenant de l'Inventaire National du Patrimoine Naturel par le biais d'OpenObs"
				}
			},
			{layer: regions,
				config: {
					title: "Régions de France",
					description: ""
				}
				},{layer: departements,
				config: {
					title: "Départements de France",
					description: ""
				}
			},
			{layer: layer_osm,
				config: {
					title: "OpenStreetMap",
					description: "Couche OpenStreetMap"
				}
			}
		]
	});
	
	// Ajout du LayerSwitcher à la carte
	map.addControl(lsControl);
	
	// Lien vers le wiki
	var wiki_a = document.createElement('a');
	wiki_a.href = 'https://www.cigalesdefrance.fr';
	wiki_a.title = 'Accès au wiki';
	var wiki_button = document.createElement('button');
	wiki_button.className = 'wikilink'
	wiki_button.innerHTML = 'W';
	var wiki = document.createElement('div');
	wiki.className = 'ol-unselectable ol-control';
	wiki.appendChild(wiki_a).appendChild(wiki_button);
	
	var wiki_link = new ol.control.Control({ element: wiki });
	map.addControl(wiki_link);
	
	// Lien vers le forum
	var forum_a = document.createElement('a');
    forum_a.href = 'https://forum.cigalesdefrance.fr';
	forum_a.title = 'Accès au forum';
	var forum_button = document.createElement('button');
	forum_button.className = 'forumlink'
	forum_button.innerHTML = 'F';
	var forum = document.createElement('div');
	forum.className = 'ol-unselectable ol-control';
	forum.appendChild(forum_a).appendChild(forum_button);
	
	var forum_link = new ol.control.Control({ element: forum });
	map.addControl(forum_link);
	
	// Création du contrôle de mesure de distance
	//var length = new ol.control.MeasureLength();
	//map.addControl(length);
	
	// Création du contrôle de détermination des coordonnées + altitude
	var mpControl = new ol.control.GeoportalMousePosition({
		//apiKey: "calcul",
		collapsed: true,
		editCoordinates : true,
		altitude : {
			triggerDelay : 500
		} 
	});
	map.addControl(mpControl);
	
	// Recherche de lieu
	var searchControl = new ol.control.SearchEngine();
	map.addControl(searchControl);
	
	// Attribution automatique
	var attControl = new ol.control.GeoportalAttribution({collapsed: false});
	map.addControl(attControl);
	
	// Extraction de l'espèce dans l'URL
	var espece = location.search.substring(1);
	$("#choix option[espece='" + espece + "']").attr("selected","selected");
	
	// Sélection de l'espèce et actions lors du changement
	var choix = document.getElementById('choix');
	choix.onchange = function() {
		
		var espece = this.options[this.selectedIndex].getAttribute('espece');
		
		autres_cartes.innerHTML = '<button class="detail"><a href="./AUTRES/" target="_blank">➤ Autres sources</a></button>';
		
		if (espece !== null) {
			
			// Mise à jour de l'URL quand l'espèce change
			var change_url = { Title: espece, Url: 'index.html?'+ espece	};
			history.pushState(change_url, change_url.Title, change_url.Url);
			
			autres_cartes.innerHTML = '<button class="detail"><a href="./AUTRES/index.html?' + espece + '" target="_blank">➤ Autres sources</a></button>';
			fiche_espece.innerHTML = '<button class="detail"><a href="https://www.cigalesdefrance.fr/espece:' + espece + '" target="_blank">➤ Fiche espèce</a></button>';
			
			// Adresses des KML et ajout des sources aux couches
			var url_bdd1 = 'https://cartes.cigalesdefrance.fr/BDD/INATURALIST/' + espece + '.kml';
			var url_bdd2 = 'https://cartes.cigalesdefrance.fr/BDD/OBSERVATION/' + espece + '.kml';
			var url_bdd3 = 'https://cartes.cigalesdefrance.fr/BDD/GBIF/' + espece + '.kml';
			var url_bdd4 = 'https://cartes.cigalesdefrance.fr/BDD/INPN/' + espece + '.kml';
			
			layer_bdd1.setSource(
				new ol.source.Vector({
					format: new ol.format.KML({
						extractStyles: true,
						extractAttributes: true
					}),
					url: url_bdd1
				})
			);
			
			layer_bdd2.setSource(
				new ol.source.Vector({
					format: new ol.format.KML({
						extractStyles: true,
						extractAttributes: true
					}),
					url: url_bdd2
				})
			);
			
			layer_bdd3.setSource(
				new ol.source.Vector({
					format: new ol.format.KML({
						extractStyles: true,
						extractAttributes: true
					}),
					url: url_bdd3
				})
			);
			
			layer_bdd4.setSource(
				new ol.source.Vector({
					format: new ol.format.KML({
						extractStyles: true,
						extractAttributes: true
					}),
					url: url_bdd4
				})
			);
		};
	};
	choix.onchange();
};