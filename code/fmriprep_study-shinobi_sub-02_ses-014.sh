#!/bin/bash
#SBATCH --account=rrg-pbellec
#SBATCH --job-name=fmriprep_study-shinobi_sub-02_ses-014.job
#SBATCH --output=/lustre03/project/6003287/datasets/cneuromod_processed/fmriprep/shinobi/code/fmriprep_study-shinobi_sub-02_ses-014.out
#SBATCH --error=/lustre03/project/6003287/datasets/cneuromod_processed/fmriprep/shinobi/code/fmriprep_study-shinobi_sub-02_ses-014.err
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=4096M
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=basile.pinsard@gmail.com
 
set -e -u -x

export SINGULARITYENV_TEMPLATEFLOW_HOME="sourcedata/templateflow/"


export LOCAL_DATASET=$SLURM_TMPDIR/${SLURM_JOB_NAME//-/}/
flock --verbose /project/rrg-pbellec/ria-beluga/alias/cneuromod.shinobi.fmriprep/.datalad_lock datalad clone ria+file:///project/rrg-pbellec/ria-beluga#~cneuromod.shinobi.fmriprep $LOCAL_DATASET
cd $LOCAL_DATASET
datalad get -s ria-beluga-storage -n -r -R1 . # get sourcedata/* containers
datalad get -s ria-beluga-storage -r sourcedata/templateflow/tpl-{MNI152NLin2009cAsym,OASIS30ANTs,fsLR,fsaverage,MNI152NLin6Asym}
if [ -d sourcedata/smriprep ] ; then
    datalad get -n sourcedata/smriprep sourcedata/smriprep/sourcedata/freesurfer
fi
git submodule foreach --recursive git annex dead here
git checkout -b $SLURM_JOB_NAME
if [ -d sourcedata/freesurfer ] ; then
  git -C sourcedata/freesurfer checkout -b $SLURM_JOB_NAME
fi


datalad containers-run -m 'fMRIPrep_sub-02/ses-014' -n containers/bids-fmriprep --input sourcedata/shinobi/sub-02/ses-014/fmap/ --input sourcedata/shinobi/sub-02/ses-014/func/ --input sourcedata/templateflow/tpl-MNI152NLin2009cAsym/ --input sourcedata/templateflow/tpl-OASIS30ANTs/ --input sourcedata/templateflow/tpl-fsLR/ --input sourcedata/templateflow/tpl-fsaverage/ --input sourcedata/templateflow/tpl-MNI152NLin6Asym/ --output . --input 'sourcedata/smriprep/sub-02/anat/' --input sourcedata/smriprep/sourcedata/freesurfer/fsaverage/ --input sourcedata/smriprep/sourcedata/freesurfer/sub-02/ -- -w ./workdir --participant-label 02 --anat-derivatives ./sourcedata/smriprep --fs-subjects-dir ./sourcedata/smriprep/sourcedata/freesurfer --bids-filter-file code/fmriprep_study-shinobi_sub-02_ses-014_bids_filters.json --output-layout bids --ignore slicetiming --use-syn-sdc --output-spaces MNI152NLin2009cAsym T1w:res-iso2mm --cifti-output 91k --notrack --write-graph --skip_bids_validation --omp-nthreads 8 --nprocs 8 --mem_mb 32768 --fs-license-file code/freesurfer.license --resource-monitor sourcedata/shinobi ./ participant 
fmriprep_exitcode=$?

flock --verbose /project/rrg-pbellec/ria-beluga/alias/cneuromod.shinobi.fmriprep/.datalad_lock datalad push -d ./ --to origin
if [ -d sourcedata/freesurfer ] ; then
    flock --verbose /project/rrg-pbellec/ria-beluga/alias/cneuromod.shinobi.fmriprep/.datalad_lock datalad push -d sourcedata/freesurfer $LOCAL_DATASET --to origin
fi 
if [ -e $LOCAL_DATASET/resource_monitor.json ] ; then cp $LOCAL_DATASET/resource_monitor.json /scratch/bpinsard/fmriprep_study-shinobi_sub-02_ses-014_resource_monitor.json ; fi 
if [ $fmriprep_exitcode -ne 0 ] ; then cp -R $LOCAL_DATASET /scratch/bpinsard/fmriprep_study-shinobi_sub-02_ses-014 ; fi 
exit $fmriprep_exitcode 
