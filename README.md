# S-SYNTH Scratch README 

This repository contains the code and results for comparing the synthetic images generated by the knowledge-based model S-SYNTH to those generated by diffusion models. This project encompassed the following steps:
1)	Train a stable diffusion model to generate synthetic skin images
2)	Sample and visualize synthetic skin images with lesions from diffusion model
3)	Segment lesions from the synthetic skin images using a segmentation model
4)	Evaluate distribution of skin colors using ITA
5)	Evaluate the performance of a supervised lesion segmentation model on synthetic images
6)	Compare the segmentation performances of synthetic images from the diffusion model vs. S-SYNTH\

# NOTE: repository in-progress

Currently, due to issues with pushing large repositories of data and models to GitHub, we ask that you use min-diff-bare instead of minimal-diffusion and seg-any-bare instead of segment-anything. Therefore, you will need to change the path names in the slurm and python files indicated in this README to match the name of repository location.

Several of the referenced folders in the below README, such as trained_models and sample_images_output_test must be created using the mkdir command before running the job because these folders aren't included in the bare versions of the repositories.

You can find the model checkpoint used for SAM in the [Segment Anything README](https://github.com/facebookresearch/segment-anything?tab=readme-ov-file#model-checkpoints). We used the default or vit_h checkpoint. Please make a folder in the seg-any-bare directory called models and upload the model checkpoint to this folder.

# Setup

Clone this repository to your device or server using the following command.
```
git clone https://github.com/DIDSR/ssynth-scratch.git
cd ssynth-scratch
git checkout -b yubi-branch
cd ../
```

# Step 1: Train diffusion model

### a. Create a virtual environment.

Source the following packages if you are using the luna server.
```
# source /projects01/mikem/python-3.12.5 (OLD)
source /projects01/mikem/python-3.12.5/set_env.sh
source /app/GPU/CUDA-Toolkit/cuda-12.1/set_env.sh
```

Navigate into the minimal-diffusion directory. Then, create a new python virtual environment with the following command.
```
python -m venv min-diff-venv
```

Activate the environment using the following command.
```
source min-diff-venv/bin/activate
```

Once you activate the environment, install the following dependencies.
```
pip install torch torchvision
pip install scipy opencv-python pillow easydict numpy
```

### b. Structure dataset

Navigate the directory minimal-diffusion/datasets/. We recommend that you download the [The Kaggle Skin Diseases Image Dataset](https://www.kaggle.com/datasets/ismailpromus/skin-diseases-image-dataset) and extract the following folders: “2. Melanoma” and “6. Benign Keratosis Like Lesions” into minimal-diffusion/datasets/. If you desire, you may use another dataset. Each folder in the directory should be titled with the name of the image class that its images fall under. For best results, we recommend using at least 2,000 images per class and at least 2 classes. Furthermore, the number of images in each class should be approximately equivalent to each other.

### 3. Modify slurm file

If choosing to train your diffusion model on multiple GPU’s using torch.distributed, modify the slurm_dist.sh file. If choosing to train your diffusion model on a single GPU, modify the slurm.sh file. Both of these files are in the minimal-diffusion directory.

Modify the number of GPU’s on line 7 to indicate the number of GPU’s that you will use for training.
```
#SBATCH --gres=gpu:<number of GPU’s>
```

Modify the time and memory specified in lines 8 and 9, respectively, based on the expected runtime and memory capacity for training your diffusion model. When training the diffusion model on ~16K images on 4 GPU’s for 250 epochs, 100 sampling steps, and with a batch size of 128, the model took ~30 hrs. to train.
```
#SBATCH --time=<time for job>
#SBATCH --mem=<memory for job>
```

Modify the file path to the diffusion_datasets directory on line 29.
```
IMG_DIR="/<path name>/minimal-diffusion/datasets/"
```

Modify the number of your master_port on line 32 to the location of your master port.

Modify the python command on lines 32-35 to specify your desired number of epochs, batch size, and number of sampling steps. We recommend training with class conditioning if you have at least 2 classes, but if you would like to train without class conditioning, you may remove the --class-cond flag. Modify the --dataset name to be ‘skin_cancer’. 

Modify the path to the min-diff-venv python virtual environment in the /bin/activate command. This min-diff-venv should be in your minimal-diffusion directory.

### 4. Modify data.py file

Locate the data.py file in the minimal-diffusion folder. Go to line 68, where the metadata for skin_cancer should be listed.

Modify the image_size to specify the desired dimensions of your input image that is fed into the diffusion model. Modify the num_classes to specify the number of classes (image folders) in diffusion_dataset. Modify the train_images to specify the number of combined total images in all your classes.

We recommend using a training dataset of RGB images with 3 channels. However, if your training dataset has images that are different, you may change num_channels to specify the number of channels in an input image.

Go to line 250, which specifies the process for reading in the training dataset. Modify line 256 to specify the desired dimensions of your input image that is fed into the diffusion model.
```
transforms.resize((<height>, <width>)
```

### 5. Train the diffusion model

Navigate to the location of your relevant slurm file (see Step 3) in your minimal-diffusion directory in your Terminal. Then, send the job to the server with the following command.
```
sbatch <slurm file name>.sh
```

You can access the updated status of your job with the command ‘sacct’. 

### 6. Locate trained model and preliminary results

Once your job is completed, navigate to the directory “trained_models”. There will be 3 outputs from your job with the following format:
* UNet_skin_cancer-1000_steps-<number of sampling steps>-sampling_steps-class_condn_<True/False>.png
* UNet_skin_cancer-epoch_<number of epochs>-timesteps_1000-class_condn_<True/False>_ema_0.9995.pt
* UNet_skin_cancer-epoch_<number of epochs>-timesteps_1000-class_condn_<True/False>.pt

You can view 64 images sampled from your trained model by opening the UNet_skin_cancer-1000_steps-<number of sampling steps>-sampling_steps-class_condn_<True/False>.png file. 

# Step 2. Sample and visualize synthetic skin images

### a. Set up python virtual environment

Activate the min-diff-venv python virtual environment using the following command.
```
min-diff-venv/bin/activate
```

Install the following packages using the following command.
```
pip install matplotlib
```

### b. Modify sample_imgs slurm file

If choosing to sample your diffusion model on multiple GPU’s using torch.distributed, modify the sample_imgs.sh file. If choosing to train your diffusion model on a single GPU, modify the sample_imgs_single.sh file. Both of these files are in the minimal-diffusion directory.

In the desired slurm file in the minimal-diffusion directory, locate MODEL_DIR on line 30 and set the path name to the location of the checkpoint (.pt) file in trained_models. This checkpoint file should be for the ema_0.9995 model. If you would like to use a pre-trained model for 250 epochs, class-conditioned on the ISIC dataset, and with 1000 sampling steps, you may download the model found at [this Hugging Face Repository](https://huggingface.co/yubimamiya/minimal-diffusion-melanoma) to the trained_models directory.

In your minimal-diffusion directory, locate the sample_imgs_output_test directory. This will be the location of the npz files with the images you sample from the trained diffusion model. Locate SAVE_DIR_PATH on line 31 and set the path name to the location of the sample_imgs_output_test directory.

Adjust the arguments in lines 33-39 as desired. Ensure that the argument for --dataset in sample_imgs.sh matches the argument for --dataset used to train your model in Step 1. Furthermore, the argument for --num-sampled-images should be the number of images you would like to sample from the trained model. If your model was trained with the --class-cond flag, please sample from your model with the --class-cond flag.

Similar to Step 1, adjust the number of GPU’s, runtime, and memory of the job in the first 9 lines of sample_imgs.sh as desired.

Modify the path to the min-diff-venv python virtual environment in the /bin/activate command. This min-diff-venv should be in your minimal-diffusion directory.

Then, send the job to the server with the following command.
```
sbatch sample_imgs.sh
```

### c. Extract images from npz file

Once your job has completed, locate the npz_to_images_luna.py python file in the minimal-diffusion directory. In line 18, edit the path name of dfile to the path of the npz file in the minimal-diffusion/sample_imgs_output_test directory that was just created by the above job. The name of the npz file should include the dataset name, number of sampling steps, class conditioning flag, and number of epochs used to sample from the diffusion model.

In lines 24-27, edit the loop to iterate through the number of sampled images in the npz file. For example,  if you sampled 5000 images, the loop should range from 0 to 5000. Ensure that the offset for k is correct. For example, if you have previously sampled 100 images, the offset should be 100. If this is your first time sampling images from the diffusion model, the offset should be 0.

Open the npz_to_imgs_slurm.sh file in the minimal-diffusion directory. Similar to Step 1, adjust the number of CPU’s, runtime, and memory of the job in the first 9 lines as desired. When extracting 5000 images from a npz file, I used 1 hour, 4 GB, and 8 CPU’s. Please do not change the number of GPU’s, but you may change the number of CPU’s.

Modify the path to the min-diff-venv python virtual environment in the /bin/activate command. This min-diff-venv should be in your minimal-diffusion directory.

Send the job to the server with the following command.
```
sbatch npz_to_imgs_slurm.sh
```

### d. Verify job and observe extracted images

Once the job has completed, you can find the extracted images under the directory minimal-diffusion/synth_data/ITA_images. You may double click on any image in MobaXTerm to view the image. You will also find your synthetic_metadata.csv under minimal-diffusion/synth_data. Open this file to check that you have the appropriate number of images listed under ‘image_id’.

### e. Create synthetic_metadata.csv

In Microsoft Excel, create a new spreadsheet where there is 1 column labeled image_id. Fill the column with the file names ITA_0, ITA_1, ITA_2, etc. until you reach the number of images extracted from the npz file. Download the spreadsheet as a csv file. Name the file with the following naming convention: synthetic_metadata_#.csv, where # is the number of images extracted from the npz file. For example, if you sampled 5000 images, name the csv synthetic_metadata_5000.csv.


# Step 3. Segment lesion masks with SAM

### a. Set up environment

Activate the min-diff-venv python virtual environment using the following command.
```
min-diff-venv/bin/activate
```

Install the following packages using the following command.
```
pip install pandas
```

Locate the directory named ITA_masks in minimal-diffusion/synth_data/. This will be the location of the lesion masks segmented by SAM after your job has completed.

### b. Edit python pipeline

Open the sam_pipeline_luna.py file in the segment-anything directory. On line 58, edit the name of the synthetic_metadata.csv to match the csv describing the image_id’s of all the images you would like to find lesion masks for. Please be aware that SAM has ~80% success rate on finding a sufficient lesion mask for a synthetic skin image, therefore, enter an appropriately high number of synthetic images if you have a goal number of image-mask pairs. For example, if you would like to finish with 80 image-mask pairs, synthetic_metadata.csv should include at least 100 image_id’s.

On line 176, edit the name of SAM_metadata_#.csv, where # is the number of synthetic images in synthetic_metadata.csv.

### c. Edit slurm file

Open the SAM_slurm.sh file in the segment-anything directory. On lines 1-9, adjust the number of CPU’s, runtime, and memory of the job. For reference, we used 4 CPU’s, 24 hours, and 10 G for segmenting lesions from 7,000 images.

Modify the path to the min-diff-venv python virtual environment in the /bin/activate command. This min-diff-venv should be in your minimal-diffusion directory.

Then, run the job with the following command.
``` 
sbatch SAM_slurm.sh
```

# Step 4. Evaluate distribution of skin colors

### a. Update python virtual environment

Activate the min-diff-venv python virtual environment using the following command.
```
min-diff-venv/bin/activate
```

Install the following packages using the following command.
```
pip install scikit-image pytest-shutil seaborn
```

### b. Modify ITA_luna.py

Locate ITA_luna.py in the ITA directory. Modify the path to synthetic_metadata to match the name of the synthetic_metadata.csv listing all of the image_id’s for all of the images that you would like to analyze their skin color. 

### c. Run the job

Locate the ITA_slurm.sh file in the ITA directory. Modify the number of CPU’s, runtime, and memory of the job as desired. For reference, calculating the ITA for 500 images with 4 CPU’s took 5 minutes and 1 GB. 

Modify the path to the min-diff-venv python virtual environment in the /bin/activate command. This min-diff-venv should be in your minimal-diffusion directory.

Send the job to the server with the following command.
```
sbatch ITA_slurm.sh
```

### d. Visualize results

Once your job is completed, you can locate skin_color.csv in minimal-diffusion/synth_data/. Open ITA_summary_luna.py in the ITA directory. Edit the path to your skin_color.csv in data_dir. Additionally, modify the path to the min-diff-venv python virtual environment in the /bin/activate command. This min-diff-venv should be in your minimal-diffusion directory. Then, send the job to the server with the following command.
```
sbatch ITA_summary_slurm.sh
```


# Step 5. Evaluate lesion segmentation performance using DermoSegDiff

Please reference ssynth-scratch/README.md in the main branch for instructions on evaluating lesion segmentation performance using DermoSegDiff. dataset/data_dir should point to minimal-diffusion/synth_data/ . You should generate the .txt files to include the path names to the desired number of real skin images from HAM and synthetic skin images from the diffusion model. The real skin images from HAM are found under /projects01/VICTRE/elena.sizikova/skin/real_dataset/ham10k/HAM10000_images_part_1/ and the synthetic skin images are found under minimal-diffusion/synth_data/ITA_images/.
