

# Makefile for creating Lambda layer

.PHONY: generate-lambda-layer clean

# Target for generating the Lambda layer
generate-lambda-layer: layer-data-ingestion.zip

layer-data-ingestion.zip:
	@mkdir -p lambda/lambda-layers/python/lib/python3.11/site-packages
	@pip3.11 install -r lambda/requirements.txt --target lambda/lambda-layers/python/lib/python3.11/site-packages
	@cd lambda/lambda-layers && zip -r9 layer-data-ingestion.zip .
	@cd lambda/lambda-layers && rm -rf python

# Clean target to remove generated files
clean:
	@rm -rf lambda/lambda-layers


get-ressources-tags:
	@aws resourcegroupstaggingapi get-resources \
		--tag-filters Key=Project,Values=TODELETE-etl-pipeline-iac \
		--query 'ResourceTagMappingList[*].ResourceARN' \
		--output table