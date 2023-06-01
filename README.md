---
ospool:
    path: software_examples/r/tutorial-R-addlibSNA/README.md
---

# Use R Packages in your R Jobs

Often we may need to add R external libraries that are not part of 
the base R installation.
This tutorial describes how to create custom R libraries for use in jobs 
on the OSPool.

## Background

The material in this tutorial builds upon the 
[Run R Scripts on the OSPool](https://portal.osg-htc.org/documentation/software_examples/r/tutorial-R/) 
tutorial. If you are not already familiar with how to run R jobs on 
the OSPool, please see that tutorial first for a general introduction. 

## Setup Directory and R Script

First we'll need to create a working directory, you can either run 
`$ git clone https://github.com/OSGConnect/tutorial-R-addlib` or type the following:

	$ mkdir tutorial-R-addlib
	$ cd tutorial-R-addlib

Similar to the general R tutorial, we will create a script to use as a test 
example. If you did not clone the tutorial, create a script called 
`hello_world.R` that contains the following:
	
	#!/usr/bin/env Rscript

	library(cowsay)

	say("Hello World!", "cow")

We will run one more command that makes the script *executable*, meaning that it 
can be run directly from the command line: 

	$ chmod +x hello_world.R

## Create a Custom Container with R Packages

Using the same container that we used for the general R tutorial, we will 
add the package we want to use (in this case, the `cowsay` package) to create 
a *new* container that we can use for our jobs. 

The new container will be generated from a "definition" file. If it isn't already 
present, create a file called `cowsay.def` that has the following lines: 

	Bootstrap: docker
	From: opensciencegrid/osgvo-r:3.5.0

	%post
		R -e "install.packages('cowsay', dependencies=TRUE, repos='http://cran.rstudio.com/')"

This file basically says that we want to start with one of the existing OSPool R 
containers and add the `cowsay` package from CRAN. 

To create the new container, set the following variables: 

	$ export TMPDIR=$HOME
	$ export APPTAINER_CACHE_DIR=$HOME

And then run this command: 

	apptainer build cowsay-test.sif cowsay.def

It may take 5-10 minutes to run. Once complete, if you run `ls`, you should see a 
file in your current directory called `cowsay-test.sif`. This is the new container. 

> Building containers can be a new skill and slightly different for different 
> packages! We recommend looking at our container guides and container training 
> materials to learn more -- these are both linked from our main guides page. 
> There are also some additional tips at the end of this tutorial on building 
> containers with R packages. 

## Test Custom Container and R Script

Start the container you created by running: 

	$ apptainer shell cowsay-test.sif

Now we can test our R script: 

	Singularity :~/tutorial-R-addlib> ./hello_world.R

If this works, we will have a message with a cow printed to our terminal. Once we have this output, we'll exit the container for now with `exit`: 

	Singularity :~/tutorial-R-addlib>  exit
	$ 

##  Build the HTCondor Job

For this job, we want to use the custom container we just created. For 
efficiency,  it is best to transfer this to the job using the [OSDF](). 
If you want to use the container you just built, copy it to the appropriate 
directory listed here, based on which Access Point you are using. 

Our submit file, `R.submit` should then look like this: 

	+SingularityImage = "osdf://osgconnect/public/osg/tutorial-R-addlib/cowsay-test.sif"
	executable        = hello_world.R
	# arguments

	log    = R.log.$(Cluster).$(Process)
	error  = R.err.$(Cluster).$(Process)
	output = R.out.$(Cluster).$(Process)

	+JobDurationCategory = "Medium"

	request_cpus   = 1
	request_memory = 1GB
	request_disk   = 1GB

	queue 1

Change the `osdf://` link in the submit file to be right for YOUR Access Point and 
username, if you are using your own container file. 

> **Reminder:** Files placed in the OSDF can be copied to other data spaces ("caches") 
> where they are NOT UPDATED. If you make a new container to use with your jobs, 
> make sure to give it a different name or put it at a different path than the 
> previous container. You will not be able to replace the exact path of the existing 
> container. 

## Submit Jobs and Review Output

Now we are ready to submit the job:

    $ condor_submit R.submit

and check the job status:

    $ condor_q

Once the job finished running, check the output file as before. They should look like this:

	$ cat R.out.0000.0
	 ----- 
	Hello World! 
	 ------ 
		\   ^__^ 
		 \  (oo)\ ________ 
			(__)\         )\ /\ 
				 ||------w|
				 ||      ||


## Tips for Building Containers with R Packages

There is a lot of variety in how to build custom containers! The two main decisions
you need to make are a) what to use as your "base" or starting container and what 
packages to install. 

There is a useful overview of building containers from our container training, 
linked on our [training page](https://portal.osg-htc.org/documentation/support_and_training/training/osgusertraining/).

### Base Containers

In this guide we used one of the existing OSPool R containers. You 
can see the other versions of R that we support on our list of [OSPool Supported Containers]()

Another good option for a base container are the "rocker" Docker containers: 
[Rocker on DockerHub](https://hub.docker.com/u/rocker)

To use a different container as the base container, you just change the top of 
the definition file. So to use the [rocker tidyverse container](https://hub.docker.com/r/rocker/tidyverse) as my starting point, I would 
have a definition file header like this:

	Bootstrap: docker
	From: rocker/tidyverse:4.1.3

When using containers from DockerHub, it's a good idea to pick a version (look at 
the "Tags" tab for options). Above, this container would be version `4.1.3` of R. 

### Installing Packages

The sample definition file from this tutorial installed one package. If you have 
multiple packages, you can change the "install.packages" command to install 
multiple packages: 

	%post
 	  R -e "install.packages(c('cowsay','here'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

*If your base container is one of the "rocker" containers*, you can use a different
tool to install packages that looks like this: 

	%post
 	  install2.r cowsay

or for multiple packages: 

	%post
 	  install2.r cowsay here

Remember, you only need to install packages that aren't already in the container. If 
you start with the tidyverse container, you don't need to install `ggplot2` or `dplyr` - 
those are already in the container and you would be adding packages on top. 
