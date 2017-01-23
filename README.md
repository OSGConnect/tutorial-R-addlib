[title]: - "Adding external packages to your R jobs"
[TOC] 


## Overview

Often we may need to add R external libraries that are not part of standard R installation. As a user, we could 
add the libraries in our home (or stash) directory and make the libraries available on remote machines for job executions. 

In this tutorial, we learn how to add `sna` package from [Stanford's R-lab](http://sna.stanford.edu/rlabs.php) and perform 
the social network analysis as a HTCondor job on OSG Connect.  

![fig 1](https://raw.githubusercontent.com/OSGConnect/tutorial-R-addlibSNA/master/Figs/SocialNetworkAnalysis.png)

Fig.1. An example outcome of social network analysis using the external R package `sna` from [Stanford's R-lab](http://sna.stanford.edu/rlabs.php)

## Tutorial files

Let us utilize the `tutorial` command. In the command prompt, type

	 $ tutorial R-addlibSNA # Copies the required files to the directory tutorial-R-addlibSNA
 
This will create a directory `tutorial-R-addSNA` with the following files

    setup_sna_packages.R    # Contains the list of sources to be installed for the sna related external packages. 
    sna_R.3.2.0.tar.gz        # The tarball of the installed sna packages provided for convinience. 
    sna_lab_1.R             # The example R program that does social network analysis
    sna_lab_1.sh            # The wrapper script to execute the R program `sna_lab_1.sh`
    sna_lab_1.submit        # The HTCondor job description file
    Log/                    # Directory to store the standard error, log and output files from the HTcondor job.

## How to build external packages for R under userspace

At first we define where to build the external R add-on libraries. We may choose a directory in our home or stash. The 
add-on library path is defined via the shell variable `R_LIBS`. Say, you decided to built the library in the path
 `/home/username/R_libs/sna_R.3.2.0`. Type the following in your shell prompt 

    $ export R_LIBS="/home/username/R_libs/sna_R.3.2"
    $ mkdir -p R_libs/sna_R.3.2 

After defining the path, we are ready to go into R prompt 

    $ module load R/3.2.0
    $ R

To see the available libraries within R  

    > library()

(here the `>` is the R-prompt) 

If you want to install the package “XYZ”, within R do
 
    > install.packages("XYZ", repos = "http://cran.cnr.berkeley.edu/", dependencies = TRUE)

Since we have a list of packages to be added, it is better to list them in a file and source the file 
to R.  The following packages are listed to be installed in `setup_sna_packages.R`: 

    install.packages("igraph", repos = "http://cran.cnr.berkeley.edu/", dependencies = TRUE)
    install.packages("magrittr", repos = "http://cran.cnr.berkeley.edu/", dependencies = TRUE)
    install.packages("sna", repos = "http://cran.cnr.berkeley.edu/", dependencies = TRUE)
    install.packages("igraphtosonia", repos = "http://cran.cnr.berkeley.edu/", dependencies = TRUE)

Run the setup file within R. 

    > source(`setup_sna_packages.R`) 

the above command should install the packages in the path defined by the variable `R_LIBS`. As mentioned above 
we set `R_LIBS` path to `/home/username/R_libs/sna_R.3.2.0` so all of them would be installed in the specified path. 


## Prepare tarball of the add-on packages 

The next step is create a tarball of san_R.3.2.0 so that we send the tarball along with the job. 

Exit from the R prompt. 

    > quit()

or 

    >q()

From the shell prompt 

    $ cd /home/username/R_libs
    $ tar -cvzf sna_R.3.2.0.tar.gz sna_R.3.2.0

Now copy the tarball to your job directory where you have R program, job wrapper script and condor job 
description file. 

## Porting your add-on packages 

The example job description file `sna_lab_1.submit`  contains the following information

    universe = vanilla

    Executable = sna_lab_1.sh
    arguments = sna_R.3.2.0.tar.gz sna_lab_1.R
    transfer_input_files = sna_R.3.2.0.tar.gz, sna_lab_1.R

    output = Log/job.out.$(Process)
    error = Log/job.error.$(Process)
    log = Log/job.log.$(Process)

    requirements = (HAS_CVMFS_oasis_opensciencegrid_org =?= TRUE)

    queue 1


In the above description file, we specify that the files `sna_R.3.2.0.tar.gz` and `sna_lab_1.R` are transferred along with the job to the remote worker machine. Also the name of these two files are passed as arguments. 

## Define the libPaths() in the wrapper script

The wrapper script takes care of executing the R job properly on the remote machine. The wrapper script `sna_lab_1.sh`

 module load libgfortran
 module load R/3.2.0
 tar -xzf $1
 rlocal_lib="$PWD/sna_R.3.2.0"
 Rscript -e ".libPaths(c(.libPaths(), '$rlocal_lib')); source('$2')"

    #!/bin/bash                # Sets up the bash shell environment
    module load libgfortran    # Load ligfortran module (R requires libgfortran library)
    module load R/3.2.0        # Loads the R/3.2.0 module
    tar -xzf $1                # Uncompress the tarball file (first argument defined in sna_lab_1.submit`)
    rlocal_lib="$PWD/sna_R.3.2.0" # Information about the location of add-on libraries
    Rscript -e ".libPaths(c(.libPaths(), '$rlocal_lib')); source('$2')"   # Set up `.libPaths and run the R program `sub_lab_1.R` which is second argument defined in sna_lab_1.submit) 

It is important to define `.libPaths()` about the location of the add-on libraries. 

## Job submission 
Now submit the job

    $ condor_submit sna_lab_1.submit

and check your job status

    $ condor_q username

## Job output 
Once the job finished running, you will see the following pdf files

    $ ls *.pdf
    1.1_Krackhardt_Full.pdf
    1.2_Krackhardt_Advice.pdf
    1.3_Krackhardt_Friendship.pdf
    1.4_Krackhardt_Reports.pdf
    1.5_Krackhardt_Reports_Fruchterman_Reingold.pdf
    1.6_Krackhardt_Reports_Color.pdf
    1.7_Krackhardt_Reports_Vertex_Size.pdf
    1.8_Krackhardt_Overlayed_Ties.pdf
    1.9_Krackhardt_Overlayed_Structure.pdf

## Getting Help

For assistance or questions, please email the OSG User Support team  at [user-support@opensciencegrid.org](mailto:user-support@opensciencegrid.org) or visit the [help desk and community forums](http://support.opensciencegrid.org).
