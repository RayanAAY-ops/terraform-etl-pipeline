

# Makefile for creating Lambda layer

.PHONY: generate-lambda-layer clean

# Target for generating the Lambda layer
generate-lambda-layer: layer-data-ingestion.zip

layer-data-ingestion.zip:
	@mkdir -p lambda-layers/python/lib/python3.11/site-packages
	@pip3.11 install -r pipeline/requirements.txt --target lambda-layers/python/lib/python3.11/site-packages
	@cd lambda-layers && zip -r9 layer-data-ingestion.zip .
	@cd lambda-layers && rm -rf python

# Clean target to remove generated files
clean:
	@rm -rf lambda-layers


get-ressources-tags:
	@aws resourcegroupstaggingapi get-resources \
		--tag-filters Key=Project,Values=TODELETE-etl-pipeline-iac \
		--query 'ResourceTagMappingList[*].ResourceARN' \
		--output table