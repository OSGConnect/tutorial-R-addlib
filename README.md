[title]: - "Use External Packages in your R Jobs"

[TOC]

# Overview

This tutorial describes how to create custom R libraries for use in jobs 
on OSG Connect.

# Background

The material in this tutorial builds upon the 
[Run R Scripts on OSG](https://support.opensciencegrid.org/support/solutions/articles/12000056217-run-r-scripts-on-osg) 
tutorial. If you are not already familiar with how to run R jobs on 
OSG Connect, please see that tutorial first.

# Use custom R libraries on OSG

Often we may need to add R external libraries that are not part of 
the base R installation. As a user, we could add the libraries in 
our home (or stash) directory and then compress the library to make 
them available on remote machines for job executions.

## Setup Workflow Files

First we'll need to create a working directory, you can either run 
`$ tutorial R-addlib` or type the following:

	$ mkdir tutorial-R-addlib
	$ cd tutorial-R-addlib

In the previous tutorial, recall that we created the script `hello_world.R` 
that contained the following:

	print("Hello World!")

We also created a wrapper script called `R-wrapper.sh` to execute our R 
script. The contents of that file is shown below:

	#!/bin/bash
	
	# create a tmp directory
	mkdir rtmp
	export TMPDIR=$_CONDOR_SCRATCH_DIR/rtmp
	
	Rscript hello_world.R

Finally, we had the `R.submit` submit script which we used to submit the 
job to OSG Connect:

	universe = vanilla
	log = R.log.$(Cluster).$(Process)
	error = R.err.$(Cluster).$(Process)
	output = R.out.$(Cluster).$(Process)
	
	+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-r:3.5.0" 
	executable = R-wrapper.sh
	transfer_input_files = hello_world.R
	
	request_cpus = 1
	request_memory = 1GB
	request_disk = 1GB
	 
	queue 1


## Create a Directory for Packages

It is helpful to create a dedicated directory to install the package 
into. This will facilitate zipping the library so it can be transported 
with the job. Say, you decided to build the library in `R-packages` in 
the current folder. If it does not already exist, 
make the necessary directory by typing the following in your shell prompt:

    $ mkdir -p R-packages
	
## Start an R Container and Install Packages

Start an R container by running: 

	$ singularity shell /cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-r:3.5.0

> ### Other Supported R Versions
> 
> To see a list of all Singularity containers containing R, look at the 
> list of [OSPool Supported Containers](https://support.opensciencegrid.org/support/solutions/articles/12000073449-view-existing-ospool-supported-containers)

Before starting to run R, set the `R_LIBS` environment variable so R 
knows where to find our custom library directory:

	$ export R_LIBS=$PWD/R-packages

We also need to set the `TMPDIR` variable so that R has a place 
to download any intermediate or temporary package files. 

	$ export TMPDIR=$PWD

Now we can run R and check that our library location is being used (here 
the `>` is the R-prompt):

	Singularity osgvo-r:3.5.0:~> R
	> .libPaths()
	[1] "/home/alice/tutorial-R-addlib/R-packages"
	[2] "/usr/lib64/R/library"                     
	[3] "/usr/share/R/library"

We should be able to see our `R-packages` path in `[1]`. We can 
also check for available libraries within R.

    > library()

Press `q` to close that display.

To install packages within R, we use the command (where “XYZ” is the name 
of the target package):
 
    > install.packages("XYZ", repos = "http://cloud.r-project.org/", dependencies = TRUE)

For this tutorial, we are going to use the `lubridate` package. To install
lubridate, enter this command:

    > install.packages("cowsay", repos="http://cloud.r-project.org/")

## Turn Package Directory Into a tar.gz File

Proceeding with the `cowsay` package, the next step is create a tarball of 
the package so we can send the tarball along with the job. 

Exit from the R prompt by typing:

    > quit()

or:

    >q()

In either case, be sure to say `n` when prompted to `Save workspace image? [y/n/c]:`.
And then exit out of the container by typing "exit": 

	Singularity osgvo-r:3.5.0:~> exit
	$ 

To tar the package directory, type the following at the shell prompt:

    $ tar -czf R-packages.tar.gz R-packages/

## Use Packages in an R Script

Now, let's change the `hello_world` job to use the new package. First, modify the 
`hello_world.R` R script by adding and changing the following lines:

	library(cowsay)
	
	say("Hello World!", "cow")	

## Define Packages in the Executable

R library locations are set upon launch and can be modified using the `R_LIBS` 
environmental variable. To set this correctly, we need to modify the wrapper script. 
Change the file `R-wrapper.sh` so it matches the following:

	#!/bin/bash
	
	# Uncompress the tarball
	tar -xzf R-packages.tar.gz
	
	# Set the library location
	export R_LIBS="$PWD/R-packages"
	# set TMPDIR variable
	export TMPDIR=$_CONDOR_SCRATCH_DIR
	
	# run the R program
	Rscript hello_world.R

## Include Packages in the Submit File

Next, we need to modify the submit script so that the package tarball is 
transferred correctly with the job. Change the submit script `R.submit` so that 
`transfer_input_files` and `arguments` are set correctly. The completed file, 
which can bee seen in `R.submit` should look like below:

	universe = vanilla
	log = R.log.$(Cluster).$(Process)
	error = R.err.$(Cluster).$(Process)
	output = R.out.$(Cluster).$(Process)

	+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-r:3.5.0" 
	executable = R-wrapper.sh
	transfer_input_files = R-packages.tar.gz, hello_world.R
	
	request_cpus = 1
	request_memory = 1GB
	request_disk = 1GB

	queue 1


## Submit Jobs and Review Output

Now we are ready to submit the job:

    $ condor_submit R.submit

and check the job status:

    $ condor_q

Once the job finished running, check the output files as before. They should now look like this:

	$ cat R.out.0000.0
	 ----- 
	Hello World! 
	 ------ 
		\   ^__^ 
		 \  (oo)\ ________ 
			(__)\         )\ /\ 
				 ||------w|
				 ||      ||


# Variations on This Process

## Install multiple packages at once

If you have multiple packages to be added, it may be better to list each of 
the `install.packages()` commands within a separate R script and source the 
file to R.  For example, if we needed to install `ggplot2`, `dplyr`, and 
`tidyr`, we can list them to be installed in a script called `setup_packages.R` 
which would contain the following: 

    install.packages("ggplot2", repos="http://cloud.r-project.org/", dependencies = TRUE)
    install.packages("dplyr", repos="http://cloud.r-project.org/", dependencies = TRUE)
    install.packages("tidyr", repos="http://cloud.r-project.org/", dependencies = TRUE)

Then, install all of the packages by running the setup file within R:

    > source(`setup_packages.R`) 


# Getting Help

For assistance or questions, please email the OSG User Support team  at <mailto:support@opensciencegrid.org>.
