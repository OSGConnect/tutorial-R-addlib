#!/bin/bash

module load r

# Uncompress the tarball
tar -xzf lubridate_R.3.5.tar.gz
	
# Set the library location
export R_LIBS="$PWD/lubridate_R.3.5"
	
# run the R program
Rscript --no-save hello_world.R