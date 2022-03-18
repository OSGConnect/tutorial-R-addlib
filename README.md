[title]: - "Use External Packages in your R Jobs"

[TOC]

## Overview

This tutorial describes how to create custom R libraries for use in jobs 
on OSG Connect.

## Background

The material in this tutorial builds up on the [Run R Scripts on OSG]
(https://support.opensciencegrid.org/support/solutions/articles/12000056217-run-r-scripts-on-osg) 
tutorial. If you are not already familiar with how to run R jobs on 
OSG Connect, please see that tutorial first.

## Use custom R libraries on OSG

Often we may need to add R external libraries that are not part of 
the base R installation. As a user, we could add the libraries in 
our home (or stash) directory and then compress the library to make 
them available on remote machines for job executions.

### Setup Workflow Files

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
	
	module load r
	Rscript --no-save hello_world.R

Finally, we had the `R.submit` submit script which we used to submit the 
job to OSG Connect:

	universe = vanilla
	log = R.log.$(Cluster).$(Process)
	error = R.err.$(Cluster).$(Process)
	output = R.out.$(Cluster).$(Process)
	 
	executable = R-wrapper.sh
	transfer_input_files = hello_world.R
	
	request_cpus = 1
	request_memory = 1GB
	request_disk = 1GB
	 
	requirements = OSGVO_OS_STRING == "RHEL 7" && Arch == "X86_64" && HAS_MODULES == True
	queue 1

### Build external packages for R under userspace

It is helpful to create a dedicated directory to install the package 
into. This will facilitate zipping the library so it can be transported 
with the job. Say, you decided to built the library in the path 
`/home/username/R_libs/lubridate_R.3.5`. If it does not already exist, 
make the necessary directory by typing the following in your shell prompt:

    $ mkdir -p ~/R_libs/lubridate_R.3.5

After defining the path, we set the `R_LIBS` environment variable so R 
knows where to find our custom library directory:

	$ export R_LIBS=~/R_libs/lubridate_R.3.5
	
Now we can run R and check that our library location is being used (here 
the `>` is the R-prompt):

    $ module load r
	$ R
	...
	> .libPaths()
	[1] "/home/user/R_libs/lubridate_R.3.5"                                                                                                                      
		[2] "/cvmfs/connect.opensciencegrid.org/modules/packages/linux-rhel7-x86_64/gcc-6.4.0spack/r-3.5.1-eoot7bzcbxp3pwf4dxlqrssdk7clylwd/rlib/R/library"
	
Excellent. We can see the location listed as library path `[1]`. We can 
also check for available libraries within R.

    > library()

Press `q` to close that display.

To install packages within R, we use the command (where “XYZ” is the name 
of the target package):
 
    > install.packages("XYZ", repos = "http://cloud.r-project.org/", dependencies = TRUE)

For this tutorial, we are going to use the `lubridate` package. To install
lubridate, enter this command:

    > install.packages("lubridate", repos="http://cloud.r-project.org/", dependencies=TRUE)


### Install multiple packages at once

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


### Prepare a tarball of the add-on packages 

Proceeding with the `lubridate` package, the next step is create a tarball of 
the package so we can send the tarball along with the job. 

Exit from the R prompt by typing:

    > quit()

or:

    >q()

In either case, be sure to say `n` when prompted to `Save workspace image? [y/n/c]:`.

To tar the package directory, type the following at the shell prompt:

    $ cd /home/user/R_libs
    $ tar -cvzf lubridate_R.3.5.tar.gz lubridate_R.3.5

Now copy the tarball to the job directory where the R program, job wrapper script 
and condor job description file are. 


### Use the packages in your OSG job

Now, let's change the `hello_world` job to use the new package. First, modify the 
`hello_world.R` R script by adding the following lines:

	library(lubridate)
	print(today())
	
This will add a print out of the local date to the output of the job. 


### Define the libPaths() in the wrapper script

R library locations are set upon launch and can be modified using the `R_LIBS` 
environmental variable. To set this correctly, we need to modify the wrapper script. 
Change the file `R-wrapper.sh` so it matches the following:

	#!/bin/bash

	module load r
	
	# Uncompress the tarball
	tar -xzf lubridate_R.3.5.tar.gz
	
	# Set the library location
	export R_LIBS="$PWD/lubridate_R.3.5"
	# set TMPDIR variable
	export TMPDIR=$_CONDOR_SCRATCH_DIR
	
	# run the R program
	Rscript --no-save hello_world.R


Once you have edited the file, make the wrapper script executable and test 
it by using the commands below:

	$ chmod +x R-wrapper.sh
	$ ./R-wrapper.sh
	[1] "Hello World!"


Next, we need to modify the submit script so that the package tarball is 
transferred correctly with the job. Change the submit script `R.submit` so that 
`transfer_input_files` and `arguments` are set correctly. The completed file, 
which can bee seen in `R.submit` should look like below:

	universe = vanilla
	log = R.log.$(Cluster).$(Process)
	error = R.err.$(Cluster).$(Process)
	output = R.out.$(Cluster).$(Process)

	executable = R-wrapper.sh
	transfer_input_files = lubridate_R.3.5.tar.gz, hello_world.R
	
	request_cpus = 1
	request_memory = 1GB
	request_disk = 1GB

	requirements = OSGVO_OS_STRING == "RHEL 7" && Arch == "X86_64" && HAS_MODULES == True
	queue 1


### Job submission and output

Now we are ready to submit the job:

    $ condor_submit R.submit

and check the job status:

    $ condor_q username

Once the job finished running, check the output files as before. They should now look like this:

	$ cat R.out.3796676.0
	[1] "2019-05-13"
	[1] "Hello World!"


## Getting Help

For assistance or questions, please email the OSG User Support team  at <mailto:support@opensciencegrid.org>.
