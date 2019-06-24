# Run PyClone on cbioportal datasets
## Description:


## Requirment: 
- Perl6 with `YAMLish` installed.
- R with packagers `data.table` installed.
- Pyclone

## Docker image
The `Dockerfile` can be used to build the docker image to run the pipeline.
```
docker build . -t cbioportal2pyclone:latest
docker run -it cbioportal2pyclone:latest
```

## Test
The test script will download the dataset from cBioPoratl and run the pipeline:
```
bash test/test_run_pyclone.sh
```
