#!/bin/bash -l
#SBATCH --job-name=npz-to-imgs
#SBATCH --output=sysout/%j.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:1  # Placeholder, will be overridden by main script
#SBATCH --time=024:00:00
#SBATCH --mem=10G

SECONDS=0
echo "====" `date +%Y%m%d-%H%M%S` "start of job $SLURM_JOB_NAME ($SLURM_JOB_ID) on node $SLURMD_NODENAME on cluster $SLURM_CLUSTER_NAME"


# Print the allocated nodes and partition
echo "Allocated nodes:" $SLURM_JOB_NODELIST
echo "Partition:" $SLURM_JOB_PARTITION


nvidia-smi

# replaced conda environment with python environment
source /projects01/VICTRE/yubi.mamiya/minimal-diffusion/min-diff-venv/bin/activate

# CUDA_VISIBLE_DEVICES=0
echo -e "CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"
export NVIDIA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES

time python npz_to_images_luna.py

deactivate

EXIT_STATUS=$?
echo "Duration: $SECONDS seconds elapsed."
echo "====" `date +%Y%m%d-%H%M%S` "end of job $SLURM_JOB_NAME ($SLURM_JOB_ID) on node $SLURMD_NODENAME on cluster $SLURM_CLUSTER_NAME: EXIT_STATUS=$EXIT_STATUS"
