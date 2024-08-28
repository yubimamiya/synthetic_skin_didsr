#!/bin/bash -l
#SBATCH --job-name=sample-imgs-test
#SBATCH --output=sysout/%j.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:2  # Placeholder, will be overridden by main script
#SBATCH --time=024:00:00
#SBATCH --mem=5G


SECONDS=0
echo "====" `date +%Y%m%d-%H%M%S` "start of job $SLURM_JOB_NAME ($SLURM_JOB_ID) on node $SLURMD_NODENAME on cluster $SLURM_CLUSTER_NAME"


# Print the allocated nodes and partition
echo "Allocated nodes:" $SLURM_JOB_NODELIST
echo "Partition:" $SLURM_JOB_PARTITION


nvidia-smi

# conda activate minimal-diffusion-env
# conda activate min-diff-env-new
source /projects01/VICTRE/yubi.mamiya/minimal-diffusion/min-diff-venv/bin/activate

# CUDA_VISIBLE_DEVICES=0
echo -e "CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"
export NVIDIA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES
NP=$((SLURM_CPUS_PER_TASK/2))

MODEL_DIR="/projects01/VICTRE/yubi.mamiya/minimal-diffusion/trained_models/UNet_melanoma-epoch_250-timesteps_1000-class_condn_True_ema_0.9995.pt"
SAVE_DIR_PATH="/projects01/VICTRE/yubi.mamiya/minimal-diffusion/sample_imgs_output_test/"

sampling_args="--arch UNet --sampling-steps 250 --sampling-only --class-cond"

time python -m torch.distributed.launch --nproc_per_node=1 --master_port 55200 main_dist.py \
	--dataset melanoma \
	--batch-size 128 --num-sampled-images 600 \
	$sampling_args --pretrained-ckpt $MODEL_DIR \
	--save-dir $SAVE_DIR_PATH

# deactivate virtual environment
deactivate

EXIT_STATUS=$?
echo "Duration: $SECONDS seconds elapsed."
echo "====" `date +%Y%m%d-%H%M%S` "end of job $SLURM_JOB_NAME ($SLURM_JOB_ID) on node $SLURMD_NODENAME on cluster $SLURM_CLUSTER_NAME: EXIT_STATUS=$EXIT_STATUS"
