# This is a Makefile for producing the uk.json topojson file used in
# Mike Bostock's tutorial "Let's make a map" http://bost.ocks.org/mike/map/

# 3 June 2013: Now includes processing of Office of National
#              Statistics 2011 Ward boundaries. Thanks to John Nance
#              for help with ogr2ogr.

# 5 June 2013: Adding postal code boundaries from Geolytix.

NATURALEARTH=http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural
ONS=http://data.statistics.gov.uk/ONSGeography/CensusGeography/Boundaries/2011
GEOLYTIX=http://geolytix.co.uk/images

all: topo/uk.json \
	topo/ukwards.topo.json \
	topo/geolytix/PostalArea.topo.json

clean:
	rm -rf gz shp topo ons

tidy:
	rm -rf *.README.html *.VERSION.txt *.prj


# UK Boundary from Natural Earth data

gz/ne/%.zip:
	mkdir -p $(dir $@) && wget $(NATURALEARTH)/$(notdir $@) -O $@.download && mv $@.download $@

#Note that ogr2ogr requires the .shp, .shx and .dbf files to work.
shp/ne/%.shp: gz/ne/%.zip
	mkdir -p $(dir $@) && unzip $< -d $(dir $@)
	touch $@
	make tidy

topo/subunits.json: shp/ne/ne_10m_admin_0_map_subunits.shp
	mkdir -p $(dir $@)
	cd shp/ne; \
	ogr2ogr \
		-f GeoJSON \
		-where "adm0_a3 IN ('GBR', 'IRL')" \
		subunits.json \
		ne_10m_admin_0_map_subunits.shp; \
	mv $(notdir $@) ../../$@
	
topo/places.json: shp/ne/ne_10m_populated_places.shp
	mkdir -p $(dir $@)
	cd shp/ne; \
	ogr2ogr \
		-f GeoJSON \
		-where "iso_a2 = 'GB' AND SCALERANK < 8" \
		places.json \
		ne_10m_populated_places.shp; \
	mv $(notdir $@) ../../$@	

topo/uk.json: topo/subunits.json topo/places.json
	mkdir -p $(dir $@)
	topojson \
		--id-property su_a3 \
		-p name=NAME \
		-p name \
		-o topo/uk.json \
		topo/subunits.json \
		topo/places.json

# English Wards, from Office of National Statistics.

ons/WD_DEC_2011_EW_BGC_shp.zip: 
	mkdir -p $(dir $@) && wget $(ONS)/Wards/$(notdir $@) -O $@.download && mv $@.download $@

shp/ons/WD_DEC_2011_EW_BGC.shp: ons/WD_DEC_2011_EW_BGC_shp.zip
	mkdir -p $(dir $@) && unzip $< -d $(dir $@)
	touch $@

topo/ukwards.json: shp/ons/WD_DEC_2011_EW_BGC.shp
	mkdir -p $(dir $@)
	cd shp/ons; \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		ukwards.json \
		WD_DEC_2011_EW_BGC.shp; \
	mv $(notdir $@) ../../$@

topo/ukwards.topo.json: topo/ukwards.json
	mkdir -p $(dir $@)
	topojson \
		-o topo/ukwards.topo.json \
		topo/ukwards.json \
		--id-property WD11CD \
		--properties WD11NM \
		--simplify-proportion 0.5

# English and Scottish postal boundaries from Geolytix.

gz/geolytix/PostalBoundariesSHP.zip: 
	mkdir -p $(dir $@) && wget $(GEOLYTIX)/$(notdir $@) -O $@.download && mv $@.download $@
	touch $@

shp/geolytix/PostalBoundariesSHP/%.shp: gz/geolytix/PostalBoundariesSHP.zip
	rm -rf $(dir $@) && mkdir -p $(dir $@) && unzip $< -d $(dir $@)
	touch $(dir $@)/*

topo/geolytix/PostalArea.json: shp/geolytix/PostalBoundariesSHP/PostalArea.shp
	mkdir -p $(dir $@)
	cd shp/geolytix/PostalBoundariesSHP; \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		PostalArea.json \
		PostalArea.shp; \
	mv $(notdir $@) ../../../$@

topo/geolytix/PostalArea.topo.json: topo/geolytix/PostalArea.json
	mkdir -p $(dir $@)
	topojson \
		-o topo/geolytix/PostalArea.topo.json \
		topo/geolytix/PostalArea.json \
		--id-property PostArea \
		--properties \
		--simplify-proportion 0.2

topo/geolytix/PostalDistrict.json: shp/geolytix/PostalBoundariesSHP/PostalDistrict.shp
	mkdir -p $(dir $@)
	cd shp/geolytix/PostalBoundariesSHP; \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		PostalDistrict.json \
		PostalDistrict.shp; \
	mv $(notdir $@) ../../../$@

topo/geolytix/PostalDistrict.topo.json: topo/geolytix/PostalDistrict.json
	mkdir -p $(dir $@)
	topojson \
		-o topo/geolytix/PostalDistrict.topo.json \
		topo/geolytix/PostalDistrict.json \
		--id-property PostDist \
		--properties \
		--simplify-proportion 0.2

topo/geolytix/PostalDistrict_v2.json: shp/geolytix/PostalBoundariesSHP/PostalDistrict_v2.shp
	mkdir -p $(dir $@)
	cd shp/geolytix/PostalBoundariesSHP; \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		PostalDistrict_v2.json \
		PostalDistrict_v2.shp; \
	mv $(notdir $@) ../../../$@

topo/geolytix/PostalDistrict_v2.topo.json: topo/geolytix/PostalDistrict_v2.json
	mkdir -p $(dir $@)
	topojson \
		-o topo/geolytix/PostalDistrict_v2.topo.json \
		topo/geolytix/PostalDistrict_v2.json \
		--id-property PostDist \
		--properties \
		--simplify-proportion 0.2



